import 'package:flutter_test/flutter_test.dart';
import 'package:dplanner/services/notification_service.dart';

void main() {
  group('NotificationService class scheduling', () {
    test('uses relative offsets for recurring class reminders', () {
      final classTime = DateTime(2026, 10, 5, 9, 0);

      final times = NotificationService.buildClassNotificationTimes(
        classTime,
        enableDayBefore: true,
        enableHourBefore: true,
        enable30MinBefore: true,
        enableAtTime: true,
      );

      expect(times, [
        DateTime(2026, 10, 4, 9, 0),
        DateTime(2026, 10, 5, 8, 0),
        DateTime(2026, 10, 5, 8, 30),
        DateTime(2026, 10, 5, 9, 0),
      ]);
    });
  });
}
