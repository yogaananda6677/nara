import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/productivity/application/productivity_service.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';

import '../../helpers/fake_productivity_repository.dart';

void main() {
  test('menolak task tanpa judul dan reminder setelah deadline', () async {
    final service = ProductivityService(
      FakeProductivityRepository(),
      FakeReminderScheduler(),
    );
    final now = DateTime.now();

    final empty = await service.saveTask(
      const TaskInput(
        title: '',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        repeatRule: RepeatRule.none,
      ),
    );
    final invalidReminder = await service.saveTask(
      TaskInput(
        title: 'Task',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        dueDate: now,
        reminderAt: now.add(const Duration(hours: 1)),
        repeatRule: RepeatRule.none,
      ),
    );

    expect(empty, isA<Failure<void>>());
    expect(invalidReminder, isA<Failure<void>>());
  });

  test('menjadwalkan reminder task yang valid', () async {
    final scheduler = FakeReminderScheduler();
    final service = ProductivityService(
      FakeProductivityRepository(),
      scheduler,
    );

    final result = await service.saveTask(
      TaskInput(
        title: 'Meeting',
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        reminderAt: DateTime.now().add(const Duration(hours: 1)),
        repeatRule: RepeatRule.weekly,
      ),
    );

    expect(result, isA<Success<void>>());
    expect(scheduler.scheduled, hasLength(1));
  });

  test('menolak jadwal dengan rentang waktu terbalik', () async {
    final service = ProductivityService(
      FakeProductivityRepository(),
      FakeReminderScheduler(),
    );
    final now = DateTime.now();

    final result = await service.saveSchedule(
      ScheduleInput(
        title: 'Kelas',
        startAt: now,
        endAt: now.subtract(const Duration(minutes: 1)),
        repeatRule: RepeatRule.none,
      ),
    );

    expect(result, isA<Failure<void>>());
  });
}
