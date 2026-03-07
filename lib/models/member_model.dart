class MemberModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String status; // Active, Pending, Expired, Rejected
  final int points;
  final String joined;
  final String expiryDate;

  MemberModel({
    required this.id,
    required this.name,
    required this.email,
    this.mobile = '',
    this.status = 'Pending',
    this.points = 0,
    this.joined = '',
    this.expiryDate = '',
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      status: json['membershipStatus'] ?? 'Pending',
      points: (json['points'] ?? 0) as int,
      joined: json['createdAt'] != null
          ? json['createdAt'].toString().split('T')[0]
          : 'N/A',
      expiryDate: json['membershipExpiry']?.toString() ?? '',
    );
  }

  String get initials {
    final parts = name.split(' ');
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join('');
  }

  int get daysRemaining {
    if (expiryDate.isEmpty) return 0;
    try {
      final expiry = DateTime.parse(expiryDate);
      final diff = expiry.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff + 1; // +1 to include today
    } catch (_) {
      return 0;
    }
  }
}

class OwnerMetrics {
  final int totalMembers;
  final int activeMembers;
  final int pendingRenewals;
  final int expiredMembers;
  final int dailyCheckins;

  OwnerMetrics({
    this.totalMembers = 0,
    this.activeMembers = 0,
    this.pendingRenewals = 0,
    this.expiredMembers = 0,
    this.dailyCheckins = 0,
  });

  factory OwnerMetrics.fromJson(Map<String, dynamic> json) {
    return OwnerMetrics(
      totalMembers: (json['totalMembers'] ?? 0) as int,
      activeMembers: (json['activeMembers'] ?? 0) as int,
      pendingRenewals: (json['pendingRenewals'] ?? 0) as int,
      expiredMembers: (json['expiredMembers'] ?? 0) as int,
      dailyCheckins: (json['dailyCheckins'] ?? 0) as int,
    );
  }
}
