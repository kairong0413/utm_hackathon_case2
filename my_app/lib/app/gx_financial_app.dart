import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../screens/adoption_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_shell.dart';
import '../services/backend_service.dart';

class GXFinancialApp extends StatefulWidget {
  const GXFinancialApp({super.key, BackendService? backend}) : backend = backend ?? const _DefaultBackend();

  final BackendService backend;

  @override
  State<GXFinancialApp> createState() => _GXFinancialAppState();
}

class _GXFinancialAppState extends State<GXFinancialApp> {
  AppProfile? _optimisticProfile;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GX Financial Cat',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: StreamBuilder<AppProfile?>(
        stream: widget.backend.watchProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _ProfileLoadError(error: snapshot.error);
          if (snapshot.connectionState == ConnectionState.waiting) return const _ProfileLoading();
          final profile = snapshot.data;
          if (profile == null && _optimisticProfile != null) _optimisticProfile = null;
          return _buildHome(_optimisticProfile ?? profile);
        },
      ),
    );
  }

  Widget _buildHome(AppProfile? profile) {
    final user = profile?.user;
    final cat = profile?.cat;
    final finance = profile?.finance ?? FinanceState.initial();

    if (user == null) {
      return AuthScreen(onAuthenticated: widget.backend.authenticate);
    }
    if (cat == null) {
      return AdoptionScreen(
        onAdopted: (cat, weeklyGoal) {
          final nextFinance = finance.copyWith(
            weeklyGoal: weeklyGoal,
            transactions: [
              GXTransaction('Adopted ${cat.name} the ${cat.breed}', 0, Icons.pets, true),
              ...finance.transactions,
            ],
          );
          setState(() {
            _optimisticProfile = AppProfile(user: user, cat: cat, finance: nextFinance);
          });
          unawaited(
            Future.wait([
              widget.backend.saveCat(cat),
              widget.backend.saveFinance(nextFinance),
            ]).catchError((error) {
              if (!mounted) return <void>[];
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('Could not save adoption yet: $error')));
              return <void>[];
            }),
          );
        },
      );
    }
    return HomeShell(
      user: user,
      cat: cat,
      finance: finance,
      onFinanceChanged: widget.backend.saveFinance,
      onUserChanged: widget.backend.saveUser,
      onCatChanged: widget.backend.saveCat,
      onFriendSearch: widget.backend.findFriend,
      incomingFriendRequests: widget.backend.watchIncomingFriendRequests(),
      onFriendRequested: widget.backend.sendFriendRequest,
      onFriendRequestAccepted: widget.backend.acceptFriendRequest,
      onFriendRequestDeclined: widget.backend.declineFriendRequest,
      onSignOut: () {
        setState(() => _optimisticProfile = null);
        widget.backend.signOut();
      },
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFF18A999);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        surface: const Color(0xFFF7F4EF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F4EF),
      textTheme: ThemeData().textTheme.apply(
            bodyColor: const Color(0xFF1F2933),
            displayColor: const Color(0xFF1F2933),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _DefaultBackend implements BackendService {
  const _DefaultBackend();

  BackendService get _delegate => FirebaseBackendService();

  @override
  Future<void> authenticate(AuthCredentials credentials) => _delegate.authenticate(credentials);

  @override
  Future<void> acceptFriendRequest(FriendRequest request) => _delegate.acceptFriendRequest(request);

  @override
  Future<void> declineFriendRequest(FriendRequest request) => _delegate.declineFriendRequest(request);

  @override
  Future<CatFriend?> findFriend(String query) => _delegate.findFriend(query);

  @override
  Future<void> sendFriendRequest(CatFriend friend) => _delegate.sendFriendRequest(friend);

  @override
  Future<void> saveCat(CatProfile cat) => _delegate.saveCat(cat);

  @override
  Future<void> saveFinance(FinanceState finance) => _delegate.saveFinance(finance);

  @override
  Future<void> saveUser(GXUser user) => _delegate.saveUser(user);

  @override
  Future<void> signOut() => _delegate.signOut();

  @override
  Stream<AppProfile?> watchProfile() => _delegate.watchProfile();

  @override
  Stream<List<FriendRequest>> watchIncomingFriendRequests() => _delegate.watchIncomingFriendRequests();
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load profile: $error', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
