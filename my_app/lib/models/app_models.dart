import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AuthMode { login, signup }

enum CatMood { thriving, neutral, distressed, hissing }

enum CatStage { kitten, adult, guardian }

enum CatActivity { idle, sleep, eat, play }

class AuthCredentials {
  const AuthCredentials({
    required this.mode,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.studentMode,
  });

  final AuthMode mode;
  final String name;
  final String email;
  final String phone;
  final String password;
  final bool studentMode;
}

class AppProfile {
  const AppProfile({
    required this.user,
    required this.cat,
    required this.finance,
  });

  final GXUser user;
  final CatProfile? cat;
  final FinanceState finance;
}

class GXUser {
  const GXUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.studentMode,
  });

  final String userId;
  final String name;
  final String email;
  final String phone;
  final bool studentMode;

  GXUser copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    bool? studentMode,
  }) {
    return GXUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      studentMode: studentMode ?? this.studentMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'studentMode': studentMode,
    };
  }

  factory GXUser.fromMap(Map<String, dynamic> map) {
    return GXUser(
      userId: map['userId'] as String? ?? '',
      name: (map['name'] as String?)?.trim().isNotEmpty == true ? map['name'] as String : 'GX Saver',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      studentMode: map['studentMode'] as bool? ?? true,
    );
  }
}

class CatProfile {
  const CatProfile({
    required this.name,
    required this.breed,
    required this.breedIndex,
    required this.accessory,
    required this.ownedItems,
  });

  final String name;
  final String breed;
  final int breedIndex;
  final String accessory;
  final List<String> ownedItems;

  CatProfile copyWith({
    String? name,
    String? breed,
    int? breedIndex,
    String? accessory,
    List<String>? ownedItems,
  }) {
    return CatProfile(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      breedIndex: breedIndex ?? this.breedIndex,
      accessory: accessory ?? this.accessory,
      ownedItems: ownedItems ?? List.of(this.ownedItems),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'breedIndex': breedIndex,
      'accessory': accessory,
      'ownedItems': ownedItems,
    };
  }

  factory CatProfile.fromMap(Map<String, dynamic> map) {
    final accessory = map['accessory'] as String? ?? 'No item';
    final ownedItems = (map['ownedItems'] as List<dynamic>?)?.whereType<String>().toList() ?? <String>[];
    final equippedItems = _accessoryItems(accessory).where(ownedItems.contains).take(2).toList();
    return CatProfile(
      name: map['name'] as String? ?? 'Mojo',
      breed: map['breed'] as String? ?? 'Calico',
      breedIndex: map['breedIndex'] as int? ?? 0,
      accessory: equippedItems.isEmpty ? 'No item' : equippedItems.join(', '),
      ownedItems: ownedItems,
    );
  }
}

class FinanceState {
  FinanceState({
    required this.weeklyGoal,
    required this.savedThisWeek,
    required this.spentThisWeek,
    required this.weeklyBudget,
    required this.streak,
    required this.meowPoints,
    required this.resilienceDays,
    required this.emergencyFundPercent,
    required this.reportsReviewed,
    required this.lastWeeklyReportKey,
    required this.overrideMood,
    required this.levelXp,
    required this.transactions,
    required this.friends,
  });

  final double weeklyGoal;
  final double savedThisWeek;
  final double spentThisWeek;
  final double weeklyBudget;
  final int streak;
  final int meowPoints;
  final int resilienceDays;
  final int emergencyFundPercent;
  final int reportsReviewed;
  final int lastWeeklyReportKey;
  final CatMood overrideMood;
  final int levelXp;
  final List<GXTransaction> transactions;
  final List<CatFriend> friends;

  static const levelThresholds = <int>[
    0,
    5,
    10,
    30,
    50,
    100,
    300,
    500,
    800,
    1200,
    1700,
    2300,
    3000,
    3800,
    4700,
    5700,
    6900,
    8200,
    9600,
    11200,
  ];

  factory FinanceState.initial() {
    return FinanceState(
      weeklyGoal: 50,
      savedThisWeek: 0,
      spentThisWeek: 0,
      weeklyBudget: 220,
      streak: 0,
      meowPoints: 0,
      resilienceDays: 0,
      emergencyFundPercent: 0,
      reportsReviewed: 0,
      lastWeeklyReportKey: 0,
      overrideMood: CatMood.neutral,
      levelXp: 0,
      transactions: [],
      friends: [],
    );
  }

  CatMood get mood {
    if (overrideMood == CatMood.hissing) return CatMood.hissing;
    if (spentThisWeek > weeklyBudget || savedThisWeek < weeklyGoal * .35) {
      return CatMood.distressed;
    }
    if (savedThisWeek >= weeklyGoal) return CatMood.thriving;
    return CatMood.neutral;
  }

  CatStage get stage {
    if (level >= 15 || emergencyFundPercent >= 100) return CatStage.guardian;
    if (level >= 8 || resilienceDays >= 30) return CatStage.adult;
    return CatStage.kitten;
  }

