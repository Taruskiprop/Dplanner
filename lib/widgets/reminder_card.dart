import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final int reminderId;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.reminderId,
  });

  Color _getCategoryColor() {
    switch (reminder.category) {
      case 'Class':
        return Colors.lightGreen;
      case 'Exam':
        return Colors.amber;
      case 'Event':
        return Colors.teal;
      case 'Assignment':
        return Colors.orange;
      default:
        return Colors.yellow;
    }
  }

  Color _getPriorityColor() {
    switch (reminder.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (reminder.category) {
      case 'Class':
        return Icons.school;
      case 'Exam':
        return Icons.edit;
      case 'Event':
        return Icons.event;
      case 'Assignment':
        return Icons.assignment;
      default:
        return Icons.notification_important;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    try {
      debugPrint('Delete dialog opened for reminderId $reminderId: ${reminder.subject}');
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Reminder'),
          content: Text('Delete "${reminder.subject}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      debugPrint('Delete confirmation result for reminderId $reminderId: $confirmed');

      if (confirmed == true) {
        try {
          await NotificationService.cancelReminderNotifications(reminderId);
          debugPrint('Notifications cancelled for reminderId $reminderId');
          
          await HiveService.deleteReminder(reminderId);
          debugPrint('Reminder deleted from Hive for reminderId $reminderId');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${reminder.subject}" deleted')),
            );
          }
        } catch (e) {
          debugPrint('Error during delete for reminderId $reminderId: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: $e')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _confirmDelete for reminderId $reminderId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final timeFormat = DateFormat('hh:mm a');

    String subtitle = reminder.classroom;
    if (reminder.category == 'Class' && reminder.dayOfWeek != null) {
      final dayName = _dayName(reminder.dayOfWeek!);
      final typeLabel = reminder.classType == 'Single' ? '' : ' ${reminder.classType}';
      subtitle += ' • $dayName at ${timeFormat.format(reminder.dateTime)}$typeLabel';
    } else {
      subtitle += ' • ${dateFormat.format(reminder.dateTime)}';
    }

    final extra = <Widget>[];
    if (reminder.category == 'Assignment' && reminder.givenDate != null) {
      extra.add(Text(
        'Given: ${dateFormat.format(reminder.givenDate!)}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ));
    }
    if (reminder.isWeeklyRecurring) {
      extra.add(Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          reminder.category == 'Class'
              ? 'Weekly'
              : 'Repeats',
          style: TextStyle(
            fontSize: 11,
            color: Colors.amber[900],
            fontWeight: FontWeight.w500,
          ),
        ),
      ));
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        color: Colors.white.withValues(alpha: 0.95),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 4,
        shadowColor: _getCategoryColor().withValues(alpha: 0.3),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getCategoryColor().withValues(alpha: 0.15),
            child: Icon(_getCategoryIcon(), color: _getCategoryColor()),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  reminder.subject,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reminder.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getPriorityColor(),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              if (extra.isNotEmpty) ...extra,
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context),
          ),
        ),
      ),
    );
  }

  static String _dayName(int weekday) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday];
  }
}
