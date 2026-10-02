import 'package:hive_flutter/hive_flutter.dart';

class ProfileService {
  static const String _boxName = 'profile';
  static const String _usernameKey = 'username';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  static String get username => _box.get(_usernameKey, defaultValue: '') as String;

  static Future<void> setUsername(String name) async {
    await _box.put(_usernameKey, name.trim());
  }
}
