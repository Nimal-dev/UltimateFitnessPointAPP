import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/fitness_log_model.dart';
import '../models/analytics_model.dart';
import '../services/api_service.dart';

class MemberProvider extends ChangeNotifier {
  UserModel? userData;
  List<TaskModel> tasks = [];
  Map<String, int> activity = {};
  List<OneRepMaxLog> strengthLogs = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchStrengthLogs() async {
    try {
      final data = await ApiService.get('/member/health/strength');
      if (data['success'] == true) {
        strengthLogs = (data['data'] as List)
            .map((l) => OneRepMaxLog.fromJson(l))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<MemberAnalytics?> fetchAnalytics() async {
    try {
      final data = await ApiService.get('/member/analytics');
      if (data['success'] == true) {
        return MemberAnalytics.fromJson(data['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<void> addStrengthLog(OneRepMaxLog log) async {
    // Optimistic update
    strengthLogs.insert(0, log);
    notifyListeners();

    try {
      final data = await ApiService.post('/member/health/strength', {
        'exerciseName': log.exerciseName,
        'weight': log.weight,
        'date': log.date.toIso8601String(),
      });
      if (data['success'] != true) {
        // Revert on failure
        strengthLogs.remove(log);
        notifyListeners();
      }
    } catch (_) {
      strengthLogs.remove(log);
      notifyListeners();
    }
  }

  Future<void> fetchDashboard({int? year}) async {
    final y = year ?? DateTime.now().year;
    final cacheKey = 'cached_dashboard_$y';
    
    error = null;
    
    // 1. Try to load from cache first for instant UI
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        _parseDashboardData(data);
        notifyListeners();
      }
    } catch (_) {
      // Ignore cache errors
    }

    // 2. Fetch fresh data from API
    if (userData == null) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final data = await ApiService.get('/member/dashboard?year=$y');
      if (data['success'] == true) {
        _parseDashboardData(data);
        
        // Save to cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(data));
      } else {
        error = data['message'];
      }
    } catch (e) {
      if (userData == null) {
        error = 'Failed to load dashboard';
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void _parseDashboardData(Map<String, dynamic> data) {
    userData = UserModel.fromJson(data['user']);
    tasks = (data['tasks'] as List<dynamic>? ?? [])
        .map((t) => TaskModel.fromJson(t))
        .toList();
    activity = Map<String, int>.from(
      (data['activity'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
    );
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
            weight: userData!.weight,
            height: userData!.height,
            age: userData!.age,
            gender: userData!.gender,
            activityLevel: userData!.activityLevel,
            bodyFatPercentage: userData!.bodyFatPercentage,
            muscleMass: userData!.muscleMass,
            dailyWaterGoal: userData!.dailyWaterGoal,
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
