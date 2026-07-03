import 'package:flutter/material.dart';

import '../services/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.instance.themeMode,
        builder: (context, mode, _) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                value: ThemeMode.system,
                groupValue: mode,
                onChanged: (value) => ThemeController.instance.setThemeMode(value!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: mode,
                onChanged: (value) => ThemeController.instance.setThemeMode(value!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: mode,
                onChanged: (value) => ThemeController.instance.setThemeMode(value!),
              ),
            ],
          );
        },
      ),
    );
  }
}
