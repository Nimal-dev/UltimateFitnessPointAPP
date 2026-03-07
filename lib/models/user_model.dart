import 'package:flutter/material.dart' show Color, Colors;

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'Owner', 'Trainer', 'Member'
  final int points;
  final String membershipStatus; // Active, Pending, Expired, Rejected
  final DateTime? membershipExpiry;
  final String? mobile;
  final double? weight;
  final double? height;
  final int? age;
  final String? gender;
  final String? activityLevel;
  final double? bodyFatPercentage;
  final double? muscleMass;
  final int dailyWaterGoal;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.points = 0,
    this.membershipStatus = 'Pending',
    this.membershipExpiry,
    this.mobile,
    this.weight,
    this.height,
    this.age,
    this.gender,
    this.activityLevel,
    this.bodyFatPercentage,
    this.muscleMass,
    this.dailyWaterGoal = 8,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Member',
      points: (json['points'] ?? 0) as int,
      membershipStatus: json['membershipStatus'] ?? 'Pending',
      membershipExpiry: json['membershipExpiry'] != null
          ? DateTime.tryParse(json['membershipExpiry'])
          : null,
      mobile: json['mobile'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      age: json['age'],
      gender: json['gender'],
      activityLevel: json['activityLevel'] ?? 'Sedentary',
      bodyFatPercentage: json['bodyFatPercentage'] != null
          ? (json['bodyFatPercentage'] as num).toDouble()
          : null,
      muscleMass: json['muscleMass'] != null
          ? (json['muscleMass'] as num).toDouble()
          : null,
      dailyWaterGoal: (json['dailyWaterGoal'] ?? 8) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'points': points,
      'membershipStatus': membershipStatus,
      'membershipExpiry': membershipExpiry?.toIso8601String(),
      'mobile': mobile,
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'activityLevel': activityLevel,
      'bodyFatPercentage': bodyFatPercentage,
      'muscleMass': muscleMass,
      'dailyWaterGoal': dailyWaterGoal,
    };
  }

  String get initials {
    final parts = name.split(' ');
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join('');
  }

  int get daysRemaining {
    if (membershipExpiry == null) return 0;
    final diff = membershipExpiry!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get tier {
    if (points > 2000) return 'Gold';
    if (points > 1000) return 'Silver';
    return 'Bronze';
  }

  double? get bmi {
    if (weight == null || height == null || height! == 0) return null;
    final hMeter = height! / 100;
    return weight! / (hMeter * hMeter);
  }

  String get bmiCategory {
    final b = bmi;
    if (b == null) return 'N/A';
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    final cat = bmiCategory;
    if (cat == 'Underweight') return Colors.blue;
    if (cat == 'Normal') return const Color(0xFFD4E600); // AppTheme.accent
    if (cat == 'Overweight') return Colors.orange;
    return Colors.red;
  }

  String get idealWeightRange {
    if (height == null || height! == 0) return 'N/A';
    final hMeter = height! / 100;
    final min = 18.5 * (hMeter * hMeter);
    final max = 24.9 * (hMeter * hMeter);
    return '${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)} kg';
  }

  double? get bmr {
    if (weight == null || height == null || age == null || gender == null) return null;
    if (gender == 'Male') {
      return (10 * weight!) + (6.25 * height!) - (5 * age!) + 5;
    } else {
      return (10 * weight!) + (6.25 * height!) - (5 * age!) - 161;
    }
  }

  double? get tdee {
    final base = bmr;
    if (base == null) return null;
    return base * tdeeMultiplier;
  }

  double get tdeeMultiplier {
    switch (activityLevel) {
      case 'Sedentary': return 1.2;
      case 'Lightly Active': return 1.375;
      case 'Moderately Active': return 1.55;
      case 'Very Active': return 1.725;
      case 'Extra Active': return 1.9;
      default: return 1.2;
    }
  }
}
