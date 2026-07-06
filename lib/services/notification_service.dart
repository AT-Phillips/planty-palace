import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/plant.dart';
import '../utils/stable_id.dart';
import 'notification_preferences.dart';
import 'plant_repository.dart';

/// Schedules local "time to water" reminders.
///
/// flutter_local_notifications does not support the Windows desktop target,
/// so every public method no-ops there — this keeps `flutter run -d windows`
/// usable for developing/testing everything else in the app.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (Platform.isWindows) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> scheduleWateringReminder(Plant plant) async {
    if (Platform.isWindows) return;
    if (!_initialized) return;
    if (!NotificationPreferences.instance.enabled.value) return;

    final plantId = plant.id;
    final lastWatered = plant.lastWatered;
    final intervalDays = plant.wateringIntervalDays;
    if (plantId == null) return;

    final notificationId = stableNotificationId(plantId);
    await cancelReminder(plantId);

    if (lastWatered == null || intervalDays == null) return;

    final reminderTime = NotificationPreferences.instance.reminderTime.value;
    final dueDate = DateTime.parse(lastWatered).add(Duration(days: intervalDays));
    var scheduledDate = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    }

    await _plugin.zonedSchedule(
      notificationId,
      'Time to water ${plant.name}',
      'It\'s been $intervalDays days since ${plant.name} was last watered.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'watering_reminders',
          'Watering reminders',
          channelDescription: 'Reminders to water your plants',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String plantId) async {
    if (Platform.isWindows) return;
    await _plugin.cancel(stableNotificationId(plantId));
  }

  Future<void> scheduleFertilizingReminder(Plant plant) async {
    if (Platform.isWindows) return;
    if (!_initialized) return;
    if (!NotificationPreferences.instance.enabled.value) return;

    final plantId = plant.id;
    final lastFertilized = plant.lastFertilized;
    final intervalDays = plant.fertilizingIntervalDays;
    if (plantId == null) return;

    final notificationId = stableNotificationId('$plantId-fertilize');
    await cancelFertilizingReminder(plantId);

    if (lastFertilized == null || intervalDays == null) return;

    final reminderTime = NotificationPreferences.instance.reminderTime.value;
    final dueDate = DateTime.parse(lastFertilized).add(Duration(days: intervalDays));
    var scheduledDate = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    }

    await _plugin.zonedSchedule(
      notificationId,
      'Time to fertilize ${plant.name}',
      'It\'s been $intervalDays days since ${plant.name} was last fertilized.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fertilizing_reminders',
          'Fertilizing reminders',
          channelDescription: 'Reminders to fertilize your plants',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelFertilizingReminder(String plantId) async {
    if (Platform.isWindows) return;
    await _plugin.cancel(stableNotificationId('$plantId-fertilize'));
  }

  Future<void> scheduleRepottingReminder(Plant plant) async {
    if (Platform.isWindows) return;
    if (!_initialized) return;
    if (!NotificationPreferences.instance.enabled.value) return;

    final plantId = plant.id;
    final lastRepotted = plant.lastRepotted;
    final intervalDays = plant.repottingIntervalDays;
    if (plantId == null) return;

    final notificationId = stableNotificationId('$plantId-repot');
    await cancelRepottingReminder(plantId);

    if (lastRepotted == null || intervalDays == null) return;

    final reminderTime = NotificationPreferences.instance.reminderTime.value;
    final dueDate = DateTime.parse(lastRepotted).add(Duration(days: intervalDays));
    var scheduledDate = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    }

    await _plugin.zonedSchedule(
      notificationId,
      'Time to repot ${plant.name}',
      'It\'s been $intervalDays days since ${plant.name} was last repotted.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'repotting_reminders',
          'Repotting reminders',
          channelDescription: 'Reminders to repot your plants',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelRepottingReminder(String plantId) async {
    if (Platform.isWindows) return;
    await _plugin.cancel(stableNotificationId('$plantId-repot'));
  }

  Future<void> schedulePruningReminder(Plant plant) async {
    if (Platform.isWindows) return;
    if (!_initialized) return;
    if (!NotificationPreferences.instance.enabled.value) return;

    final plantId = plant.id;
    final lastPruned = plant.lastPruned;
    final intervalDays = plant.pruningIntervalDays;
    if (plantId == null) return;

    final notificationId = stableNotificationId('$plantId-prune');
    await cancelPruningReminder(plantId);

    if (lastPruned == null || intervalDays == null) return;

    final reminderTime = NotificationPreferences.instance.reminderTime.value;
    final dueDate = DateTime.parse(lastPruned).add(Duration(days: intervalDays));
    var scheduledDate = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    }

    await _plugin.zonedSchedule(
      notificationId,
      'Time to prune ${plant.name}',
      'It\'s been $intervalDays days since ${plant.name} was last pruned.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pruning_reminders',
          'Pruning reminders',
          channelDescription: 'Reminders to prune your plants',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelPruningReminder(String plantId) async {
    if (Platform.isWindows) return;
    await _plugin.cancel(stableNotificationId('$plantId-prune'));
  }

  /// Re-syncs every plant's watering, fertilizing, repotting, and pruning
  /// reminders against the current reminder time and enabled/disabled
  /// state - schedules all of them if enabled, cancels all of them if
  /// disabled. Called whenever either setting changes.
  Future<void> refreshAllReminders() async {
    final plants = await PlantRepository().getPlants();
    if (NotificationPreferences.instance.enabled.value) {
      for (final plant in plants) {
        await scheduleWateringReminder(plant);
        await scheduleFertilizingReminder(plant);
        await scheduleRepottingReminder(plant);
        await schedulePruningReminder(plant);
      }
    } else {
      for (final plant in plants) {
        await cancelReminder(plant.id!);
        await cancelFertilizingReminder(plant.id!);
        await cancelRepottingReminder(plant.id!);
        await cancelPruningReminder(plant.id!);
      }
    }
  }
}
