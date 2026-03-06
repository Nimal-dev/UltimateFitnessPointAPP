import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../models/analytics_model.dart';
import '../services/api_service.dart';

class OwnerProvider extends ChangeNotifier {
  OwnerMetrics metrics = OwnerMetrics();
  List<MemberModel> members = [];
  bool isLoading = false;
  String? error;

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
        metrics = OwnerMetrics.fromJson(data['data']);
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
        members = (data['data'] as List<dynamic>)
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
    return members.where((m) {
      // tab filter
      if (tab == 'pending' && m.status != 'Pending') return false;
      if (tab == 'rejected' && m.status != 'Rejected') return false;
      if (tab == 'all' && (m.status == 'Pending' || m.status == 'Rejected')) {
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
      members.where((m) => m.status == 'Pending').length;
}
