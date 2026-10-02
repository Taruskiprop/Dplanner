import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Reminder extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  String subject;

  @HiveField(2)
  String classroom;

  @HiveField(3)
  DateTime dateTime;

  @HiveField(4)
  bool isWeeklyRecurring;

  @HiveField(5)
  int? dayOfWeek;

  @HiveField(6)
  DateTime? givenDate;

  @HiveField(7)
  String classType;

  @HiveField(8)
  String priority;

  Reminder({
    required this.category,
    required this.subject,
    required this.classroom,
    required this.dateTime,
    this.isWeeklyRecurring = false,
    this.dayOfWeek,
    this.givenDate,
    this.classType = 'Single',
    this.priority = 'medium',
  });
}
