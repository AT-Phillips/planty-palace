import 'package:flutter/material.dart';
import 'package:planty_palace/styles/app_theme.dart';

class IdentifyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const IdentifyButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.search),
      label: const Text('Identify'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 16),
      ),
      onPressed: onPressed,
    );
  }
}
