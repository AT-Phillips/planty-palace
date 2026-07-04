import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'firebase_options.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/theme_controller.dart';
import 'styles/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI database for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Firebase isn't configured for Windows/Linux desktop (used for local dev)
  // - skip there so `flutter run -d windows` keeps working.
  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await AuthService.instance.ensureSignedIn();
  }

  await NotificationService().initialize();
  await ThemeController.instance.load();

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
          home: const MainShell(),
        );
      },
    );
  }
}
