# Add this file to: android/app/proguard-rules.pro

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Hive specific rules
-keep class io.hive.** { *; }
-keep class * extends io.hive.TypeAdapterFactory { *; }
-keepclassmembers class * extends io.hive.TypeAdapterFactory {
    public <init>(...);
}

# Keep generic signature of Call, Response (R8 full mode)
-keepattributes Signature

# Keep data model classes
-keep class com.example.student_planner.models.** { *; }

# Keep notification service
-keep class com.example.student_plancer.NotificationForegroundService { *; }

# General rules
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**
-dontwarn io.hive.**
