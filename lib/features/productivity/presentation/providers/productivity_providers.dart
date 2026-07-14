import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/notifications/reminder_scheduler.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/database/database_provider.dart';
import 'package:nara/features/productivity/application/productivity_service.dart';
import 'package:nara/features/productivity/data/repositories/drift_productivity_repository.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';
import 'package:nara/features/productivity/domain/repositories/productivity_repository.dart';

class ProductivityState {
  const ProductivityState({
    required this.snapshot,
    required this.day,
    this.taskSearch = '',
    this.taskStatus,
    this.isMutating = false,
    this.message,
  });

  final ProductivitySnapshot snapshot;
  final DateTime day;
  final String taskSearch;
  final TaskStatus? taskStatus;
  final bool isMutating;
  final String? message;

  ProductivityState copyWith({
    ProductivitySnapshot? snapshot,
    DateTime? day,
    String? taskSearch,
    TaskStatus? taskStatus,
    bool clearTaskStatus = false,
    bool? isMutating,
    String? message,
    bool clearMessage = false,
  }) => ProductivityState(
    snapshot: snapshot ?? this.snapshot,
    day: day ?? this.day,
    taskSearch: taskSearch ?? this.taskSearch,
    taskStatus: clearTaskStatus ? null : taskStatus ?? this.taskStatus,
    isMutating: isMutating ?? this.isMutating,
    message: clearMessage ? null : message ?? this.message,
  );
}

final productivityRepositoryProvider = Provider<ProductivityRepository>((ref) {
  return DriftProductivityRepository(ref.watch(appDatabaseProvider));
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return LocalReminderScheduler();
});

final productivityServiceProvider = Provider<ProductivityService>((ref) {
  return ProductivityService(
    ref.watch(productivityRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
  );
});

final productivityControllerProvider =
    AsyncNotifierProvider<ProductivityController, ProductivityState>(
      ProductivityController.new,
    );

class ProductivityController extends AsyncNotifier<ProductivityState> {
  var _revision = 0;

  @override
  Future<ProductivityState> build() async {
    final day = DateTime.now();
    final snapshot = await ref
        .watch(productivityRepositoryProvider)
        .loadSnapshot(day: day);
    return ProductivityState(snapshot: snapshot, day: day);
  }

  Future<void> refresh() => _reload();

  Future<void> changeDay(int offset) {
    final current = state.value;
    if (current == null) return Future.value();
    return _reload(day: current.day.add(Duration(days: offset)));
  }

  Future<void> setTaskSearch(String search) => _reload(taskSearch: search);

  Future<void> setTaskStatus(TaskStatus? status) =>
      _reload(taskStatus: status, clearTaskStatus: status == null);

  Future<void> _reload({
    DateTime? day,
    String? taskSearch,
    TaskStatus? taskStatus,
    bool clearTaskStatus = false,
  }) async {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(
      day: day,
      taskSearch: taskSearch,
      taskStatus: taskStatus,
      clearTaskStatus: clearTaskStatus,
      clearMessage: true,
    );
    final revision = ++_revision;
    final snapshot = await ref
        .read(productivityRepositoryProvider)
        .loadSnapshot(
          day: next.day,
          taskSearch: next.taskSearch,
          taskStatus: next.taskStatus,
        );
    if (revision != _revision) return;
    state = AsyncData(
      next.copyWith(snapshot: snapshot, isMutating: false, clearMessage: true),
    );
  }

  Future<bool> saveTask(TaskInput input, {TaskItem? existing}) => _execute(
    ref.read(productivityServiceProvider).saveTask(input, existing: existing),
  );

  Future<bool> deleteTask(String id) =>
      _execute(ref.read(productivityServiceProvider).deleteTask(id));

  Future<bool> saveSchedule(ScheduleInput input, {ScheduleItem? existing}) =>
      _execute(
        ref
            .read(productivityServiceProvider)
            .saveSchedule(input, existing: existing),
      );

  Future<bool> deleteSchedule(String id) =>
      _execute(ref.read(productivityServiceProvider).deleteSchedule(id));

  Future<bool> saveActivity(ActivityInput input, {ActivityItem? existing}) =>
      _execute(
        ref
            .read(productivityServiceProvider)
            .saveActivity(input, existing: existing),
      );

  Future<bool> deleteActivity(String id) =>
      _execute(ref.read(productivityServiceProvider).deleteActivity(id));

  Future<bool> _execute(Future<Result<void>> operation) async {
    final current = state.value;
    if (current == null) return false;
    state = AsyncData(current.copyWith(isMutating: true, clearMessage: true));
    final result = await operation;
    if (result case Failure(:final failure)) {
      state = AsyncData(
        current.copyWith(isMutating: false, message: failure.message),
      );
      return false;
    }
    await _reload();
    return true;
  }
}
