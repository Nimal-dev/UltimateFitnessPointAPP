class TaskModel {
  final String id;
  final String title;
  final int points;
  bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.points,
    this.isCompleted = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      points: (json['points'] ?? 0) as int,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
