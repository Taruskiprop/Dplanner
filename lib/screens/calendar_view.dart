import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/hive_service.dart';
import '../widgets/reminder_card.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _currentMonth;
  final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  final DateFormat _dayFormat = DateFormat('d');

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<Reminder> _getRemindersForDate(DateTime date) {
    final reminders = HiveService.getAllReminders();
    return reminders.where((reminder) {
      final reminderDate = reminder.dateTime;
      if (reminder.isWeeklyRecurring && reminder.dayOfWeek != null) {
        return reminderDate.weekday == date.weekday;
      }
      return reminderDate.year == date.year &&
          reminderDate.month == date.month &&
          reminderDate.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 8.0 : 12.0;
    final verticalPadding = screenWidth < 360 ? 8.0 : 12.0;
    final iconSize = screenWidth < 360 ? 20.0 : 24.0;
    final titleFontSize = screenWidth < 360 ? 16.0 : 18.0;
    final dayFontSize = screenWidth < 360 ? 10.0 : 12.0;
    final cellSpacing = screenWidth < 360 ? 4.0 : 8.0;

    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: Icon(Icons.chevron_left, size: iconSize),
              ),
              Expanded(
                child: Text(
                  _monthFormat.format(_currentMonth),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: titleFontSize,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(Icons.chevron_right, size: iconSize),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Row(
            children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: cellSpacing,
              mainAxisSpacing: cellSpacing,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox.shrink();
              }

              final day = index - startWeekday + 1;
              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              final reminders = _getRemindersForDate(date);
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () {
                  if (reminders.isNotEmpty) {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => ListView.builder(
                        padding: EdgeInsets.all(horizontalPadding),
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = reminders[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReminderCard(
                              reminder: reminder,
                              reminderId: reminder.key as int,
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: reminders.isNotEmpty
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          _dayFormat.format(date),
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.normal,
                            fontSize: dayFontSize,
                            color: isToday
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (reminders.isNotEmpty)
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
