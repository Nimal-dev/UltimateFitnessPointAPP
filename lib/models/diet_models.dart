class MealModel {
  final String id;
  final String timeOfDay;
  final String time;
  final List<String> items;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final String instructions;

  MealModel({
    required this.id,
    required this.timeOfDay,
    required this.time,
    required this.items,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.instructions = '',
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['_id'] ?? '',
      timeOfDay: json['timeOfDay'] ?? '',
      time: json['time'] ?? '',
      items: List<String>.from(json['items'] ?? []),
      calories: (json['calories'] ?? 0) as int,
      protein: (json['protein'] ?? 0) as int,
      carbs: (json['carbs'] ?? 0) as int,
      fats: (json['fats'] ?? 0) as int,
      instructions: json['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'timeOfDay': timeOfDay,
        'time': time,
        'items': items,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'instructions': instructions,
      };
}

class DietPlanModel {
  final String id;
  final String assignedByName;
  final List<MealModel> meals;
  final String notes;

  DietPlanModel({
    required this.id,
    required this.assignedByName,
    required this.meals,
    this.notes = '',
  });

  factory DietPlanModel.fromJson(Map<String, dynamic> json) {
    return DietPlanModel(
      id: json['_id'] ?? '',
      assignedByName: (json['assignedBy'] is Map)
          ? json['assignedBy']['name'] ?? 'Trainer'
          : 'Trainer',
      meals: (json['meals'] as List<dynamic>? ?? [])
          .map((m) => MealModel.fromJson(m))
          .toList(),
      notes: json['notes'] ?? '',
    );
  }

  int get totalCalories => meals.fold(0, (s, m) => s + m.calories);
  int get totalProtein => meals.fold(0, (s, m) => s + m.protein);
  int get totalCarbs => meals.fold(0, (s, m) => s + m.carbs);
  int get totalFats => meals.fold(0, (s, m) => s + m.fats);
}

class DietLogModel {
  final String? id;
  final String date;
  int waterIntake;
  String memberNotes;
  List<String> mealsCompleted;

  DietLogModel({
    this.id,
    required this.date,
    this.waterIntake = 0,
    this.memberNotes = '',
    List<String>? mealsCompleted,
  }) : mealsCompleted = mealsCompleted ?? [];

  factory DietLogModel.fromJson(Map<String, dynamic> json) {
    return DietLogModel(
      id: json['_id'],
      date: json['date'] ?? '',
      waterIntake: (json['waterIntake'] ?? 0) as int,
      memberNotes: json['memberNotes'] ?? '',
      mealsCompleted: List<String>.from(json['mealsCompleted'] ?? []),
    );
  }

  DietLogModel empty(String date) => DietLogModel(date: date);
}
