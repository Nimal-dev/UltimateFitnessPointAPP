import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../models/analytics_model.dart';
import '../services/api_service.dart';

class OwnerProvider extends ChangeNotifier {
  OwnerMetrics _metrics = OwnerMetrics();
  List<MemberModel> _members = [];
  bool isLoading = false;
  String? error;

  OwnerMetrics get metrics => _metrics;
  List<MemberModel> get members => _members;
  List<MemberModel> get trainers => _members.where((m) => m.role == 'Trainer').toList();

  Future<MemberAnalytics?> fetchMemberAnalytics(String memberId) async {
    error = null;
    try {
      final data = await ApiService.get('/owner/members/$memberId/analytics');
      if (data['success'] == true) {
        return MemberAnalytics.fromJson(data['data']);
      } else {
        error = data['message'] ?? 'Failed to load analytics';
      }
    } catch (e) {
      error = 'Error fetching analytics: $e';
      print(error);
    }
    notifyListeners();
    return null;
  }

  Future<void> fetchMetrics() async {
    try {
      final data = await ApiService.get('/owner/metrics');
      if (data['success'] == true) {
        _metrics = OwnerMetrics.fromJson(data['data']);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchMembers() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await ApiService.get('/owner/members');
      if (data['success'] == true) {
        _members = (data['data'] as List<dynamic>)
            .map((m) => MemberModel.fromJson(m))
            .toList();
      } else {
        error = data['message'];
      }
    } catch (e) {
      error = 'Failed to load members';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> updateMemberStatus(String id, String status) async {
    try {
      final data = await ApiService.patch(
          '/owner/members/$id', {'membershipStatus': status});
      if (data['success'] == true) {
        await fetchMembers();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteMember(String id) async {
    try {
      final data = await ApiService.delete('/owner/members/$id');
      if (data['success'] == true) {
        members.removeWhere((m) => m.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> addMember(Map<String, dynamic> memberData) async {
    try {
      final data = await ApiService.post('/owner/members', memberData);
      if (data['success'] == true) {
        await fetchMembers();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> assignDietPlan(
      String memberId, List<Map<String, dynamic>> meals, String notes) async {
    try {
      final data = await ApiService.post('/diet/plan', {
        'memberId': memberId,
        'meals': meals,
        'notes': notes,
      });
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  List<MemberModel> filtered(String tab, String search) {
    return _members.where((m) {
      // Exclude trainers from Member Management tabs
      if (m.role == 'Trainer') return false;

      // tab filter
      if (tab == 'pending' && m.status != 'Pending') return false;
      if (tab == 'expired' && m.status != 'Expired') return false;
      if (tab == 'rejected' && m.status != 'Rejected') return false;
      if (tab == 'active' && m.status != 'Active') return false;
      
      // Default fallback for any other cases (though UI handles its own tabs)
      if (tab == 'all' && (m.status == 'Pending' || m.status == 'Rejected' || m.status == 'Expired')) {
        return false;
      }
      // search filter
      if (search.isNotEmpty) {
        final q = search.toLowerCase();
        return m.name.toLowerCase().contains(q) ||
            m.email.toLowerCase().contains(q) ||
            m.mobile.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  int get pendingCount =>
      _members.where((m) => m.role == 'Member' && m.status == 'Pending').length;

  int get expiredCount =>
      _members.where((m) => m.role == 'Member' && m.status == 'Expired').length;

  // Phase 2: Announcements & Leaderboards
  List<AnnouncementModel> announcements = [];
  List<LeaderboardEntry> engagementLeaderboard = [];

  Future<void> fetchOwnerAnnouncements() async {
    try {
      final data = await ApiService.get('/owner/announcements');
      if (data['success'] == true) {
        announcements = (data['data'] as List)
            .map((a) => AnnouncementModel.fromJson(a))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> createAnnouncement(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.post('/owner/announcements', data);
      if (res['success'] == true) {
        await fetchOwnerAnnouncements();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteAnnouncement(String id) async {
    try {
      final res = await ApiService.delete('/owner/announcements/$id');
      if (res['success'] == true) {
        announcements.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchEngagementLeaderboard() async {
    try {
      final data = await ApiService.get('/owner/leaderboard/engagement');
      if (data['success'] == true) {
        engagementLeaderboard = (data['data'] as List)
            .map((l) => LeaderboardEntry.fromJson(l))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // Phase 3: Staffing & Operations
  List<StaffWorkload> staffWorkload = [];
  List<ExpiringMember> expiringMembers = [];

  Future<void> fetchStaffStats() async {
    try {
      final data = await ApiService.get('/owner/staff/stats');
      if (data['success'] == true) {
        staffWorkload = (data['data'] as List)
            .map((s) => StaffWorkload.fromJson(s))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchExpiringMembers() async {
    try {
      final data = await ApiService.get('/owner/members/expiring');
      if (data['success'] == true) {
        expiringMembers = (data['data'] as List)
            .map((e) => ExpiringMember.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> sendRenewalReminder(String memberId) async {
    try {
      final data = await ApiService.post('/owner/members/$memberId/remind', {});
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // Phase 4: Trainer Detail Tracking
  Future<Map<String, dynamic>?> fetchTrainerPerformance(String trainerId) async {
    try {
      final data = await ApiService.get('/owner/trainers/$trainerId/managed-members');
      if (data['success'] == true) {
        return data['data'];
      }
    } catch (e) {
      print('Error fetching trainer performance: $e');
    }
    return null;
  }
}
