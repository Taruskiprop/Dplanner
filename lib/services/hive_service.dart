import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder.dart';
import '../adapters/reminder_adapter.dart';

class HiveService {
  static const String _reminderBoxName = 'reminders';
  static const String _settingsBoxName = 'settings';

  static Future<void> init() async {
    Hive.registerAdapter(ReminderAdapter());
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_reminderBoxName)) {
      await Hive.openBox<Reminder>(_reminderBoxName);
    }
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      await Hive.openBox(_settingsBoxName);
    }
  }

  static Box<Reminder> get box {
    try {
      if (!Hive.isBoxOpen(_reminderBoxName)) {
        throw StateError('Hive box "$_reminderBoxName" is not open');
      }
      return Hive.box<Reminder>(_reminderBoxName);
    } on Exception catch (e) {
      throw StateError('Unable to access Hive box "$_reminderBoxName": $e');
    }
  }

  static Box<dynamic> get settingsBox {
    try {
      if (!Hive.isBoxOpen(_settingsBoxName)) {
        throw StateError('Hive box "$_settingsBoxName" is not open');
      }
      return Hive.box(_settingsBoxName);
    } on Exception catch (e) {
      throw StateError('Unable to access Hive box "$_settingsBoxName": $e');
    }
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final settings = settingsBox.get('default');
    if (settings is Map) {
      return Map<String, dynamic>.from(settings);
    }
    final defaultSettings = <String, dynamic>{
      'enableDayBefore': true,
      'enableHourBefore': true,
      'enable30MinBefore': true,
      'enableAtTime': true,
      'enableWeeklyReminders': true,
      'customMinutesBefore': null,
    };
    await settingsBox.put('default', defaultSettings);
    return defaultSettings;
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await settingsBox.put('default', settings);
  }

  static Future<bool> isFirstLaunch() async {
    final value = settingsBox.get('firstLaunch');
    if (value == null) {
      await settingsBox.put('firstLaunch', false);
      return true;
    }
    return value == true;
  }

  static Future<void> setFirstLaunchComplete() async {
    await settingsBox.put('firstLaunch', false);
  }

  static Future<int> addReminder(Reminder reminder) async {
    return await box.add(reminder);
  }

  static Future<void> updateReminder(int key, Reminder reminder) async {
    await box.put(key, reminder);
  }

  static Future<void> deleteReminder(int key) async {
    try {
      debugPrint('Attempting to delete reminder with key: $key');
      await box.delete(key);
      debugPrint('Successfully deleted reminder with key: $key');
    } catch (e) {
      debugPrint('Failed to delete reminder with key $key: $e');
      rethrow;
    }
  }

  static List<Reminder> getAllReminders() {
    return box.values.toList();
  }
}
