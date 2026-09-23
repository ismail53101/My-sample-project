class TaskPriority {
  final String label;
  final int level;

  const TaskPriority._(this.label, this.level);

  static const low = TaskPriority._('Low', 0);
  static const medium = TaskPriority._('Medium', 1);
  static const high = TaskPriority._('High', 2);

  static const List<TaskPriority> values = [low, medium, high];

  @override
  String toString() => label;
}

class Task {
  final String id;
  final String title;
  bool isCompleted;
  final TaskPriority priority;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
