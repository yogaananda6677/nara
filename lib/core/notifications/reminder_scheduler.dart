import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract interface class ReminderScheduler {
  Future<void> schedule({
    required String targetType,
    required String targetId,
    required String title,
    required DateTime scheduledAt,
    required RepeatRule repeatRule,
  });

  Future<void> cancel(String targetType, String targetId);
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initializing;

  Future<void> _initialize() => _initializing ??= _doInitialize();

  Future<void> _doInitialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_nara'),
      ),
    );
  }

  @override
  Future<void> schedule({
    required String targetType,
    required String targetId,
    required String title,
    required DateTime scheduledAt,
    required RepeatRule repeatRule,
  }) async {
    await _initialize();
    await cancel(targetType, targetId);
    if (!scheduledAt.isAfter(DateTime.now())) return;
    if (!kIsWeb && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    final localTime = tz.TZDateTime.from(scheduledAt, tz.local);
    await _plugin.zonedSchedule(
      id: _notificationId(targetType, targetId),
      title: targetType == 'task' ? 'Pengingat task' : 'Pengingat jadwal',
      body: title,
      scheduledDate: localTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'nara_reminders',
          'Pengingat Nara',
          channelDescription: 'Reminder task dan jadwal offline',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: '$targetType:$targetId',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: switch (repeatRule) {
        RepeatRule.daily => DateTimeComponents.time,
        RepeatRule.weekly => DateTimeComponents.dayOfWeekAndTime,
        RepeatRule.monthly => DateTimeComponents.dayOfMonthAndTime,
        RepeatRule.none => null,
      },
    );
  }

  @override
  Future<void> cancel(String targetType, String targetId) async {
    await _initialize();
    await _plugin.cancel(id: _notificationId(targetType, targetId));
  }

  int _notificationId(String type, String id) =>
      Object.hash(type, id) & 0x7fffffff;
}
