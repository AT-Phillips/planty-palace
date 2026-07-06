import 'package:flutter/material.dart';

import '../services/theme_controller.dart';

const _presetPrefix = 'preset:';

/// Fixed set of icon-on-color preset avatars, reusing the app's existing
/// accent-color palette - offered as an alternative to a real camera/gallery
/// photo since there's no custom illustrated-avatar art in this project.
const List<IconData> presetAvatarIcons = [
  Icons.person,
  Icons.eco,
  Icons.pets,
  Icons.wb_sunny,
  Icons.local_florist,
];

bool isPresetAvatar(String? photoUrl) => photoUrl != null && photoUrl.startsWith(_presetPrefix);

String presetAvatarValue(int index) => '$_presetPrefix$index';

int? presetAvatarIndex(String? photoUrl) {
  if (!isPresetAvatar(photoUrl)) return null;
  return int.tryParse(photoUrl!.substring(_presetPrefix.length));
}

/// Shows the current profile picture: a preset icon-on-color circle, a real
/// synced photo, or (if nothing is set yet) a neutral placeholder circle.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;

  const ProfileAvatar({super.key, required this.photoUrl, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final presetIndex = presetAvatarIndex(photoUrl);
    if (presetIndex != null && presetIndex >= 0 && presetIndex < presetAvatarIcons.length) {
      final color = ThemeController.accentColors[presetIndex % ThemeController.accentColors.length];
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: color,
        child: Icon(presetAvatarIcons[presetIndex], color: Colors.white, size: size * 0.55),
      );
    }

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.surfaceContainerHighest,
      child: Icon(Icons.person_outline, color: scheme.onSurfaceVariant, size: size * 0.55),
    );
  }
}
