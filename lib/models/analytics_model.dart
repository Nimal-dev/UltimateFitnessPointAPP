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

class OwnerMetrics {
  final int totalMembers;
  final int activeMembers;
  final int pendingRenewals;
  final int expiredMembers;
  final int dailyCheckins;
  final List<RevenueProjection> revenueProjections;
  final List<AtRiskMember> atRiskMembers;
  final List<PeakHour> peakHours;

  OwnerMetrics({
    this.totalMembers = 0,
    this.activeMembers = 0,
    this.pendingRenewals = 0,
    this.expiredMembers = 0,
    this.dailyCheckins = 0,
    this.revenueProjections = const [],
    this.atRiskMembers = const [],
    this.peakHours = const [],
  });

  factory OwnerMetrics.fromJson(Map<String, dynamic> json) {
    return OwnerMetrics(
      totalMembers: json['totalMembers'] ?? 0,
      activeMembers: json['activeMembers'] ?? 0,
      pendingRenewals: json['pendingRenewals'] ?? 0,
      expiredMembers: json['expiredMembers'] ?? 0,
      dailyCheckins: json['dailyCheckins'] ?? 0,
      revenueProjections: (json['revenueProjections'] as List? ?? [])
          .map((i) => RevenueProjection.fromJson(i))
          .toList(),
      atRiskMembers: (json['atRiskMembers'] as List? ?? [])
          .map((i) => AtRiskMember.fromJson(i))
          .toList(),
      peakHours: (json['peakHours'] as List? ?? [])
          .map((i) => PeakHour.fromJson(i))
          .toList(),
    );
  }
}

class RevenueProjection {
  final int month;
  final int year;
  final int count;
  final double projectedRevenue;

  RevenueProjection({
    required this.month,
    required this.year,
    required this.count,
    required this.projectedRevenue,
  });

  factory RevenueProjection.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? {};
    return RevenueProjection(
      month: id['month'] ?? 0,
      year: id['year'] ?? 0,
      count: json['count'] ?? 0,
      projectedRevenue: (json['projectedRevenue'] ?? 0.0).toDouble(),
    );
  }
}

class AtRiskMember {
  final String id;
  final String name;
  final String mobile;
  final DateTime? lastCheckin;

  AtRiskMember({
    required this.id,
    required this.name,
    required this.mobile,
    this.lastCheckin,
  });

  factory AtRiskMember.fromJson(Map<String, dynamic> json) {
    return AtRiskMember(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      mobile: json['mobile'] ?? '',
      lastCheckin: json['lastCheckin'] != null 
          ? DateTime.parse(json['lastCheckin']) 
          : null,
    );
  }
}

class PeakHour {
  final int hour;
  final int count;

  PeakHour({required this.hour, required this.count});

  factory PeakHour.fromJson(Map<String, dynamic> json) {
    return PeakHour(
      hour: json['_id'] ?? 0,
      count: json['count'] ?? 0,
    );
  }
}
