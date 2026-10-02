import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'screens/username_setup_screen.dart';
import 'screens/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  await ProfileService.init();
  await NotificationService.init();
  await NotificationService.rescheduleAll();
  await NotificationService.requestBatteryOptimizationExemption();

  runApp(const StudentPlannerApp());
}

class StudentPlannerApp extends StatelessWidget {
  const StudentPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DPlanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.lightGreen,
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: ProfileService.username.isEmpty
          ? const UsernameSetupScreen()
          : const DashboardScreen(),
    );
  }
}
