import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
// Home screen widget disabled for now - see "Later" section of the
// project roadmap. Re-enable this import along with the calls below.
// import 'services/home_widget_service.dart';
import 'services/location_preferences.dart';
import 'services/notification_preferences.dart';
import 'services/notification_service.dart';
import 'services/onboarding_preferences.dart';
import 'services/theme_controller.dart';
import 'services/unit_preferences.dart';
import 'services/weather_preferences.dart';
import 'styles/app_theme.dart';
import 'utils/app_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase isn't configured for Windows/Linux desktop (used for local dev)
  // - skip there so `flutter run -d windows` keeps working. Any Firebase
  // failure here (e.g. a sign-in provider not yet enabled in the console)
  // must never block app startup - the rest of the app works fine without
  // an authenticated user.
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint('Firebase init failed, continuing without it: $e');
    }

    // Attests requests genuinely come from this app before Functions/
    // Firestore/Storage serve them (bug/bot/abuse protection). DeviceCheck
    // provider chosen over App Attest specifically because it needs no
    // Xcode capability/entitlements change - see the project roadmap.
    // Monitor-only for now: enforcement isn't turned on server-side yet.
    try {
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.deviceCheck,
        androidProvider: AndroidProvider.playIntegrity,
      );
    } catch (e) {
      debugPrint('App Check activation failed, continuing without it: $e');
    }

    try {
      await AuthService.instance.ensureSignedIn();
    } catch (e) {
      debugPrint('Sign-in failed, continuing without it: $e');
    }
  }

  await NotificationService().initialize();
  await ThemeController.instance.load();
  await NotificationPreferences.instance.load();
  await WeatherPreferences.instance.load();
  await UnitPreferences.instance.load();
  await LocationPreferences.instance.load();
  await OnboardingPreferences.instance.load();
  NotificationPreferences.instance.onReminderTimeChanged =
      () => NotificationService().refreshAllReminders();
  NotificationPreferences.instance.onEnabledChanged =
      () => NotificationService().refreshAllReminders();

  // Home screen widget disabled for now - see "Later" section of the
  // project roadmap.
  // if (Platform.isAndroid || Platform.isIOS) {
  //   HomeWidgetService().refresh();
  //   AppLifecycleListener(
  //     onResume: () => HomeWidgetService().refresh(),
  //   );
  // }

  runApp(const ThicketApp());
}

class ThicketApp extends StatelessWidget {
  const ThicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<int>(
          valueListenable: ThemeController.instance.accentColorIndex,
          builder: (context, accentIndex, _) {
            final seedColor = ThemeController.accentColors[accentIndex];
            return MaterialApp(
              title: 'Thicket',
              theme: AppTheme.lightTheme(seedColor: seedColor),
              darkTheme: AppTheme.darkTheme(seedColor: seedColor),
              themeMode: mode,
              scrollBehavior: AppScrollBehavior(),
              home: OnboardingPreferences.instance.completed.value
                  ? const MainShell()
                  : const OnboardingScreen(),
            );
          },
        );
      },
    );
  }
}
