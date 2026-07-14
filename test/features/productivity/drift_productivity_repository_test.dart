import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/database/app_database.dart';
import 'package:nara/features/productivity/data/repositories/drift_productivity_repository.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';

void main() {
  late AppDatabase database;
  late DriftProductivityRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftProductivityRepository(database);
  });

  tearDown(() => database.close());

  test('menyimpan task, kategori, dan reminder pada schema v3', () async {
    final now = DateTime.now();
    final reminder = now.add(const Duration(hours: 1));
    await repository.saveTask(
      TaskItem(
        id: 'task-1',
        title: 'Belajar Drift',
        category: 'Kuliah',
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        dueDate: now.add(const Duration(hours: 2)),
        reminderAt: reminder,
        repeatRule: RepeatRule.none,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final snapshot = await repository.loadSnapshot(day: now);
    expect(snapshot.tasks.single.category, 'Kuliah');
    expect(snapshot.summary.activeTasks, 1);
    expect(snapshot.summary.nextReminder, isNotNull);
    expect(await database.select(database.reminders).get(), hasLength(1));
  });

  test('menghitung agenda dan durasi aktivitas hari terpilih', () async {
    final day = DateTime(2026, 7, 14, 8);
    await repository.saveSchedule(
      ScheduleItem(
        id: 'schedule-1',
        title: 'Kelas',
        startAt: day,
        endAt: day.add(const Duration(hours: 1)),
        repeatRule: RepeatRule.none,
        createdAt: day,
        updatedAt: day,
      ),
    );
    await repository.saveActivity(
      ActivityItem(
        id: 'activity-1',
        title: 'Olahraga',
        startAt: day,
        endAt: day.add(const Duration(minutes: 45)),
        durationMinutes: 45,
        createdAt: day,
        updatedAt: day,
      ),
    );

    final snapshot = await repository.loadSnapshot(day: day);
    expect(snapshot.summary.todaySchedules, 1);
    expect(snapshot.summary.todayActivityMinutes, 45);
  });

  test('menghapus task utama beserta subtask', () async {
    final now = DateTime.now();
    TaskItem item(String id, {String? parent}) => TaskItem(
      id: id,
      parentTaskId: parent,
      title: id,
      priority: TaskPriority.medium,
      status: TaskStatus.pending,
      repeatRule: RepeatRule.none,
      createdAt: now,
      updatedAt: now,
    );
    await repository.saveTask(item('parent'));
    await repository.saveTask(item('child', parent: 'parent'));

    await repository.deleteTask('parent');

    expect((await repository.loadSnapshot(day: now)).tasks, isEmpty);
  });
}
