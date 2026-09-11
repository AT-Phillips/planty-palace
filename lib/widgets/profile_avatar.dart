import 'package:flutter/material.dart';

import '../styles/app_theme.dart';

const _presetPrefix = 'preset:';

/// Fixed set of icon-on-color preset avatars, offered as an alternative to a
/// real camera/gallery photo since there is no custom illustrated-avatar art
/// in this project.
const List<IconData> presetAvatarIcons = [
  Icons.person,
  Icons.eco,
  Icons.pets,
  Icons.wb_sunny,
  Icons.local_florist,
];

/// Backdrop colors for the preset avatars.
///
/// These used to borrow the (now removed) user-selectable accent palette,
/// which meant a decorative avatar choice was coupled to the app's theming.
/// They are their own thing: a botanical set chosen to sit happily beside
/// the fern accent without competing with the care signal colors.
const List<Color> presetAvatarColors = [
  Color(0xFF2E6B4F), // sage
  Color(0xFF3F8F77), // eucalyptus
  Color(0xFF7A6A4F), // bark
  Color(0xFFB5793C), // clay
  Color(0xFF5C6E8A), // slate blue
];

bool isPresetAvatar(String? photoUrl) =>
    photoUrl != null && photoUrl.startsWith(_presetPrefix);

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
    final p = context.palette;

    final presetIndex = presetAvatarIndex(photoUrl);
    if (presetIndex != null &&
        presetIndex >= 0 &&
        presetIndex < presetAvatarIcons.length) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor:
            presetAvatarColors[presetIndex % presetAvatarColors.length],
        child: Icon(
          presetAvatarIcons[presetIndex],
          color: Colors.white,
          size: size * 0.55,
        ),
      );
    }

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: p.ground2,
        // Decode at the avatar's real size (up to 3x density) rather than at
        // the full resolution of whatever the user uploaded - a 4000px
        // portrait behind a 36px chip is otherwise decoded in full on every
        // main screen.
        backgroundImage: ResizeImage(
          NetworkImage(photoUrl!),
          width: (size * 3).round(),
          allowUpscaling: false,
        ),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: p.ground2,
      child: Icon(
        Icons.person_outline_rounded,
        color: p.inkFaint,
        size: size * 0.55,
      ),
    );
  }
}
