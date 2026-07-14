enum TaskPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
    low => 'Rendah',
    medium => 'Sedang',
    high => 'Tinggi',
  };

  static TaskPriority fromStorage(String value) =>
      values.firstWhere((item) => item.name == value, orElse: () => medium);
}

enum TaskStatus {
  pending,
  inProgress,
  completed;

  String get label => switch (this) {
    pending => 'Belum mulai',
    inProgress => 'Dikerjakan',
    completed => 'Selesai',
  };

  static TaskStatus fromStorage(String value) =>
      values.firstWhere((item) => item.name == value, orElse: () => pending);
}

enum RepeatRule {
  none,
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
    none => 'Tidak berulang',
    daily => 'Setiap hari',
    weekly => 'Setiap minggu',
    monthly => 'Setiap bulan',
  };

  static RepeatRule fromStorage(String? value) =>
      values.firstWhere((item) => item.name == value, orElse: () => none);
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
    this.parentTaskId,
    this.description,
    this.category,
    this.dueDate,
    this.reminderAt,
  });

  final String id;
  final String? parentTaskId;
  final String title;
  final String? description;
  final String? category;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final RepeatRule repeatRule;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => status == TaskStatus.completed;
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.location,
    this.reminderAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final String? location;
  final DateTime? reminderAt;
  final RepeatRule repeatRule;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.startAt,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.endAt,
    this.durationMinutes,
    this.notes,
    this.mood,
  });

  final String id;
  final String title;
  final String? category;
  final DateTime startAt;
  final DateTime? endAt;
  final int? durationMinutes;
  final String? notes;
  final String? mood;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ProductivitySummary {
  const ProductivitySummary({
    required this.activeTasks,
    required this.completedTasks,
    required this.todaySchedules,
    required this.todayActivityMinutes,
    this.nextReminder,
  });

  final int activeTasks;
  final int completedTasks;
  final int todaySchedules;
  final int todayActivityMinutes;
  final DateTime? nextReminder;
}

class ProductivitySnapshot {
  const ProductivitySnapshot({
    required this.tasks,
    required this.schedules,
    required this.activities,
    required this.summary,
  });

  const ProductivitySnapshot.empty()
    : tasks = const [],
      schedules = const [],
      activities = const [],
      summary = const ProductivitySummary(
        activeTasks: 0,
        completedTasks: 0,
        todaySchedules: 0,
        todayActivityMinutes: 0,
      );

  final List<TaskItem> tasks;
  final List<ScheduleItem> schedules;
  final List<ActivityItem> activities;
  final ProductivitySummary summary;
}