  int get level {
    for (var i = levelThresholds.length - 1; i >= 0; i--) {
      if (levelXp >= levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  int get nextLevelXp {
    if (level >= 20) return levelThresholds.last;
    return levelThresholds[level];
  }

  int get currentLevelXp => levelThresholds[level - 1];

  double get levelProgress {
    if (level >= 20) return 1;
    final span = nextLevelXp - currentLevelXp;
    return ((levelXp - currentLevelXp) / span).clamp(0, 1).toDouble();
  }

  String get levelReward {
    return rewardForLevel(level);
  }

  static String rewardForLevel(int level) {
    const rewards = [
      'No item yet',
      'Soft cat carpet',
      'Wood side table',
      'Yarn toy',
      'Cat wall frame',
      'GX cat bank',
      'Window sunlight',
      'Adult cat form',
      'Scratching post',
      'Catnip plant',
      'Toy mouse',
      'Cozy lamp',
      'Second room shelf',
      'Gold collar shine',
      'Regal guardian form',
      'Crown display',
      'Premium bed',
      'Cafe invitation',
      'Emergency fund vault',
      'Legendary guardian room',
    ];
    return rewards[(level - 1).clamp(0, rewards.length - 1)];
  }

  List<String> get unlockedRewards {
    return [
      for (var unlockedLevel = 2; unlockedLevel <= level; unlockedLevel++) rewardForLevel(unlockedLevel),
    ];
  }

  double get savingsProgress => (savedThisWeek / weeklyGoal).clamp(0, 1).toDouble();

  double get budgetProgress => (spentThisWeek / weeklyBudget).clamp(0, 1.4).toDouble();

  int get resilienceScore {
    final saving = (savingsProgress * 45).round();
    final budget = ((1 - (budgetProgress - 1).clamp(0, 1)) * 35).round();
    final streakScore = math.min(streak * 2, 20);
    return (saving + budget + streakScore).clamp(0, 100).toInt();
  }

  FinanceState copyWith({
    double? weeklyGoal,
    double? savedThisWeek,
    double? spentThisWeek,
    double? weeklyBudget,
    int? streak,
    int? meowPoints,
    int? resilienceDays,
    int? emergencyFundPercent,
    int? reportsReviewed,
    int? lastWeeklyReportKey,
    CatMood? overrideMood,
    int? levelXp,
    List<GXTransaction>? transactions,
    List<CatFriend>? friends,
  }) {
    return FinanceState(
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      savedThisWeek: savedThisWeek ?? this.savedThisWeek,
      spentThisWeek: spentThisWeek ?? this.spentThisWeek,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
      streak: streak ?? this.streak,
      meowPoints: meowPoints ?? this.meowPoints,
      resilienceDays: resilienceDays ?? this.resilienceDays,
      emergencyFundPercent: emergencyFundPercent ?? this.emergencyFundPercent,
      reportsReviewed: reportsReviewed ?? this.reportsReviewed,
      lastWeeklyReportKey: lastWeeklyReportKey ?? this.lastWeeklyReportKey,
      overrideMood: overrideMood ?? this.overrideMood,
      levelXp: levelXp ?? this.levelXp,
      transactions: transactions ?? List.of(this.transactions),
      friends: friends ?? List.of(this.friends),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weeklyGoal': weeklyGoal,
      'savedThisWeek': savedThisWeek,
      'spentThisWeek': spentThisWeek,
      'weeklyBudget': weeklyBudget,
      'streak': streak,
      'meowPoints': meowPoints,
      'resilienceDays': resilienceDays,
      'emergencyFundPercent': emergencyFundPercent,
      'reportsReviewed': reportsReviewed,
      'lastWeeklyReportKey': lastWeeklyReportKey,
      'overrideMood': overrideMood.name,
      'levelXp': levelXp,
      'transactions': transactions.map((transaction) => transaction.toMap()).toList(),
      'friends': friends.map((friend) => friend.toMap()).toList(),
    };
  }

  factory FinanceState.fromMap(Map<String, dynamic> map) {
    final fallback = FinanceState.initial();
    return FinanceState(
      weeklyGoal: (map['weeklyGoal'] as num?)?.toDouble() ?? fallback.weeklyGoal,
      savedThisWeek: (map['savedThisWeek'] as num?)?.toDouble() ?? fallback.savedThisWeek,
      spentThisWeek: (map['spentThisWeek'] as num?)?.toDouble() ?? fallback.spentThisWeek,
      weeklyBudget: (map['weeklyBudget'] as num?)?.toDouble() ?? fallback.weeklyBudget,
      streak: map['streak'] as int? ?? fallback.streak,
      meowPoints: map['meowPoints'] as int? ?? fallback.meowPoints,
      resilienceDays: map['resilienceDays'] as int? ?? fallback.resilienceDays,
      emergencyFundPercent: map['emergencyFundPercent'] as int? ?? fallback.emergencyFundPercent,
      reportsReviewed: map['reportsReviewed'] as int? ?? fallback.reportsReviewed,
      lastWeeklyReportKey: map['lastWeeklyReportKey'] as int? ?? fallback.lastWeeklyReportKey,
      overrideMood: CatMood.values.firstWhere(
        (mood) => mood.name == map['overrideMood'],
        orElse: () => fallback.overrideMood,
      ),
      levelXp: map['levelXp'] as int? ?? fallback.levelXp,
      transactions: (map['transactions'] as List<dynamic>?)
              ?.map(_stringMap)
              .map(GXTransaction.fromMap)
              .toList() ??
          fallback.transactions,
      friends: (map['friends'] as List<dynamic>?)
              ?.map(_stringMap)
              .map(CatFriend.fromMap)
              .toList() ??
          fallback.friends,
    );
  }
}

class GXTransaction {
  GXTransaction(this.title, this.amount, this.icon, this.positive);

  final String title;
  final double amount;
  final IconData icon;
  final bool positive;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'iconCodePoint': icon.codePoint,
      'positive': positive,
    };
  }

  factory GXTransaction.fromMap(Map<String, dynamic> map) {
    return GXTransaction(
      map['title'] as String? ?? 'Transaction',
      (map['amount'] as num?)?.toDouble() ?? 0,
      IconData(map['iconCodePoint'] as int? ?? Icons.receipt_long.codePoint, fontFamily: 'MaterialIcons'),
      map['positive'] as bool? ?? true,
    );
  }
}

class CatFriend {
  CatFriend({
    required this.ownerUserId,
    required this.owner,
    required this.catName,
    required this.mood,
    required this.score,
    required this.breedIndex,
    required this.stage,
    required this.accessory,
    required this.level,
    required this.item,
  });

