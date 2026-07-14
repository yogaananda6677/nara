import 'package:nara/core/notifications/reminder_scheduler.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';
import 'package:nara/features/productivity/domain/repositories/productivity_repository.dart';

class FakeProductivityRepository implements ProductivityRepository {
  FakeProductivityRepository({ProductivitySnapshot? snapshot})
    : _snapshot = snapshot ?? const ProductivitySnapshot.empty();

  ProductivitySnapshot _snapshot;

  @override
  Future<ProductivitySnapshot> loadSnapshot({
    required DateTime day,
    String taskSearch = '',
    TaskStatus? taskStatus,
  }) async {
    final query = taskSearch.toLowerCase();
    final tasks = _snapshot.tasks.where((item) {
      return (taskStatus == null || item.status == taskStatus) &&
          (query.isEmpty || item.title.toLowerCase().contains(query));
    }).toList();
    return _copy(tasks: tasks);
  }

  @override
  Future<void> saveTask(TaskItem task) async {
    final items = [..._snapshot.tasks];
    final index = items.indexWhere((item) => item.id == task.id);
    index < 0 ? items.add(task) : items[index] = task;
    _snapshot = _copy(tasks: items);
  }

  @override
  Future<void> deleteTask(String id) async {
    _snapshot = _copy(
      tasks: _snapshot.tasks
          .where((item) => item.id != id && item.parentTaskId != id)
          .toList(),
    );
  }

  @override
  Future<void> saveSchedule(ScheduleItem schedule) async {
    final items = [..._snapshot.schedules];
    final index = items.indexWhere((item) => item.id == schedule.id);
    index < 0 ? items.add(schedule) : items[index] = schedule;
    _snapshot = _copy(schedules: items);
  }

  @override
  Future<void> deleteSchedule(String id) async {
    _snapshot = _copy(
      schedules: _snapshot.schedules.where((item) => item.id != id).toList(),
    );
  }

  @override
  Future<void> saveActivity(ActivityItem activity) async {
    final items = [..._snapshot.activities];
    final index = items.indexWhere((item) => item.id == activity.id);
    index < 0 ? items.add(activity) : items[index] = activity;
    _snapshot = _copy(activities: items);
  }

  @override
  Future<void> deleteActivity(String id) async {
    _snapshot = _copy(
      activities: _snapshot.activities.where((item) => item.id != id).toList(),
    );
  }

  ProductivitySnapshot _copy({
    List<TaskItem>? tasks,
    List<ScheduleItem>? schedules,
    List<ActivityItem>? activities,
  }) {
    final allTasks = tasks ?? _snapshot.tasks;
    final allSchedules = schedules ?? _snapshot.schedules;
    final allActivities = activities ?? _snapshot.activities;
    return ProductivitySnapshot(
      tasks: allTasks,
      schedules: allSchedules,
      activities: allActivities,
      summary: ProductivitySummary(
        activeTasks: allTasks.where((item) => !item.isCompleted).length,
        completedTasks: allTasks.where((item) => item.isCompleted).length,
        todaySchedules: allSchedules.length,
        todayActivityMinutes: allActivities.fold(
          0,
          (sum, item) => sum + (item.durationMinutes ?? 0),
        ),
      ),
    );
  }
}

class FakeReminderScheduler implements ReminderScheduler {
  final scheduled = <String>[];
  final cancelled = <String>[];

  @override
  Future<void> schedule({
    required String targetType,
    required String targetId,
    required String title,
    required DateTime scheduledAt,
    required RepeatRule repeatRule,
  }) async {
    scheduled.add('$targetType:$targetId');
  }

  @override
  Future<void> cancel(String targetType, String targetId) async {
    cancelled.add('$targetType:$targetId');
  }
}
