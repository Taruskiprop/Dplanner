import 'package:hive/hive.dart';
import '../models/reminder.dart';

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 0;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      category: fields[0] as String,
      subject: fields[1] as String,
      classroom: fields[2] as String,
      dateTime: fields[3] as DateTime,
      isWeeklyRecurring: fields[4] as bool,
      dayOfWeek: fields[5] as int?,
      givenDate: fields[6] as DateTime?,
      classType: (fields[7] as String?) ?? 'Single',
      priority: (fields[8] as String?) ?? 'medium',
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer.writeByte(9);
    writer.writeByte(0);
    writer.write(obj.category);
    writer.writeByte(1);
    writer.write(obj.subject);
    writer.writeByte(2);
    writer.write(obj.classroom);
    writer.writeByte(3);
    writer.write(obj.dateTime);
    writer.writeByte(4);
    writer.write(obj.isWeeklyRecurring);
    writer.writeByte(5);
    writer.write(obj.dayOfWeek);
    writer.writeByte(6);
    writer.write(obj.givenDate);
    writer.writeByte(7);
    writer.write(obj.classType);
    writer.writeByte(8);
    writer.write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
