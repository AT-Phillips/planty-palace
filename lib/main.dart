import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'firebase_options.dart';
import 'helpers/database_helper.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'services/notification_preferences.dart';
import 'services/notification_service.dart';
import 'services/theme_controller.dart';
import 'services/weather_preferences.dart';
import 'styles/app_theme.dart';
import 'utils/app_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI database for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Firebase isn't configured for Windows/Linux desktop (used for local dev)
  // - skip there so `flutter run -d windows` keeps working. Any Firebase
  // failure here (e.g. a sign-in provider not yet enabled in the console)
  // must never block app startup - the rest of the app works fine without
  // an authenticated user.
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await AuthService.instance.ensureSignedIn();
    } catch (e) {
      debugPrint('Firebase init/sign-in failed, continuing without it: $e');
    }
  }

  await NotificationService().initialize();
  await ThemeController.instance.load();
  await NotificationPreferences.instance.load();
  await WeatherPreferences.instance.load();
  NotificationPreferences.instance.onReminderTimeChanged = () async {
    final plants = await DatabaseHelper().getPlants();
    for (final plant in plants) {
      await NotificationService().scheduleWateringReminder(plant);
    }
  };

  runApp(const ThicketApp());
}

class ThicketApp extends StatelessWidget {
  const ThicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Thicket',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          scrollBehavior: AppScrollBehavior(),
          home: const MainShell(),
        );
      },
    );
  }
}
