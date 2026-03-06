import 'user_model.dart';

class MemberAnalytics {
  final UserModel? memberProfile;
  final MemberSummary summary;
  final List<AttendancePoint> attendance;
  final List<DietTrendPoint> dietTrend;
  final List<WorkoutTrendPoint> workoutTrend;
  final bool hasDietPlan;
  final String? dietPlanNotes;

  MemberAnalytics({
    this.memberProfile,
    required this.summary,
    required this.attendance,
    required this.dietTrend,
    required this.workoutTrend,
    required this.hasDietPlan,
    this.dietPlanNotes,
  });

  factory MemberAnalytics.fromJson(Map<String, dynamic> json) {
    return MemberAnalytics(
      memberProfile: json['member'] != null ? UserModel.fromJson(json['member']) : null,
      summary: MemberSummary.fromJson(json['summary'] ?? {}),
      attendance: (json['attendance'] as List? ?? [])
          .map((i) => AttendancePoint.fromJson(i))
          .toList(),
      dietTrend: (json['dietTrend'] as List? ?? [])
          .map((i) => DietTrendPoint.fromJson(i))
          .toList(),
      workoutTrend: (json['workoutTrend'] as List? ?? [])
          .map((i) => WorkoutTrendPoint.fromJson(i))
          .toList(),
      hasDietPlan: json['hasDietPlan'] ?? false,
      dietPlanNotes: json['dietPlanNotes']?.toString(),
    );
  }
}

class MemberSummary {
  final int attendanceDays;
  final int avgWater;
  final int? avgDietAdherence;
  final int totalPoints;

  MemberSummary({
    required this.attendanceDays,
    required this.avgWater,
    this.avgDietAdherence,
    required this.totalPoints,
  });

  factory MemberSummary.fromJson(Map<String, dynamic> json) {
    return MemberSummary(
      attendanceDays: json['attendanceDays'] ?? 0,
      avgWater: json['avgWater'] ?? 0,
      avgDietAdherence: json['avgDietAdherence'],
      totalPoints: json['totalPoints'] ?? 0,
    );
  }
}

class AttendancePoint {
  final DateTime date;
  final bool present;

  AttendancePoint({required this.date, required this.present});

  factory AttendancePoint.fromJson(Map<String, dynamic> json) {
    return AttendancePoint(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      present: json['present'] ?? false,
    );
  }
}

class DietTrendPoint {
  final DateTime date;
  final int waterIntake;
  final int mealsCompleted;
  final int totalMeals;
  final int adherencePercent;

  DietTrendPoint({
    required this.date,
    required this.waterIntake,
    required this.mealsCompleted,
    required this.totalMeals,
    required this.adherencePercent,
  });

  factory DietTrendPoint.fromJson(Map<String, dynamic> json) {
    return DietTrendPoint(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      waterIntake: (json['waterIntake'] ?? 0) as int,
      mealsCompleted: (json['mealsCompleted'] ?? 0) as int,
      totalMeals: (json['totalMeals'] ?? 0) as int,
      adherencePercent: (json['adherencePercent'] ?? 0) as int,
    );
  }
}

class WorkoutTrendPoint {
  final DateTime date;
  final int tasksTotal;
  final int tasksCompleted;
  final int completionPercent;

  WorkoutTrendPoint({
    required this.date,
    required this.tasksTotal,
    required this.tasksCompleted,
    required this.completionPercent,
  });

  factory WorkoutTrendPoint.fromJson(Map<String, dynamic> json) {
    return WorkoutTrendPoint(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      tasksTotal: (json['tasksTotal'] ?? 0) as int,
      tasksCompleted: (json['tasksCompleted'] ?? 0) as int,
      completionPercent: (json['completionPercent'] ?? 0) as int,
    );
  }
}