  final String ownerUserId;
  final String owner;
  final String catName;
  final CatMood mood;
  final int score;
  final int breedIndex;
  final CatStage stage;
  final String accessory;
  final int level;
  final String item;

  CatFriend copyWith({int? score}) {
    return CatFriend(
      ownerUserId: ownerUserId,
      owner: owner,
      catName: catName,
      mood: mood,
      score: score ?? this.score,
      breedIndex: breedIndex,
      stage: stage,
      accessory: accessory,
      level: level,
      item: item,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
      'owner': owner,
      'catName': catName,
      'mood': mood.name,
      'score': score,
      'breedIndex': breedIndex,
      'stage': stage.name,
      'accessory': accessory,
      'level': level,
      'item': item,
    };
  }

  factory CatFriend.fromMap(Map<String, dynamic> map) {
    return CatFriend(
      ownerUserId: map['ownerUserId'] as String? ?? '',
      owner: map['owner'] as String? ?? 'Friend',
      catName: map['catName'] as String? ?? 'Kitty',
      mood: CatMood.values.firstWhere(
        (mood) => mood.name == map['mood'],
        orElse: () => CatMood.neutral,
      ),
      score: map['score'] as int? ?? 50,
      breedIndex: map['breedIndex'] as int? ?? 0,
      stage: CatStage.values.firstWhere(
        (stage) => stage.name == map['stage'],
        orElse: () => CatStage.kitten,
      ),
      accessory: map['accessory'] as String? ?? 'No item',
      level: map['level'] as int? ?? 1,
      item: map['item'] as String? ?? 'No item yet',
    );
  }
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromFriend,
    required this.toFriend,
    required this.status,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final CatFriend fromFriend;
  final CatFriend toFriend;
  final String status;

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromFriend': fromFriend.toMap(),
      'toFriend': toFriend.toMap(),
      'status': status,
    };
  }

  factory FriendRequest.fromMap(String id, Map<String, dynamic> map) {
    return FriendRequest(
      id: id,
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      fromFriend: CatFriend.fromMap(_stringMap(map['fromFriend'])),
      toFriend: CatFriend.fromMap(_stringMap(map['toFriend'])),
      status: map['status'] as String? ?? 'pending',
    );
  }
}

extension CatMoodLabel on CatMood {
  String get label {
    return switch (this) {
      CatMood.thriving => 'Thriving Chonk',
      CatMood.neutral => 'House Cat',
      CatMood.distressed => 'Stray recovery',
      CatMood.hissing => 'BNPL Hiss',
    };
  }
}

extension CatStageLabel on CatStage {
  String get label {
    return switch (this) {
      CatStage.kitten => 'Kitten',
      CatStage.adult => 'Adult Cat',
      CatStage.guardian => 'Regal Guardian',
    };
  }
}

extension CatActivityLabel on CatActivity {
  String get label {
    return switch (this) {
      CatActivity.idle => 'wandering',
      CatActivity.sleep => 'sleeping',
      CatActivity.eat => 'eating',
      CatActivity.play => 'playing',
    };
  }
}

Map<String, dynamic> _stringMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

List<String> _accessoryItems(String accessory) {
  final normalized = accessory.trim();
  if (normalized.isEmpty || normalized == 'No item' || normalized == 'No item yet') return const [];
  return normalized
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item != 'No item' && item != 'No item yet')
      .toList();
}
