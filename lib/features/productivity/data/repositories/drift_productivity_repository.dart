import 'package:drift/drift.dart';
import 'package:nara/database/app_database.dart' as db;
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';
import 'package:nara/features/productivity/domain/repositories/productivity_repository.dart';

class DriftProductivityRepository implements ProductivityRepository {
  DriftProductivityRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<ProductivitySnapshot> loadSnapshot({
    required DateTime day,
    String taskSearch = '',
    TaskStatus? taskStatus,
  }) async {
    final taskRows = await (_database.select(
      _database.tasks,
    )..orderBy([(row) => OrderingTerm.asc(row.dueDate)])).get();
    final scheduleRows = await (_database.select(
      _database.schedules,
    )..orderBy([(row) => OrderingTerm.asc(row.startAt)])).get();
    final activityRows = await (_database.select(
      _database.activityLogs,
    )..orderBy([(row) => OrderingTerm.desc(row.startAt)])).get();
    final reminderRows =
        await (_database.select(_database.reminders)
              ..where((row) => row.isEnabled.equals(true))
              ..orderBy([(row) => OrderingTerm.asc(row.scheduledAt)]))
            .get();

    final query = taskSearch.trim().toLowerCase();
    final tasks = taskRows.map(_task).where((task) {
      final matchesStatus = taskStatus == null || task.status == taskStatus;
      final matchesSearch =
          query.isEmpty ||
          '${task.title} ${task.description ?? ''} ${task.category ?? ''}'
              .toLowerCase()
              .contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
    final schedules = scheduleRows.map(_schedule).toList();
    final activities = activityRows.map(_activity).toList();
    final allTasks = taskRows.map(_task).toList();
    final todaySchedules = schedules.where(
      (item) => _sameDay(item.startAt.toLocal(), day),
    );
    final todayActivities = activities.where(
      (item) => _sameDay(item.startAt.toLocal(), day),
    );
    final now = DateTime.now().toUtc();
    final futureReminders = reminderRows.where(
      (item) => item.scheduledAt.isAfter(now),
    );

    return ProductivitySnapshot(
      tasks: tasks,
      schedules: schedules,
      activities: activities,
      summary: ProductivitySummary(
        activeTasks: allTasks.where((item) => !item.isCompleted).length,
        completedTasks: allTasks.where((item) => item.isCompleted).length,
        todaySchedules: todaySchedules.length,
        todayActivityMinutes: todayActivities.fold(
          0,
          (sum, item) => sum + (item.durationMinutes ?? 0),
        ),
        nextReminder: futureReminders.isEmpty
            ? null
            : futureReminders.first.scheduledAt,
      ),
    );
  }

  @override
  Future<void> saveTask(TaskItem task) async {
    await _database.transaction(() async {
      await _database
          .into(_database.tasks)
          .insertOnConflictUpdate(
            db.TasksCompanion.insert(
              id: task.id,
              parentTaskId: Value(task.parentTaskId),
              title: task.title,
              description: Value(task.description),
              category: Value(task.category),
              priority: Value(task.priority.name),
              status: Value(task.status.name),
              dueDate: Value(task.dueDate?.toUtc()),
              reminderAt: Value(task.reminderAt?.toUtc()),
              repeatRule: Value(
                task.repeatRule == RepeatRule.none
                    ? null
                    : task.repeatRule.name,
              ),
              createdAt: Value(task.createdAt.toUtc()),
              updatedAt: Value(task.updatedAt.toUtc()),
            ),
          );
      await _syncReminder(
        targetType: 'task',
        targetId: task.id,
        scheduledAt: task.reminderAt,
      );
    });
  }

  @override
  Future<void> deleteTask(String id) async {
    await _database.transaction(() async {
      final childIds =
          await (_database.selectOnly(_database.tasks)
                ..addColumns([_database.tasks.id])
                ..where(_database.tasks.parentTaskId.equals(id)))
              .map((row) => row.read(_database.tasks.id))
              .get();
      for (final childId in childIds.whereType<String>()) {
        await _deleteReminder('task', childId);
        await (_database.delete(
          _database.tasks,
        )..where((row) => row.id.equals(childId))).go();
      }
      await _deleteReminder('task', id);
      await (_database.delete(
        _database.tasks,
      )..where((row) => row.id.equals(id))).go();
    });
  }

  @override
  Future<void> saveSchedule(ScheduleItem schedule) async {
    await _database.transaction(() async {
      await _database
          .into(_database.schedules)
          .insertOnConflictUpdate(
            db.SchedulesCompanion.insert(
              id: schedule.id,
              title: schedule.title,
              description: Value(schedule.description),
              startAt: schedule.startAt.toUtc(),
              endAt: schedule.endAt.toUtc(),
              location: Value(schedule.location),
              reminderAt: Value(schedule.reminderAt?.toUtc()),
              repeatRule: Value(
                schedule.repeatRule == RepeatRule.none
                    ? null
                    : schedule.repeatRule.name,
              ),
              createdAt: Value(schedule.createdAt.toUtc()),
              updatedAt: Value(schedule.updatedAt.toUtc()),
            ),
          );
      await _syncReminder(
        targetType: 'schedule',
        targetId: schedule.id,
        scheduledAt: schedule.reminderAt,
      );
    });
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await _database.transaction(() async {
      await _deleteReminder('schedule', id);
      await (_database.delete(
        _database.schedules,
      )..where((row) => row.id.equals(id))).go();
    });
  }

  @override
  Future<void> saveActivity(ActivityItem activity) async {
    await _database
        .into(_database.activityLogs)
        .insertOnConflictUpdate(
          db.ActivityLogsCompanion.insert(
            id: activity.id,
            title: activity.title,
            category: Value(activity.category),
            startAt: activity.startAt.toUtc(),
            endAt: Value(activity.endAt?.toUtc()),
            durationMinutes: Value(activity.durationMinutes),
            notes: Value(activity.notes),
            mood: Value(activity.mood),
            createdAt: Value(activity.createdAt.toUtc()),
            updatedAt: Value(activity.updatedAt.toUtc()),
          ),
        );
  }

  @override
  Future<void> deleteActivity(String id) async {
    await (_database.delete(
      _database.activityLogs,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<void> _syncReminder({
    required String targetType,
    required String targetId,
    required DateTime? scheduledAt,
  }) async {
    await _deleteReminder(targetType, targetId);
    if (scheduledAt == null) return;
    await _database
        .into(_database.reminders)
        .insert(
          db.RemindersCompanion.insert(
            id: '$targetType-$targetId',
            targetType: targetType,
            targetId: targetId,
            scheduledAt: scheduledAt.toUtc(),
            isEnabled: Value(scheduledAt.isAfter(DateTime.now())),
          ),
        );
  }

  Future<void> _deleteReminder(String targetType, String targetId) {
    return (_database.delete(_database.reminders)..where(
          (row) =>
              row.targetType.equals(targetType) & row.targetId.equals(targetId),
        ))
        .go();
  }

  TaskItem _task(db.Task row) => TaskItem(
    id: row.id,
    parentTaskId: row.parentTaskId,
    title: row.title,
    description: row.description,
    category: row.category,
    priority: TaskPriority.fromStorage(row.priority),
    status: TaskStatus.fromStorage(row.status),
    dueDate: row.dueDate,
    reminderAt: row.reminderAt,
    repeatRule: RepeatRule.fromStorage(row.repeatRule),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ScheduleItem _schedule(db.Schedule row) => ScheduleItem(
    id: row.id,
    title: row.title,
    description: row.description,
    startAt: row.startAt,
    endAt: row.endAt,
    location: row.location,
    reminderAt: row.reminderAt,
    repeatRule: RepeatRule.fromStorage(row.repeatRule),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ActivityItem _activity(db.ActivityLog row) => ActivityItem(
    id: row.id,
    title: row.title,
    category: row.category,
    startAt: row.startAt,
    endAt: row.endAt,
    durationMinutes: row.durationMinutes,
    notes: row.notes,
    mood: row.mood,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
