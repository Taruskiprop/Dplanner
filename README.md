# Student Planner

A Flutter mobile application for students to manage Classes, Exams, and Events with local-first Hive storage and multi-tier local notifications.

## Features

- **Hive Data Model**: Persistent local storage for reminders with TypeAdapters
- **Add Reminder Form**: Choose category (Class, Exam, Event), enter subject and classroom, pick date/time, toggle weekly recurrence, and save
- **Dashboard**: List view with custom category badges/icons and swipe-to-delete
- **Multi-Tier Notifications**: Automatically schedules 3 notifications per reminder:
  - 1 day before
  - 1 hour before
  - 30 minutes before
- **Weekly Recurring**: Notifications repeat every week on the same day and time
- **Custom Audio**: Pick a custom notification sound from local storage

## Project Structure

```
lib/
  main.dart
  models/
    reminder.dart
  adapters/
    reminder_adapter.dart
  services/
    hive_service.dart
    notification_service.dart
  screens/
    dashboard.dart
    add_reminder_screen.dart
  widgets/
    reminder_card.dart
```

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Hive TypeAdapter (Optional)

A manual TypeAdapter is already provided in `lib/adapters/reminder_adapter.dart`. If you prefer generated code:

```bash
flutter pub run build_runner build
```

### 3. Android Configuration

The app requires the following permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

A `FileProvider` is also configured for sharing custom notification sound files.

### 4. Run the App

```bash
flutter run
```

## Custom Notification Sounds

Custom sounds are picked from local storage and stored in the app's private directory. For the best compatibility:

- Use `.mp3`, `.wav`, or `.ogg` files
- On Android, sounds can be referenced by file URI
- For persistent custom sounds across app restarts, place the file in `android/app/src/main/res/raw/` and update the `NotificationService` to use `RawResourceAndroidNotificationSound`

## Notes

- Notifications are automatically rescheduled when the app restarts
- Each reminder gets 3 unique notification IDs (based on Hive key)
- Deleting a reminder cancels its scheduled notifications
- Weekly recurring reminders use `matchDateTimeLiterals` to repeat every week
