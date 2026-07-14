import 'package:nara/core/errors/app_failure.dart';
import 'package:nara/core/notifications/reminder_scheduler.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';
import 'package:nara/features/productivity/domain/repositories/productivity_repository.dart';
import 'package:uuid/uuid.dart';

class TaskInput {
  const TaskInput({
    required this.title,
    required this.priority,
    required this.status,
    required this.repeatRule,
    this.parentTaskId,
    this.description,
    this.category,
    this.dueDate,
    this.reminderAt,
  });

  final String title;
  final String? parentTaskId;
  final String? description;
  final String? category;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final RepeatRule repeatRule;
}

class ScheduleInput {
  const ScheduleInput({
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.repeatRule,
    this.description,
    this.location,
    this.reminderAt,
  });

  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final String? location;
  final DateTime? reminderAt;
  final RepeatRule repeatRule;
}

class ActivityInput {
  const ActivityInput({
    required this.title,
    required this.startAt,
    this.category,
    this.endAt,
    this.notes,
    this.mood,
  });

  final String title;
  final String? category;
  final DateTime startAt;
  final DateTime? endAt;
  final String? notes;
  final String? mood;
}

class ProductivityService {
  ProductivityService(this._repository, this._scheduler, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final ProductivityRepository _repository;
  final ReminderScheduler _scheduler;
  final Uuid _uuid;

  Future<Result<void>> saveTask(TaskInput input, {TaskItem? existing}) async {
    final title = input.title.trim();
    if (title.isEmpty || title.length > 200) {
      return _validation('task.invalid', 'Judul task wajib diisi.');
    }
    if (input.reminderAt != null &&
        input.dueDate != null &&
        input.reminderAt!.isAfter(input.dueDate!)) {
      return _validation(
        'task.reminder_invalid',
        'Reminder harus sebelum deadline.',
      );
    }
    final now = DateTime.now().toUtc();
    final item = TaskItem(
      id: existing?.id ?? _uuid.v4(),
      parentTaskId: input.parentTaskId,
      title: title,
      description: _nullable(input.description),
      category: _nullable(input.category),
      priority: input.priority,
      status: input.status,
      dueDate: input.dueDate?.toUtc(),
      reminderAt: input.reminderAt?.toUtc(),
      repeatRule: input.repeatRule,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    return _guard(
      () async {
        await _repository.saveTask(item);
        await _scheduler.cancel('task', item.id);
        if (item.reminderAt != null && !item.isCompleted) {
          await _scheduler.schedule(
            targetType: 'task',
            targetId: item.id,
            title: item.title,
            scheduledAt: item.reminderAt!,
            repeatRule: item.repeatRule,
          );
        }
      },
      'task.save_failed',
      'Task belum dapat disimpan.',
    );
  }

  Future<Result<void>> deleteTask(String id) => _guard(
    () async {
      await _repository.deleteTask(id);
      await _scheduler.cancel('task', id);
    },
    'task.delete_failed',
    'Task belum dapat dihapus.',
  );

  Future<Result<void>> saveSchedule(
    ScheduleInput input, {
    ScheduleItem? existing,
  }) async {
    final title = input.title.trim();
    if (title.isEmpty || !input.endAt.isAfter(input.startAt)) {
      return _validation(
        'schedule.invalid',
        'Judul wajib diisi dan waktu selesai harus setelah mulai.',
      );
    }
    if (input.reminderAt != null && input.reminderAt!.isAfter(input.startAt)) {
      return _validation(
        'schedule.reminder_invalid',
        'Reminder harus sebelum jadwal dimulai.',
      );
    }
    final now = DateTime.now().toUtc();
    final item = ScheduleItem(
      id: existing?.id ?? _uuid.v4(),
      title: title,
      description: _nullable(input.description),
      startAt: input.startAt.toUtc(),
      endAt: input.endAt.toUtc(),
      location: _nullable(input.location),
      reminderAt: input.reminderAt?.toUtc(),
      repeatRule: input.repeatRule,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    return _guard(
      () async {
        await _repository.saveSchedule(item);
        await _scheduler.cancel('schedule', item.id);
        if (item.reminderAt != null) {
          await _scheduler.schedule(
            targetType: 'schedule',
            targetId: item.id,
            title: item.title,
            scheduledAt: item.reminderAt!,
            repeatRule: item.repeatRule,
          );
        }
      },
      'schedule.save_failed',
      'Jadwal belum dapat disimpan.',
    );
  }

  Future<Result<void>> deleteSchedule(String id) => _guard(
    () async {
      await _repository.deleteSchedule(id);
      await _scheduler.cancel('schedule', id);
    },
    'schedule.delete_failed',
    'Jadwal belum dapat dihapus.',
  );

  Future<Result<void>> saveActivity(
    ActivityInput input, {
    ActivityItem? existing,
  }) async {
    final title = input.title.trim();
    if (title.isEmpty ||
        (input.endAt != null && !input.endAt!.isAfter(input.startAt))) {
      return _validation(
        'activity.invalid',
        'Periksa judul dan rentang waktu aktivitas.',
      );
    }
    final duration = input.endAt?.difference(input.startAt).inMinutes;
    final now = DateTime.now().toUtc();
    final item = ActivityItem(
      id: existing?.id ?? _uuid.v4(),
      title: title,
      category: _nullable(input.category),
      startAt: input.startAt.toUtc(),
      endAt: input.endAt?.toUtc(),
      durationMinutes: duration,
      notes: _nullable(input.notes),
      mood: _nullable(input.mood),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    return _guard(
      () => _repository.saveActivity(item),
      'activity.save_failed',
      'Aktivitas belum dapat disimpan.',
    );
  }

  Future<Result<void>> deleteActivity(String id) => _guard(
    () => _repository.deleteActivity(id),
    'activity.delete_failed',
    'Aktivitas belum dapat dihapus.',
  );

  Future<Result<void>> _guard(
    Future<void> Function() action,
    String code,
    String message,
  ) async {
    try {
      await action();
      return const Success(null);
    } catch (error) {
      return Failure(
        LocalServiceFailure(code: code, message: message, cause: error),
      );
    }
  }

  Result<void> _validation(String code, String message) =>
      Failure(ValidationFailure(code: code, message: message));

  String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
