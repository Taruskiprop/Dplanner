import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../widgets/reminder_card.dart';
import 'add_reminder_screen.dart';
import 'calendar_view.dart';
import 'help_screen.dart';
import 'reminder_settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedView = 0;
  bool _isCheckingFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final isFirst = await HiveService.isFirstLaunch();
    if (isFirst && mounted) {
      await HiveService.setFirstLaunchComplete();
      await NotificationService.openAppNotificationSettings();
    }
    if (mounted) {
      setState(() {
        _isCheckingFirstLaunch = false;
      });
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final controller = TextEditingController(text: ProfileService.username);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await ProfileService.setUsername(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    }
  }

  Future<void> _testNotification(BuildContext context) async {
    await NotificationService.sendTestNotification();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent')),
      );
    }
  }

  Future<void> _openNotificationSettings(BuildContext context) async {
    await NotificationService.openNotificationSettings();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening notification settings...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingFirstLaunch) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth >= 360 && screenWidth < 400;

        final horizontalPadding = isSmallScreen ? 10.0 : isMediumScreen ? 14.0 : 18.0;
        final verticalPadding = isSmallScreen ? 5.0 : isMediumScreen ? 7.0 : 9.0;
        final iconSize = isSmallScreen ? 22.0 : isMediumScreen ? 26.0 : 30.0;
        final titleFontSize = isSmallScreen ? 15.0 : isMediumScreen ? 17.0 : 19.0;
        final bodyFontSize = isSmallScreen ? 13.0 : isMediumScreen ? 14.0 : 15.0;
        final cardSpacing = isSmallScreen ? 8.0 : isMediumScreen ? 10.0 : 12.0;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/app_icon.jpg',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: isSmallScreen ? 6 : 10),
                Text(
                  'DPlanner',
                  style: TextStyle(fontSize: titleFontSize),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () => _testNotification(context),
                icon: Icon(Icons.notifications_active, size: iconSize),
                tooltip: 'Test Notification',
              ),
              IconButton(
                onPressed: () => _openNotificationSettings(context),
                icon: Icon(Icons.settings, size: iconSize),
                tooltip: 'Notification Settings',
              ),
              IconButton(
                onPressed: () => _navigateToReminderSettings(context),
                icon: Icon(Icons.alarm, size: iconSize),
                tooltip: 'Reminder Times',
              ),
              IconButton(
                onPressed: () => _editProfile(context),
                icon: Icon(Icons.person, size: iconSize),
                tooltip: 'Edit Profile',
              ),
              IconButton(
                onPressed: () => _navigateToHelp(context),
                icon: Icon(Icons.help_outline, size: iconSize),
                tooltip: 'How to Use',
              ),
            ],
          ),
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
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
                        Expanded(
                          child: _ViewToggle(
                            selected: _selectedView == 0,
                            icon: Icons.list,
                            label: 'List',
                            onTap: () => setState(() => _selectedView = 0),
                            iconSize: iconSize,
                            labelFontSize: bodyFontSize,
                          ),
                        ),
                        Expanded(
                          child: _ViewToggle(
                            selected: _selectedView == 1,
                            icon: Icons.calendar_month,
                            label: 'Calendar',
                            onTap: () => setState(() => _selectedView = 1),
                            iconSize: iconSize,
                            labelFontSize: bodyFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: HiveService.box.listenable(),
                      builder: (context, Box<Reminder> box, _) {
                        final name = ProfileService.username.trim();
                        final greeting = name.isEmpty ? '' : 'Hi $name,';

                        if (box.isEmpty) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - kToolbarHeight - 48,
                              ),
                              child: IntrinsicHeight(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 2),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        TweenAnimationBuilder(
                                          tween: Tween<double>(begin: 0.8, end: 1),
                                          duration: const Duration(milliseconds: 800),
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Icon(Icons.inbox, size: iconSize * 2.5, color: Colors.white70),
                                            );
                                          },
                                        ),
                                        SizedBox(height: verticalPadding * 3),
                                        Text(
                                          greeting.isEmpty ? 'No reminders yet' : '$greeting\nNo reminders yet',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: Colors.white,
                                                fontSize: titleFontSize + 2,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: verticalPadding * 1.5),
                                        Text(
                                          'Tap + to add a class, exam, or event',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.white70,
                                                fontSize: bodyFontSize,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: verticalPadding * 4),
                                        Text(
                                          'Developed by Boniface Tarus',
                                          style: TextStyle(color: Colors.white70, fontSize: bodyFontSize - 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        if (_selectedView == 1) {
                          return CalendarView();
                        }

                        return ListView.builder(
                          padding: EdgeInsets.only(top: verticalPadding * 2, bottom: 80),
                          itemCount: box.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final name = ProfileService.username.trim();
                              final greetingText = name.isEmpty ? 'Your reminders' : 'Hi $name, here are your reminders';
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                                child: Text(
                                  greetingText,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: titleFontSize,
                                      ),
                                ),
                              );
                            }
                            final reminder = box.getAt(index - 1)!;
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: cardSpacing / 2),
                              child: ReminderCard(
                                reminder: reminder,
                                reminderId: reminder.key as int,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                    color: Colors.transparent,
                    child: Text(
                      'Developed by Boniface Tarus',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: bodyFontSize - 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.15).animate(
              CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeInOut,
              ),
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _navigateToAdd(context),
              icon: Icon(Icons.add, size: iconSize),
              label: Text('Add Reminder', style: TextStyle(fontSize: bodyFontSize)),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
          ),
        );
      },
    );
  }

  void _navigateToAdd(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder saved')),
      );
    }
  }

  void _navigateToHelp(BuildContext context) async {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpScreen()),
    );
  }

  void _navigateToReminderSettings(BuildContext context) async {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReminderSettingsScreen()),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;
  final double labelFontSize;

  const _ViewToggle({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 18,
    this.labelFontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
