import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../screens/adoption_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_shell.dart';

class GXFinancialApp extends StatefulWidget {
  const GXFinancialApp({super.key});

  @override
  State<GXFinancialApp> createState() => _GXFinancialAppState();
}

class _GXFinancialAppState extends State<GXFinancialApp> {
  GXUser? _user;
  CatProfile? _cat;
  FinanceState _finance = FinanceState.initial();

  void _handleAuth(GXUser user) {
    setState(() => _user = user);
  }

  void _handleAdoption(CatProfile cat, double weeklyGoal) {
    setState(() {
      _cat = cat;
      _finance = _finance.copyWith(weeklyGoal: weeklyGoal);
      _finance.transactions.insert(
        0,
        GXTransaction('Adopted ${cat.name} the ${cat.breed}', 0, Icons.pets, true),
      );
    });
  }

  void _updateFinance(FinanceState finance) {
    setState(() => _finance = finance);
  }

  void _updateUser(GXUser user) {
    setState(() => _user = user);
  }

  void _updateCat(CatProfile cat) {
    setState(() => _cat = cat);
  }

  void _signOut() {
    setState(() {
      _user = null;
      _cat = null;
      _finance = FinanceState.initial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GX Financial Cat',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final user = _user;
    final cat = _cat;

    if (user == null) {
      return AuthScreen(onAuthenticated: _handleAuth);
    }
    if (cat == null) {
      return AdoptionScreen(onAdopted: _handleAdoption);
    }
    return HomeShell(
      user: user,
      cat: cat,
      finance: _finance,
      onFinanceChanged: _updateFinance,
      onUserChanged: _updateUser,
      onCatChanged: _updateCat,
      onSignOut: _signOut,
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
