import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class MemberProvider extends ChangeNotifier {
  UserModel? userData;
  List<TaskModel> tasks = [];
  Map<String, int> activity = {};
  bool isLoading = false;
  String? error;

  Future<void> fetchDashboard({int? year}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final y = year ?? DateTime.now().year;
      final data = await ApiService.get('/member/dashboard?year=$y');
      if (data['success'] == true) {
        userData = UserModel.fromJson(data['user']);
        tasks = (data['tasks'] as List<dynamic>? ?? [])
            .map((t) => TaskModel.fromJson(t))
            .toList();
        activity = Map<String, int>.from(
          (data['activity'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ),
        );
      } else {
        error = data['message'];
      }
    } catch (e) {
      error = 'Failed to load dashboard';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> toggleTask(String taskId) async {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    // Optimistic update
    final wasCompleted = tasks[taskIndex].isCompleted;
    tasks[taskIndex].isCompleted = !wasCompleted;

    // Heatmap update
    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    if (tasks[taskIndex].isCompleted) {
      activity[dateKey] = (activity[dateKey] ?? 0) + 1;
    } else {
      activity[dateKey] = (activity[dateKey] ?? 0) - 1;
      if (activity[dateKey]! < 0) activity[dateKey] = 0;
    }

    notifyListeners();

    try {
      final data =
          await ApiService.post('/member/tasks/$taskId/toggle', {});
      if (data['success'] == true) {
        tasks[taskIndex].isCompleted = data['isCompleted'] ?? tasks[taskIndex].isCompleted;
        if (userData != null) {
          userData = UserModel(
            id: userData!.id,
            name: userData!.name,
            email: userData!.email,
            role: userData!.role,
            points: (data['totalPoints'] ?? userData!.points) as int,
            membershipStatus: userData!.membershipStatus,
            membershipExpiry: userData!.membershipExpiry,
            mobile: userData!.mobile,
          );
        }
        notifyListeners();
      }
    } catch (_) {
      // Revert on failure
      tasks[taskIndex].isCompleted = !tasks[taskIndex].isCompleted;
      notifyListeners();
    }
  }
}
