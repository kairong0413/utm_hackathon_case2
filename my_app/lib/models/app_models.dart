import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AuthMode { login, signup }

enum CatMood { thriving, neutral, distressed, hissing }

enum CatStage { kitten, adult, guardian }

class GXUser {
  const GXUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.studentMode,
  });

  final String name;
  final String email;
  final String phone;
  final bool studentMode;

  GXUser copyWith({
    String? name,
    String? email,
    String? phone,
    bool? studentMode,
  }) {
    return GXUser(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      studentMode: studentMode ?? this.studentMode,
    );
  }
}

class CatProfile {
  const CatProfile({
    required this.name,
    required this.breed,
    required this.breedIndex,
    required this.accessory,
  });

  final String name;
  final String breed;
  final int breedIndex;
  final String accessory;

  CatProfile copyWith({
    String? name,
    String? breed,
    int? breedIndex,
    String? accessory,
  }) {
    return CatProfile(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      breedIndex: breedIndex ?? this.breedIndex,
      accessory: accessory ?? this.accessory,
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
    required this.overrideMood,
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
  final CatMood overrideMood;
  final List<GXTransaction> transactions;
  final List<CatFriend> friends;

  factory FinanceState.initial() {
    return FinanceState(
      weeklyGoal: 50,
      savedThisWeek: 32,
      spentThisWeek: 128,
      weeklyBudget: 220,
      streak: 8,
      meowPoints: 240,
      resilienceDays: 12,
      emergencyFundPercent: 18,
      reportsReviewed: 0,
      overrideMood: CatMood.neutral,
      transactions: [
        GXTransaction('Round-up from nasi lemak', 2.40, Icons.savings, true),
        GXTransaction('Boba treat', 15.00, Icons.local_cafe, false),
        GXTransaction('Daily catnip interest', 0.36, Icons.auto_awesome, true),
      ],
      friends: [
        CatFriend('Aina', 'Pixel', CatMood.thriving, 92),
        CatFriend('Jay', 'Kopi', CatMood.distressed, 38),
        CatFriend('Mei', 'Milo', CatMood.neutral, 68),
      ],
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
    if (emergencyFundPercent >= 100) return CatStage.guardian;
    if (resilienceDays >= 30) return CatStage.adult;
    return CatStage.kitten;
  }

  double get savingsProgress => (savedThisWeek / weeklyGoal).clamp(0, 1);

  double get budgetProgress => (spentThisWeek / weeklyBudget).clamp(0, 1.4);

  int get resilienceScore {
    final saving = (savingsProgress * 45).round();
    final budget = ((1 - (budgetProgress - 1).clamp(0, 1)) * 35).round();
    final streakScore = math.min(streak * 2, 20);
    return (saving + budget + streakScore).clamp(0, 100);
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
    CatMood? overrideMood,
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
      overrideMood: overrideMood ?? this.overrideMood,
      transactions: transactions ?? List.of(this.transactions),
      friends: friends ?? List.of(this.friends),
    );
  }
}

class GXTransaction {
  GXTransaction(this.title, this.amount, this.icon, this.positive);

  final String title;
  final double amount;
  final IconData icon;
  final bool positive;
}

class CatFriend {
  CatFriend(this.owner, this.catName, this.mood, this.score);

  final String owner;
  final String catName;
  final CatMood mood;
  final int score;

  CatFriend copyWith({int? score}) {
    return CatFriend(owner, catName, mood, score ?? this.score);
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
