import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder.dart';
import '../services/hive_service.dart';
import '../services/profile_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'reminder_channel';
  static const String _channelName = 'Reminders';
  static const String _channelDescription = 'Class, Exam, and Event reminders';

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('Notification permission granted: $granted');
    }

    final info = await _plugin.getNotificationAppLaunchDetails();
    debugPrint('Notification launch details: ${info?.didNotificationLaunchApp}');

    try {
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
      );
      debugPrint('Notification channel created');
    } catch (e) {
      debugPrint('Could not create notification channel: $e');
    }

    final isEnabled = await androidPlugin?.areNotificationsEnabled();
    debugPrint('Notifications enabled: $isEnabled');
  }

  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId != null && actionId.startsWith('snooze_')) {
      final parts = actionId.split('_');
      if (parts.length < 3) return;

      final notificationId = int.tryParse(parts[2]);
      if (notificationId == null) return;

      final reminderId = notificationId ~/ 10;

      final reminders = HiveService.getAllReminders();
      final reminder = reminders.where((r) => r.key == reminderId).firstOrNull;
      if (reminder == null) return;

      if (actionId.startsWith('snooze_5_')) {
        await _snoozeReminder(reminder, reminderId, const Duration(minutes: 5));
      } else if (actionId.startsWith('snooze_15_')) {
        await _snoozeReminder(reminder, reminderId, const Duration(minutes: 15));
      } else if (actionId.startsWith('snooze_60_')) {
        await _snoozeReminder(reminder, reminderId, const Duration(hours: 1));
      }
      return;
    }

    if (payload == null) return;

    final parts = payload.split('|');
    if (parts.length < 2) return;

    final reminderId = int.tryParse(parts[0]);
    if (reminderId == null) return;
  }

  static Future<void> _snoozeReminder(Reminder reminder, int reminderId, Duration duration) async {
    await cancelReminderNotifications(reminderId);
    final snoozedTime = DateTime.now().add(duration);
    final updatedReminder = Reminder(
      category: reminder.category,
      subject: reminder.subject,
      classroom: reminder.classroom,
      dateTime: snoozedTime,
      isWeeklyRecurring: reminder.isWeeklyRecurring,
      priority: reminder.priority,
      dayOfWeek: reminder.dayOfWeek,
      givenDate: reminder.givenDate,
      classType: reminder.classType,
    );
    await HiveService.updateReminder(reminderId, updatedReminder);
    await scheduleReminderNotifications(updatedReminder, reminderId);
    debugPrint('Snoozed ${reminder.subject} for ${duration.inMinutes} minutes');
  }

  static Future<void> requestBatteryOptimizationExemption() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestExactAlarmsPermission();
        debugPrint('Exact alarms permission requested');
      }
    } catch (e) {
      debugPrint('Could not request exact alarms permission: $e');
    }
  }

  static Future<void> scheduleReminderNotifications(
      Reminder reminder, int reminderId) async {
    final scheduledTime = reminder.dateTime;

    final baseId = reminderId * 10;

    final settings = await HiveService.getSettings();
    final enableDayBefore = settings['enableDayBefore'] as bool? ?? true;
    final enableHourBefore = settings['enableHourBefore'] as bool? ?? true;
    final enable30MinBefore = settings['enable30MinBefore'] as bool? ?? true;
    final enableAtTime = settings['enableAtTime'] as bool? ?? true;
    final customMinutesBefore = settings['customMinutesBefore'] as int?;

    debugPrint('Scheduling notifications for ${reminder.subject} at $scheduledTime');

    try {
      if (reminder.category == 'Class' && reminder.dayOfWeek != null) {
        final baseOccurrence = _nextInstanceOfWeekday(reminder.dayOfWeek!, scheduledTime);
        final offsets = <Duration>[];
        if (enableDayBefore) offsets.add(const Duration(days: 1));
        if (enableHourBefore) offsets.add(const Duration(hours: 1));
        if (enable30MinBefore) offsets.add(const Duration(minutes: 30));
        if (customMinutesBefore != null && customMinutesBefore > 0) {
          offsets.add(Duration(minutes: customMinutesBefore));
        }
        if (enableAtTime) offsets.add(Duration.zero);

        final notificationTimes = buildClassNotificationTimes(
          baseOccurrence,
          enableDayBefore: enableDayBefore,
          enableHourBefore: enableHourBefore,
          enable30MinBefore: enable30MinBefore,
          enableAtTime: enableAtTime,
          customMinutesBefore: customMinutesBefore,
        );

        for (var i = 0; i < notificationTimes.length; i++) {
          final notifyTime = notificationTimes[i];
          final offset = offsets[i];
          final id = baseId + i;

          String title;
          String body;
          if (offset == Duration.zero) {
            title = 'Now: ${reminder.subject}';
            body = _buildClassNowBody(reminder);
          } else if (offset == const Duration(minutes: 30)) {
            title = 'In 30 Minutes: ${reminder.subject}';
            body = _buildClassAlmostNowBody(reminder);
          } else if (offset == const Duration(hours: 1)) {
            title = 'Starting Soon: ${reminder.subject}';
            body = _buildClassStartingSoonBody(reminder);
          } else if (offset == const Duration(days: 1)) {
            title = 'Reminder: ${reminder.subject}';
            body = _buildClassDetailBody(reminder);
          } else {
            title = 'Reminder: ${reminder.subject}';
            body = _buildClassMessage(reminder);
          }

          await _scheduleNotification(
            id: id,
            reminder: reminder,
            scheduledTime: notifyTime,
            title: title,
            body: body,
            useWeekly: true,
            targetWeekday: reminder.dayOfWeek!,
            action: 'open',
          );
        }
      } else {
        final offsets = <Duration>[];
        if (enableDayBefore) offsets.add(const Duration(days: 1));
        if (enableHourBefore) offsets.add(const Duration(hours: 1));
        if (enable30MinBefore) offsets.add(const Duration(minutes: 30));
        if (customMinutesBefore != null && customMinutesBefore > 0) {
          offsets.add(Duration(minutes: customMinutesBefore));
        }
        if (enableAtTime) offsets.add(Duration.zero);

        for (var i = 0; i < offsets.length; i++) {
          final offset = offsets[i];
          final notifyTime = scheduledTime.subtract(offset);
          final id = baseId + i;

          String title;
          String body;
          if (offset == Duration.zero) {
            title = 'Now: ${reminder.subject}';
            body = _buildReminderBody(reminder, 'is happening now at ${reminder.classroom}');
          } else if (offset == const Duration(minutes: 30)) {
            title = 'In 30 Minutes: ${reminder.subject}';
            body = _buildReminderBody(reminder, 'at ${reminder.classroom} is about to start');
          } else if (offset == const Duration(hours: 1)) {
            title = 'Starting Soon: ${reminder.subject}';
            body = _buildReminderBody(reminder, 'begins in 1 hour at ${reminder.classroom}');
          } else if (offset == const Duration(days: 1)) {
            title = 'Reminder: ${reminder.subject}';
            body = _buildReminderBody(reminder, 'starts at ${_formatTime(scheduledTime)}');
          } else {
            title = 'Reminder: ${reminder.subject}';
            body = _buildReminderBody(reminder, 'starts in ${offset.inMinutes} minutes at ${reminder.classroom}');
          }

          await _scheduleNotification(
            id: id,
            reminder: reminder,
            scheduledTime: notifyTime,
            title: title,
            body: body,
            action: 'open',
          );
        }
      }

      debugPrint('Notifications scheduled successfully for ${reminder.subject}');
    } catch (e) {
      debugPrint('Failed to schedule notifications: $e');
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required Reminder reminder,
    required DateTime scheduledTime,
    required String title,
    required String body,
    bool useWeekly = false,
    int? targetWeekday,
    String action = 'open',
  }) async {
    DateTime? nextOccurrence;
    if (useWeekly && targetWeekday != null) {
      nextOccurrence = _nextInstanceOfWeekday(targetWeekday, scheduledTime);
    } else if (reminder.isWeeklyRecurring) {
      nextOccurrence = _nextInstanceOfWeekday(scheduledTime.weekday, scheduledTime);
    }

    final tzNow = tz.TZDateTime.now(tz.local);
    final timeToCheck = nextOccurrence != null
        ? tz.TZDateTime.from(nextOccurrence, tz.local)
        : tz.TZDateTime.from(scheduledTime, tz.local);

    if (timeToCheck.isBefore(tzNow)) {
      debugPrint('Skipping past notification: $title at $timeToCheck');
      return;
    }

    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    final vibrationPattern = Int64List(4)
      ..[0] = 0
      ..[1] = 500
      ..[2] = 500
      ..[3] = 500;

    final reminderId = reminder.key as int;
    final payload = '$reminderId|$action';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      actions: [
        AndroidNotificationAction(
          'snooze_5_$id',
          '5m',
          showsUserInterface: false,
          allowGeneratedReplies: false,
        ),
        AndroidNotificationAction(
          'snooze_15_$id',
          '15m',
          showsUserInterface: false,
          allowGeneratedReplies: false,
        ),
        AndroidNotificationAction(
          'snooze_60_$id',
          '1h',
          showsUserInterface: false,
          allowGeneratedReplies: false,
        ),
      ],
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
      categoryIdentifier: 'snooze_category',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final target = nextOccurrence ?? tzScheduled;
    debugPrint('Scheduling notification $id: "$title" at $target');

    if (useWeekly && targetWeekday != null) {
      final nextOccurrence = _nextInstanceOfWeekday(targetWeekday, scheduledTime);
      debugPrint('Weekly notification $id next occurrence: $nextOccurrence');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        nextOccurrence,
        details,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } else if (reminder.isWeeklyRecurring) {
      final nextOccurrence = _nextInstanceOfWeekday(scheduledTime.weekday, scheduledTime);
      debugPrint('Recurring notification $id next occurrence: $nextOccurrence');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        nextOccurrence,
        details,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } else {
      debugPrint('One-time notification $id at $tzScheduled');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        details,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    debugPrint('Notification $id scheduled successfully');
  }

  static List<DateTime> buildClassNotificationTimes(
    DateTime scheduledTime, {
    bool enableDayBefore = true,
    bool enableHourBefore = true,
    bool enable30MinBefore = true,
    bool enableAtTime = true,
    int? customMinutesBefore,
  }) {
    final offsets = <Duration>[];
    if (enableDayBefore) offsets.add(const Duration(days: 1));
    if (enableHourBefore) offsets.add(const Duration(hours: 1));
    if (enable30MinBefore) offsets.add(const Duration(minutes: 30));
    if (customMinutesBefore != null && customMinutesBefore > 0) {
      offsets.add(Duration(minutes: customMinutesBefore));
    }
    if (enableAtTime) offsets.add(Duration.zero);

    return offsets.map((offset) => scheduledTime.subtract(offset)).toList();
  }

  static tz.TZDateTime _nextInstanceOfWeekday(int targetWeekday, DateTime scheduledTime) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    int daysUntilNext = (targetWeekday - next.weekday + 7) % 7;
    if (daysUntilNext == 0 && next.isBefore(now)) {
      daysUntilNext = 7;
    }

    return next.add(Duration(days: daysUntilNext));
  }

  static String _dayName(int weekday) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday];
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _buildGenericMessage(Reminder reminder, String action) {
    final name = ProfileService.username.trim();
    final prefix = name.isEmpty ? '' : 'Hi $name, ';
    return '$prefix${reminder.subject} ${reminder.category.toLowerCase()} $action';
  }

  static String _buildClassMessage(Reminder reminder) {
    final name = ProfileService.username.trim();
    final prefix = name.isEmpty ? '' : 'Hi $name, ';
    final type = reminder.classType == 'Single' ? '' : ' ${reminder.classType}';
    return '$prefix${reminder.subject}$type class at ${_formatTime(reminder.dateTime)} on ${_dayName(reminder.dayOfWeek!)} in ${reminder.classroom}';
  }

  static String _buildClassStartingMessage(Reminder reminder) {
    final name = ProfileService.username.trim();
    final prefix = name.isEmpty ? '' : 'Hi $name, ';
    final type = reminder.classType == 'Single' ? '' : ' ${reminder.classType}';
    return '$prefix${reminder.subject}$type class at ${reminder.classroom} in 1 hour';
  }

  static String _buildClassAboutMessage(Reminder reminder) {
    final name = ProfileService.username.trim();
    final prefix = name.isEmpty ? '' : 'Hi $name, ';
    final type = reminder.classType == 'Single' ? '' : ' ${reminder.classType}';
    return '$prefix${reminder.subject}$type class at ${reminder.classroom} is about to start';
  }

  static String _buildClassNowMessage(Reminder reminder) {
    final name = ProfileService.username.trim();
    final prefix = name.isEmpty ? '' : 'Hi $name, ';
    final type = reminder.classType == 'Single' ? '' : ' ${reminder.classType}';
    return '$prefix${reminder.subject}$type class is happening now at ${reminder.classroom}';
  }

  static String _buildClassDetailBody(Reminder reminder) {
    return _buildClassMessage(reminder);
  }

  static String _buildClassStartingSoonBody(Reminder reminder) {
    return _buildClassStartingMessage(reminder);
  }

  static String _buildClassAlmostNowBody(Reminder reminder) {
    return _buildClassAboutMessage(reminder);
  }

  static String _buildClassNowBody(Reminder reminder) {
    return _buildClassNowMessage(reminder);
  }

  static String _buildReminderBody(Reminder reminder, String actionText) {
    return _buildGenericMessage(reminder, actionText);
  }

  static Future<void> cancelReminderNotifications(int reminderId) async {
    final baseId = reminderId * 10;
    for (var i = 0; i < 20; i++) {
      try {
        await _plugin.cancel(baseId + i);
      } catch (e) {
        debugPrint('Could not cancel notification $baseId + $i: $e');
      }
    }
  }

  static Future<void> rescheduleAll() async {
    final reminders = HiveService.getAllReminders();
    for (final reminder in reminders) {
      if (reminder.key is int) {
        await scheduleReminderNotifications(reminder, reminder.key as int);
      }
    }
  }

  static Future<void> sendTestNotification() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    try {
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
      );
    } catch (e) {
      debugPrint('Could not ensure notification channel: $e');
    }

    final granted = await androidPlugin?.areNotificationsEnabled();
    debugPrint('Notifications enabled before test: $granted');

    final vibrationPattern = Int64List(4)..[0] = 0..[1] = 500..[2] = 500..[3] = 500;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: 'default',
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.show(
        999,
        'DPlanner Test',
        'Notifications are working, ${ProfileService.username.trim().isEmpty ? '' : 'Hi ${ProfileService.username.trim()}, '}this is a test alert.',
        details,
      );
      debugPrint('Test notification shown immediately');
    } catch (e) {
      debugPrint('Failed to show test notification: $e');
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }

      await _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Could not open notification settings: $e');
    }
  }

  static Future<void> openAppNotificationSettings() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Could not open app notification settings: $e');
    }
  }

  static Future<Map<String, dynamic>> checkNotificationStatus() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    final result = <String, dynamic>{
      'notificationsEnabled': false,
      'channelExists': false,
      'permissionGranted': false,
    };

    try {
      result['notificationsEnabled'] = await androidPlugin?.areNotificationsEnabled() ?? false;
    } catch (e) {
      debugPrint('Could not check notifications enabled: $e');
    }

    try {
      result['channelExists'] = true;
    } catch (e) {
      debugPrint('Could not check notification channels: $e');
    }

    try {
      final granted = await androidPlugin?.requestNotificationsPermission();
      result['permissionGranted'] = granted ?? false;
    } catch (e) {
      debugPrint('Could not request notification permission: $e');
    }

    return result;
  }
}
