import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late bool _enableDayBefore;
  late bool _enableHourBefore;
  late bool _enable30MinBefore;
  late bool _enableAtTime;
  late bool _enableWeeklyReminders;
  late TextEditingController _customMinutesController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customMinutesController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await HiveService.getSettings();
    setState(() {
      _enableDayBefore = settings['enableDayBefore'] as bool? ?? true;
      _enableHourBefore = settings['enableHourBefore'] as bool? ?? true;
      _enable30MinBefore = settings['enable30MinBefore'] as bool? ?? true;
      _enableAtTime = settings['enableAtTime'] as bool? ?? true;
      _enableWeeklyReminders = settings['enableWeeklyReminders'] as bool? ?? true;
      _customMinutesController.text = (settings['customMinutesBefore'] as int?)?.toString() ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final customMinutes = int.tryParse(_customMinutesController.text);
    final settings = <String, dynamic>{
      'enableDayBefore': _enableDayBefore,
      'enableHourBefore': _enableHourBefore,
      'enable30MinBefore': _enable30MinBefore,
      'enableAtTime': _enableAtTime,
      'enableWeeklyReminders': _enableWeeklyReminders,
      'customMinutesBefore': customMinutes,
    };
    await HiveService.saveSettings(settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose when you want to be reminded',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildSwitchTile(
                    context,
                    title: 'Remind me 1 day before',
                    subtitle: 'Get a reminder one day before the event',
                    value: _enableDayBefore,
                    onChanged: (value) {
                      setState(() {
                        _enableDayBefore = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    context,
                    title: 'Remind me 1 hour before',
                    subtitle: 'Get a reminder one hour before the event',
                    value: _enableHourBefore,
                    onChanged: (value) {
                      setState(() {
                        _enableHourBefore = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    context,
                    title: 'Remind me 30 minutes before',
                    subtitle: 'Get a reminder 30 minutes before the event',
                    value: _enable30MinBefore,
                    onChanged: (value) {
                      setState(() {
                        _enable30MinBefore = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    context,
                    title: 'Remind me at the exact time',
                    subtitle: 'Get a reminder when the event starts',
                    value: _enableAtTime,
                    onChanged: (value) {
                      setState(() {
                        _enableAtTime = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Custom reminder',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Minutes before event',
                      hintText: 'e.g., 15',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    controller: _customMinutesController,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primary,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
