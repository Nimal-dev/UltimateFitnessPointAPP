import 'package:flutter/material.dart';
import '../models/diet_models.dart';
import '../services/api_service.dart';

class DietProvider extends ChangeNotifier {
  DietPlanModel? plan;
  DietLogModel? log;
  bool isLoading = false;
  String? error;

  String get todayDate => DateTime.now().toIso8601String().split('T')[0];

  Future<void> fetchDietData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.get('/diet/plan'),
        ApiService.get('/diet/log/$todayDate'),
      ]);

      final planData = results[0];
      final logData = results[1];

      if (planData['_id'] != null) {
        plan = DietPlanModel.fromJson(planData);
      } else {
        plan = null;
      }

      if (logData.containsKey('_id') || logData['date'] != null) {
        log = DietLogModel.fromJson(logData);
      } else {
        log = DietLogModel(date: todayDate);
      }
    } catch (e) {
      log = DietLogModel(date: todayDate);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> toggleMeal(String mealId) async {
    if (log == null) return;
    final completed = List<String>.from(log!.mealsCompleted);
    if (completed.contains(mealId)) {
      completed.remove(mealId);
    } else {
      completed.add(mealId);
    }
    log!.mealsCompleted = completed;
    notifyListeners();
    await _syncLog();
  }

  Future<void> setWater(int amount) async {
    if (log == null) return;
    log!.waterIntake = amount;
    notifyListeners();
    await _syncLog();
  }

  Future<void> updateNotes(String notes) async {
    if (log == null) return;
    log!.memberNotes = notes;
    notifyListeners();
  }

  Future<void> saveNotes() async {
    await _syncLog();
  }

  Future<void> _syncLog() async {
    if (log == null) return;
    try {
      await ApiService.post('/diet/log', {
        'date': log!.date,
        'waterIntake': log!.waterIntake,
        'mealsCompleted': log!.mealsCompleted,
        'memberNotes': log!.memberNotes,
      });
    } catch (_) {}
  }

  int get progressPercent {
    final total = plan?.meals.length ?? 0;
    if (total == 0) return 0;
    return ((log?.mealsCompleted.length ?? 0) / total * 100).round();
  }
}
