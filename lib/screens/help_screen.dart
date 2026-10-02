import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 360 ? 16.0 : 20.0;
    final sectionSpacing = screenWidth < 360 ? 14.0 : 20.0;
    final iconSize = screenWidth < 360 ? 20.0 : 24.0;
    final titleFontSize = screenWidth < 360 ? 15.0 : 16.0;
    final descriptionFontSize = screenWidth < 360 ? 13.0 : 14.0;
    final contactFontSize = screenWidth < 360 ? 14.0 : 15.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('How to Use DPlanner', style: TextStyle(fontSize: titleFontSize + 2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber, Colors.lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(padding),
          children: [
            _buildSection(
              context,
              icon: Icons.info,
              title: 'Welcome to DPlanner',
              description: 'DPlanner helps you manage your classes, exams, events, and assignments with timely reminders.',
              iconSize: iconSize,
              titleFontSize: titleFontSize,
              descriptionFontSize: descriptionFontSize,
            ),
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.add_circle,
              title: 'Add Reminders',
              description: 'Tap the + button to create a new reminder. Choose a category (Class, Exam, Event, or Assignment), enter details, set date/time, and save.',
              iconSize: iconSize,
              titleFontSize: titleFontSize,
              descriptionFontSize: descriptionFontSize,
            ),
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.flag,
              title: 'Priority Levels',
              description: 'Set reminders as Low, Medium, or High priority. High priority items are visually highlighted with a red badge.',
              iconSize: iconSize,
              titleFontSize: titleFontSize,
              descriptionFontSize: descriptionFontSize,
            ),
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.calendar_month,
              title: 'Calendar View',
              description: 'Switch to Calendar view to see your schedule visually. Days with reminders are marked. Tap any day to see its reminders.',
              iconSize: iconSize,
              titleFontSize: titleFontSize,
              descriptionFontSize: descriptionFontSize,
            ),
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.list,
              title: 'List View',
              description: 'Default view shows all your reminders in a scrollable list. Swipe or scroll to browse through your schedule.',
              iconSize: iconSize,
              titleFontSize: titleFontSize,
              descriptionFontSize: descriptionFontSize,
            ),
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.notifications_active,
              title: 'Notifications & Snooze',
              description: 'Get notified before your events. When a notification arrives, use the 5m, 15m, or 1h snooze buttons to delay it.',
              iconSize: iconSize,
              titleFontSize: titleFontSize,
              descriptionFontSize: descriptionFontSize,
            ),
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.person,
              title: 'Your Profile',
              description: 'Set your name in the profile screen. Your name will be included in notification messages for a personal touch.',
              iconSize: iconSize,
              titleFontSize: titleFontSize,
              descriptionFontSize: descriptionFontSize,
            ),
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.repeat,
              title: 'Weekly Recurring',
              description: 'For classes, enable weekly recurring to get notified every week on the selected day and time.',
              iconSize: iconSize,
              titleFontSize: titleFontSize,
              descriptionFontSize: descriptionFontSize,
            ),
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.verified,
              title: 'About the Developer',
              description: 'This app was developed by Boniface Kiprop Tarus, a passionate developer dedicated to helping students manage their academic life effectively.',
              iconSize: iconSize,
              titleFontSize: titleFontSize,
              descriptionFontSize: descriptionFontSize,
            ),
            SizedBox(height: sectionSpacing * 0.8),
            _buildContactRow(context, icon: Icons.person, label: 'Name', value: 'Boniface Kiprop Tarus', iconSize: iconSize, labelFontSize: descriptionFontSize, valueFontSize: contactFontSize),
            SizedBox(height: sectionSpacing * 0.8),
            _buildContactRow(context, icon: Icons.phone, label: 'Phone', value: '0715436152', iconSize: iconSize, labelFontSize: descriptionFontSize, valueFontSize: contactFontSize),
            SizedBox(height: sectionSpacing * 0.8),
            _buildContactRow(context, icon: Icons.email, label: 'Email', value: 'kipropboniface7@gmail.com', iconSize: iconSize, labelFontSize: descriptionFontSize, valueFontSize: contactFontSize),
            SizedBox(height: sectionSpacing),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(iconSize * 0.8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '© ${DateTime.now().year} Boniface Kiprop Tarus. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: descriptionFontSize - 1,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required double iconSize,
    required double titleFontSize,
    required double descriptionFontSize,
  }) {
    return Container(
      padding: EdgeInsets.all(iconSize),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(iconSize * 0.4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: iconSize,
            ),
          ),
          SizedBox(width: iconSize * 0.6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: iconSize * 0.3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: descriptionFontSize,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required double iconSize,
    required double labelFontSize,
    required double valueFontSize,
  }) {
    return Container(
      padding: EdgeInsets.all(iconSize * 0.6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: iconSize * 0.9,
          ),
          SizedBox(width: iconSize * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: iconSize * 0.1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
