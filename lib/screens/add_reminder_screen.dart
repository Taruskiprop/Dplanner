import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class AddReminderScreen extends StatefulWidget {
  final Reminder? reminder;
  final int? editKey;

  const AddReminderScreen({super.key, this.reminder, this.editKey});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _classroomController;
  late String _category;
  late DateTime _dateTime;
  late bool _isWeeklyRecurring;
  late int? _dayOfWeek;
  late DateTime? _givenDate;
  late String _classType;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(
      text: widget.reminder?.subject ?? '',
    );
    _classroomController = TextEditingController(
      text: widget.reminder?.classroom ?? '',
    );
    _category = widget.reminder?.category ?? 'Class';
    _dateTime = widget.reminder?.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    _isWeeklyRecurring = widget.reminder?.isWeeklyRecurring ?? false;
    _dayOfWeek = widget.reminder?.dayOfWeek;
    _givenDate = widget.reminder?.givenDate;
    _classType = widget.reminder?.classType ?? 'Single';
    _priority = widget.reminder?.priority ?? 'medium';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  bool get _isClass => _category == 'Class';
  bool get _isAssignment => _category == 'Assignment';

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );

    if (time == null) return;

    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickTimeOnly() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );

    if (time == null) return;

    setState(() {
      _dateTime = DateTime(_dateTime.year, _dateTime.month, _dateTime.day, time.hour, time.minute);
    });
  }

  Future<void> _pickGivenDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _givenDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (date == null) return;

    setState(() {
      _givenDate = date;
    });
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final reminder = Reminder(
      category: _category,
      subject: _subjectController.text.trim(),
      classroom: _classroomController.text.trim(),
      dateTime: _dateTime,
      isWeeklyRecurring: _isClass ? true : _isWeeklyRecurring,
      priority: _priority,
      dayOfWeek: _isClass ? _dayOfWeek : null,
      givenDate: _isAssignment ? _givenDate : null,
      classType: _isClass ? _classType : 'Single',
    );

    try {
      if (widget.editKey != null && widget.reminder != null) {
        await NotificationService.cancelReminderNotifications(widget.editKey!);
        await HiveService.updateReminder(widget.editKey!, reminder);
        await NotificationService.scheduleReminderNotifications(
          reminder,
          widget.editKey!,
        );
      } else {
        final key = await HiveService.addReminder(reminder);
        await NotificationService.scheduleReminderNotifications(reminder, key);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 360 ? 14.0 : 20.0;
    final fieldSpacing = screenWidth < 360 ? 12.0 : 16.0;
    final titleFontSize = screenWidth < 360 ? 16.0 : 18.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editKey != null ? 'Edit Reminder' : 'New Reminder', style: TextStyle(fontSize: titleFontSize)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAnimatedField(
                  index: 0,
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.category),
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Class', child: Text('Class')),
                      DropdownMenuItem(value: 'Exam', child: Text('Exam')),
                      DropdownMenuItem(value: 'Event', child: Text('Event')),
                      DropdownMenuItem(value: 'Assignment', child: Text('Assignment')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
                  ),
                ),
                SizedBox(height: fieldSpacing),
                _buildAnimatedField(
                  index: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: const Icon(Icons.flag),
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _priority = value);
                      }
                    },
                  ),
                ),
                SizedBox(height: fieldSpacing),
                _buildAnimatedField(
                  index: 2,
                  child: TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: Icon(Icons.book),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                     },
                   ),
                 ),
                 SizedBox(height: fieldSpacing),
                 _buildAnimatedField(
                   index: 3,
                   child: TextFormField(
                     controller: _classroomController,
                    decoration: InputDecoration(
                      labelText: _isAssignment ? 'Assignment Details / Venue' : 'Classroom / Venue',
                      prefixIcon: const Icon(Icons.location_on),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _isAssignment
                            ? 'Please enter assignment details'
                            : 'Please enter a classroom or venue';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: fieldSpacing),
                if (_isClass) ...[
                  _buildAnimatedField(
                    index: 4,
                    child: DropdownButtonFormField<int>(
                      initialValue: _dayOfWeek,
                      decoration: const InputDecoration(
                        labelText: 'Day of Week',
                        prefixIcon: Icon(Icons.calendar_view_day),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Monday')),
                        DropdownMenuItem(value: 2, child: Text('Tuesday')),
                        DropdownMenuItem(value: 3, child: Text('Wednesday')),
                        DropdownMenuItem(value: 4, child: Text('Thursday')),
                        DropdownMenuItem(value: 5, child: Text('Friday')),
                        DropdownMenuItem(value: 6, child: Text('Saturday')),
                        DropdownMenuItem(value: 7, child: Text('Sunday')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _dayOfWeek = value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a day';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: fieldSpacing),
                  _buildAnimatedField(
                    index: 5,
                    child: DropdownButtonFormField<String>(
                      initialValue: _classType,
                      decoration: const InputDecoration(
                        labelText: 'Class Type',
                        prefixIcon: Icon(Icons.class_),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Single', child: Text('Single')),
                        DropdownMenuItem(value: 'Double', child: Text('Double')),
                        DropdownMenuItem(value: 'Triple', child: Text('Triple')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _classType = value);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: fieldSpacing),
                  _buildAnimatedField(
                    index: 6,
                    child: InkWell(
                      onTap: _pickTimeOnly,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          timeFormat.format(_dateTime),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ] else if (_isAssignment) ...[
                  _buildAnimatedField(
                    index: 4,
                    child: InkWell(
                      onTap: _pickGivenDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Given Date',
                          prefixIcon: Icon(Icons.event_available),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _givenDate == null
                              ? 'Pick given date'
                              : dateFormat.format(_givenDate!),
                          style: TextStyle(
                            fontSize: 16,
                            color: _givenDate == null ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: fieldSpacing),
                  _buildAnimatedField(
                    index: 5,
                    child: InkWell(
                      onTap: _pickDateTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date & Time',
                          prefixIcon: Icon(Icons.alarm),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          dateFormat.format(_dateTime),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                 ] else ...[
                   _buildAnimatedField(
                     index: 4,
                     child: InkWell(
                       onTap: _pickDateTime,
                       child: InputDecorator(
                         decoration: const InputDecoration(
                           labelText: 'Date & Time',
                           prefixIcon: Icon(Icons.calendar_today),
                           border: OutlineInputBorder(),
                         ),
                         child: Text(
                           dateFormat.format(_dateTime),
                           style: const TextStyle(fontSize: 16),
                         ),
                       ),
                     ),
                   ),
                   SizedBox(height: fieldSpacing),
                   _buildAnimatedField(
                     index: 5,
                     child: SwitchListTile(
                      title: const Text('Repeat Weekly'),
                      subtitle: Text(
                        _isWeeklyRecurring
                            ? 'Notifications will repeat every week'
                            : 'One-time reminder',
                      ),
                      value: _isWeeklyRecurring,
                      onChanged: (value) {
                        setState(() => _isWeeklyRecurring = value);
                      },
                    ),
                  ),
                ],
                SizedBox(height: fieldSpacing * 1.25),
                _buildAnimatedField(
                  index: 7,
                  child: ElevatedButton(
                    onPressed: _saveReminder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 4,
                    ),
                    child: Text(
                      widget.editKey != null ? 'Update Reminder' : 'Save Reminder',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedField({required int index, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
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
      child: child,
    );
  }
}
