class OneRepMaxLog {
  final String id;
  final String exerciseName;
  final double weight;
  final DateTime date;

  OneRepMaxLog({
    required this.id,
    required this.exerciseName,
    required this.weight,
    required this.date,
  });

  factory OneRepMaxLog.fromJson(Map<String, dynamic> json) {
    return OneRepMaxLog(
      id: json['_id'] ?? json['id'] ?? '',
      exerciseName: json['exerciseName'] ?? '',
      weight: (json['weight'] ?? 0.0) as double,
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }
}
