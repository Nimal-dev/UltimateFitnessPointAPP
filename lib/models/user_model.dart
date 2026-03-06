class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'Owner', 'Trainer', 'Member'
  final int points;
  final String membershipStatus; // Active, Pending, Expired, Rejected
  final DateTime? membershipExpiry;
  final String? mobile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.points = 0,
    this.membershipStatus = 'Pending',
    this.membershipExpiry,
    this.mobile,
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
    );
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
}
