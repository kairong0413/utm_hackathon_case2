import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';

import '../models/app_models.dart';

abstract class BackendService {
  Stream<AppProfile?> watchProfile();

  Future<void> authenticate(AuthCredentials credentials);

  Future<CatFriend?> findFriend(String query);

  Stream<List<FriendRequest>> watchIncomingFriendRequests();

  Future<void> sendFriendRequest(CatFriend friend);

  Future<void> acceptFriendRequest(FriendRequest request);

  Future<void> declineFriendRequest(FriendRequest request);

  Future<void> saveUser(GXUser user);

  Future<void> saveCat(CatProfile cat);

  Future<void> saveFinance(FinanceState finance);

  Future<void> saveCatAndFinance(CatProfile cat, FinanceState finance);

  Future<void> signOut();
}

class FirebaseBackendService implements BackendService {
  FirebaseBackendService({
    auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _publicProfiles => _firestore.collection('publicProfiles');
  CollectionReference<Map<String, dynamic>> get _friendRequests => _firestore.collection('friendRequests');

  @override
  Stream<AppProfile?> watchProfile() async* {
    await for (final firebaseUser in _auth.authStateChanges()) {
      if (firebaseUser == null) {
        yield null;
        continue;
      }

      try {
        await _trySyncAcceptedRequests(firebaseUser.uid);
        await for (final snapshot in _users.doc(firebaseUser.uid).snapshots()) {
          final migrated = _migrateProfile(firebaseUser.uid, _profileFromSnapshot(firebaseUser, snapshot));
          final profile = AppProfile(
            user: migrated.user,
            cat: migrated.cat,
            finance: await _refreshFriendSnapshots(migrated.finance),
          );
          await _tryPublishProfile(firebaseUser.uid, profile);
          yield profile;
        }
      } catch (error, stackTrace) {
        debugPrint('Firestore profile stream failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        yield _fallbackProfile(firebaseUser);
      }
    }
  }

  @override
  Future<void> authenticate(AuthCredentials credentials) async {
    final userCredential = credentials.mode == AuthMode.signup
        ? await _auth.createUserWithEmailAndPassword(
            email: credentials.email,
            password: credentials.password,
          )
        : await _auth.signInWithEmailAndPassword(
            email: credentials.email,
            password: credentials.password,
          );

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) return;

    try {
      if (credentials.mode == AuthMode.signup) {
        await firebaseUser.updateDisplayName(credentials.name);
        await _users.doc(firebaseUser.uid).set({
          'user': GXUser(
            userId: firebaseUser.uid,
            name: credentials.name,
            email: credentials.email,
            phone: credentials.phone,
            studentMode: credentials.studentMode,
          ).toMap(),
          'finance': FinanceState.initial().toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final doc = _users.doc(firebaseUser.uid);
        final snapshot = await doc.get();
        if (snapshot.exists) {
          await doc.update({
            'user.userId': firebaseUser.uid,
            'user.email': credentials.email,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await doc.set({
            'user': GXUser(
              userId: firebaseUser.uid,
              name: firebaseUser.displayName ?? 'GX Saver',
              email: credentials.email,
              phone: credentials.phone,
              studentMode: credentials.studentMode,
            ).toMap(),
            'finance': FinanceState.initial().toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      await _tryPublishCurrentProfile();
    } catch (error, stackTrace) {
      debugPrint('Firestore profile sync failed after auth: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  AppProfile _profileFromSnapshot(
    auth.User firebaseUser,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) return _fallbackProfile(firebaseUser);
    return AppProfile(
      user: GXUser.fromMap(_asStringMap(data['user'])).copyWith(userId: firebaseUser.uid),
      cat: data['cat'] == null ? null : CatProfile.fromMap(_asStringMap(data['cat'])),
      finance: FinanceState.fromMap(_asStringMap(data['finance'])),
    );
  }

  AppProfile _fallbackProfile(auth.User firebaseUser) {
    return AppProfile(
      user: GXUser(
        userId: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'GX Saver',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        studentMode: true,
      ),
      cat: null,
      finance: FinanceState.initial(),
    );
  }

  @override
  Future<CatFriend?> findFriend(String query) async {
    final search = _normalizeSearch(query);
    if (search.isEmpty) return null;

    final currentUid = _auth.currentUser?.uid;
    DocumentSnapshot<Map<String, dynamic>>? snapshot;
    if (!query.trim().contains('/')) {
      final byId = await _publicProfiles.doc(query.trim()).get();
      if (byId.exists) snapshot = byId;
    }
    if (snapshot == null) {
      final matches = await _publicProfiles.where('searchTerms', arrayContains: search).limit(1).get();
      if (matches.docs.isNotEmpty) snapshot = matches.docs.first;
    }

    if (snapshot == null || !snapshot.exists || snapshot.id == currentUid) return null;
    return _friendFromPublicProfile(snapshot.id, snapshot.data() ?? {});
  }

  @override
  Stream<List<FriendRequest>> watchIncomingFriendRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream<List<FriendRequest>>.value([]);
    return _friendRequests.where('toUserId', isEqualTo: uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.id, doc.data()))
          .where((request) => request.status == 'pending')
          .toList();
    });
  }

  @override
  Future<void> sendFriendRequest(CatFriend friend) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid == friend.ownerUserId) return;
    final me = await _currentFriendSnapshot();
    if (me == null) return;

    final requestId = '${uid}_${friend.ownerUserId}';
    await _friendRequests.doc(requestId).set({
      'fromUserId': uid,
      'toUserId': friend.ownerUserId,
      'fromFriend': me.toMap(),
      'toFriend': friend.toMap(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> acceptFriendRequest(FriendRequest request) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || request.toUserId != uid) return;
    await _addFriendSnapshot(uid, request.fromFriend);
    await _friendRequests.doc(request.id).set({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> declineFriendRequest(FriendRequest request) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || request.toUserId != uid) return;
    await _friendRequests.doc(request.id).set({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _addFriendSnapshot(String uid, CatFriend friend) async {
    final doc = _users.doc(uid);
    final snapshot = await doc.get();
    final data = snapshot.data() ?? {};
    final finance = FinanceState.fromMap(_asStringMap(data['finance']));
    final latestFriend = await _latestFriendSnapshot(friend.ownerUserId, fallback: friend);
    final friends = [
      latestFriend,
      for (final existing in finance.friends)
        if (existing.ownerUserId != latestFriend.ownerUserId) existing,
    ];
    await doc.set({
      'finance': finance.copyWith(friends: friends).toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (uid == _auth.currentUser?.uid) await _tryPublishCurrentProfile();
  }

  Future<void> _syncAcceptedRequests(String uid) async {
    final accepted = await _friendRequests.where('fromUserId', isEqualTo: uid).get();
    for (final doc in accepted.docs) {
      final request = FriendRequest.fromMap(doc.id, doc.data());
      if (request.status != 'accepted') continue;
      await _addFriendSnapshot(uid, request.toFriend);
      await doc.reference.set({
        'status': 'connected',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> saveUser(GXUser user) {
    return _save({'user': user.toMap()});
  }

  @override
  Future<void> saveCat(CatProfile cat) {
    return _save({'cat': cat.toMap()});
  }

  @override
  Future<void> saveFinance(FinanceState finance) {
    return _save({'finance': finance.toMap()});
  }

  @override
  Future<void> saveCatAndFinance(CatProfile cat, FinanceState finance) {
    return _save({
      'cat': cat.toMap(),
      'finance': finance.toMap(),
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<void> _save(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _users.doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _tryPublishCurrentProfile();
  }

  Future<void> _tryPublishCurrentProfile() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      final snapshot = await _users.doc(firebaseUser.uid).get();
      final profile = _migrateProfile(firebaseUser.uid, _profileFromSnapshot(firebaseUser, snapshot));
      await _publishProfile(firebaseUser.uid, profile);
    } catch (error, stackTrace) {
      debugPrint('Public profile publish failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _tryPublishProfile(String userId, AppProfile profile) async {
    try {
      await _publishProfile(userId, profile);
    } catch (error, stackTrace) {
      debugPrint('Public profile publish failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _trySyncAcceptedRequests(String uid) async {
    try {
      await _syncAcceptedRequests(uid);
    } catch (error, stackTrace) {
      debugPrint('Friend request sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _publishProfile(String userId, AppProfile profile) async {
    if (profile.cat == null) return;

    await _publicProfiles.doc(userId).set({
      'userId': userId,
      'name': profile.user.name,
      'cat': profile.cat!.toMap(),
      'finance': _publicFinanceMap(profile.finance),
      'searchTerms': _searchTerms(userId, profile.user.name),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<CatFriend?> _currentFriendSnapshot() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    final snapshot = await _users.doc(firebaseUser.uid).get();
    return _friendFromProfile(firebaseUser.uid, _migrateProfile(firebaseUser.uid, _profileFromSnapshot(firebaseUser, snapshot)));
  }

  AppProfile _migrateProfile(String userId, AppProfile profile) {
    final cat = profile.cat;
    if (cat == null) return profile;
    final rewards = profile.finance.unlockedRewards;
    final owned = <String>{...cat.ownedItems}
      ..remove('No item yet')
      ..removeWhere(rewards.contains);
    final equipped = cat.accessory
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && owned.contains(item))
        .take(2)
        .toList();
    final accessory = equipped.isEmpty ? 'No item' : equipped.join(', ');
    return AppProfile(
      user: profile.user.copyWith(userId: userId),
      cat: cat.copyWith(accessory: accessory, ownedItems: owned.toList()),
      finance: profile.finance.copyWith(
        friends: [
          for (final friend in profile.finance.friends)
            if (!friend.ownerUserId.startsWith('demo-')) friend,
        ],
      ),
    );
  }

  Future<FinanceState> _refreshFriendSnapshots(FinanceState finance) async {
    if (finance.friends.isEmpty) return finance;
    final refreshed = <CatFriend>[];
    for (final friend in finance.friends) {
      refreshed.add(await _latestFriendSnapshot(friend.ownerUserId, fallback: friend));
    }
    return finance.copyWith(friends: refreshed);
  }

  Future<CatFriend> _latestFriendSnapshot(String userId, {required CatFriend fallback}) async {
    try {
      final snapshot = await _publicProfiles.doc(userId).get();
      if (!snapshot.exists) return fallback;
      return _friendFromPublicProfile(snapshot.id, snapshot.data() ?? {});
    } catch (error, stackTrace) {
      debugPrint('Friend refresh failed for $userId: $error');
      debugPrintStack(stackTrace: stackTrace);
      return fallback;
    }
  }
}

class MemoryBackendService implements BackendService {
  final ValueNotifier<AppProfile?> _profile = ValueNotifier<AppProfile?>(null);

  @override
  Stream<AppProfile?> watchProfile() async* {
    yield _profile.value;
    yield* _profileChanges();
  }

  Stream<AppProfile?> _profileChanges() {
    late Stream<AppProfile?> stream;
    stream = Stream<AppProfile?>.multi((controller) {
      void listener() => controller.add(_profile.value);
      _profile.addListener(listener);
      controller.onCancel = () => _profile.removeListener(listener);
    });
    return stream;
  }

  @override
  Future<void> authenticate(AuthCredentials credentials) async {
    _profile.value = AppProfile(
      user: GXUser(
        userId: 'memory-user',
        name: credentials.mode == AuthMode.login ? 'Student Saver' : credentials.name,
        email: credentials.email,
        phone: credentials.phone,
        studentMode: credentials.studentMode,
      ),
      cat: null,
      finance: FinanceState.initial(),
    );
  }

  @override
  Future<CatFriend?> findFriend(String query) async {
    final current = _profile.value;
    final cat = current?.cat;
    final finance = current?.finance;
    if (current == null || cat == null || finance == null) return null;
    if (!_normalizeSearch(current.user.name).contains(_normalizeSearch(query))) return null;
    return CatFriend(
      ownerUserId: current.user.userId,
      owner: current.user.name,
      catName: cat.name,
      mood: finance.mood,
      score: finance.resilienceScore,
      breedIndex: cat.breedIndex,
      stage: finance.stage,
      accessory: cat.accessory,
      level: finance.level,
      item: finance.levelReward,
    );
  }

  @override
  Stream<List<FriendRequest>> watchIncomingFriendRequests() {
    return Stream<List<FriendRequest>>.value([]);
  }

  @override
  Future<void> sendFriendRequest(CatFriend friend) async {
    await _addFriend(friend);
  }

  @override
  Future<void> acceptFriendRequest(FriendRequest request) async {
    await _addFriend(request.fromFriend);
  }

  @override
  Future<void> declineFriendRequest(FriendRequest request) async {}

  Future<void> _addFriend(CatFriend friend) async {
    final current = _profile.value;
    if (current == null) return;
    _profile.value = AppProfile(
      user: current.user,
      cat: current.cat,
      finance: current.finance.copyWith(
        friends: [
          friend,
          for (final existing in current.finance.friends)
            if (existing.ownerUserId != friend.ownerUserId) existing,
        ],
      ),
    );
  }

  @override
  Future<void> saveUser(GXUser user) async {
    final current = _profile.value;
    if (current == null) return;
    _profile.value = AppProfile(user: user, cat: current.cat, finance: current.finance);
  }

  @override
  Future<void> saveCat(CatProfile cat) async {
    final current = _profile.value;
    if (current == null) return;
    _profile.value = AppProfile(user: current.user, cat: cat, finance: current.finance);
  }

  @override
  Future<void> saveFinance(FinanceState finance) async {
    final current = _profile.value;
    if (current == null) return;
    _profile.value = AppProfile(user: current.user, cat: current.cat, finance: finance);
  }

  @override
  Future<void> saveCatAndFinance(CatProfile cat, FinanceState finance) async {
    final current = _profile.value;
    if (current == null) return;
    _profile.value = AppProfile(user: current.user, cat: cat, finance: finance);
  }

  @override
  Future<void> signOut() async {
    _profile.value = null;
  }
}

Map<String, dynamic> _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

CatFriend _friendFromPublicProfile(String userId, Map<String, dynamic> data) {
  final user = GXUser.fromMap({...data, 'userId': userId});
  final cat = CatProfile.fromMap(_asStringMap(data['cat']));
  final finance = FinanceState.fromMap(_asStringMap(data['finance']));
  return _friendFromParts(userId, user.name, cat, finance);
}

CatFriend? _friendFromProfile(String userId, AppProfile profile) {
  final cat = profile.cat;
  if (cat == null) return null;
  return _friendFromParts(userId, profile.user.name, cat, profile.finance);
}

CatFriend _friendFromParts(String userId, String owner, CatProfile cat, FinanceState finance) {
  return CatFriend(
    ownerUserId: userId,
    owner: owner,
    catName: cat.name,
    mood: finance.mood,
    score: finance.resilienceScore,
    breedIndex: cat.breedIndex,
    stage: finance.stage,
    accessory: cat.accessory,
    level: finance.level,
    item: finance.levelReward,
  );
}

String _normalizeSearch(String value) => value.trim().toLowerCase();

List<String> _searchTerms(String userId, String name) {
  final terms = <String>{_normalizeSearch(userId), _normalizeSearch(name)};
  final normalizedName = _normalizeSearch(name);
  for (var i = 1; i <= normalizedName.length; i++) {
    terms.add(normalizedName.substring(0, i));
  }
  for (final part in name.split(RegExp(r'\s+'))) {
    final normalized = _normalizeSearch(part);
    for (var i = 1; i <= normalized.length; i++) {
      terms.add(normalized.substring(0, i));
    }
  }
  return terms.where((term) => term.isNotEmpty).toList();
}

Map<String, dynamic> _publicFinanceMap(FinanceState finance) {
  return {
    'weeklyGoal': finance.weeklyGoal,
    'savedThisWeek': finance.savedThisWeek,
    'spentThisWeek': finance.spentThisWeek,
    'weeklyBudget': finance.weeklyBudget,
    'streak': finance.streak,
    'resilienceDays': finance.resilienceDays,
    'emergencyFundPercent': finance.emergencyFundPercent,
    'overrideMood': finance.overrideMood.name,
    'levelXp': finance.levelXp,
  };
}
