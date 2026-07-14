import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';

abstract interface class ProductivityRepository {
  Future<ProductivitySnapshot> loadSnapshot({
    required DateTime day,
    String taskSearch = '',
    TaskStatus? taskStatus,
  });

  Future<void> saveTask(TaskItem task);
  Future<void> deleteTask(String id);
  Future<void> saveSchedule(ScheduleItem schedule);
  Future<void> deleteSchedule(String id);
  Future<void> saveActivity(ActivityItem activity);
  Future<void> deleteActivity(String id);
}
