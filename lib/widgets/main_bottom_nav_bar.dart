import 'package:flutter/material.dart';

import '../services/theme_controller.dart';

/// Custom bottom navigation: Spaces, Care, a visually prominent central
/// Camera quick-action, Find, and Guides. Two tabs sit on each side of the
/// camera so it stays centered. The camera button never changes
/// [selectedIndex] — it's an action, not a tab. Account isn't here; it's
/// reached via the profile avatar in each screen's top-right.
///
/// Deliberately a "dark anchor" bar - it always shows the dark tone of the
/// user's selected background palette, regardless of whether the app itself
/// is currently in light or dark mode. This keeps it customizable (the
/// palette picker still matters) while staying a fixed, brand-consistent
/// anchor rather than flipping light when the rest of the app does.
class MainBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCameraTap;

  const MainBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<int>(
      valueListenable: ThemeController.instance.backgroundPaletteIndex,
      builder: (context, paletteIndex, _) {
        final palette = ThemeController.backgroundPalettes[paletteIndex];

        return SafeArea(
          top: false,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: palette.darkCard,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.space_dashboard_outlined,
                  label: 'Spaces',
                  selected: selectedIndex == 0,
                  activeColor: scheme.primary,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Care',
                  selected: selectedIndex == 1,
                  activeColor: scheme.primary,
                  onTap: () => onTap(1),
                ),
                _CameraNavItem(
                  onTap: onCameraTap,
                  color: scheme.primary,
                  iconColor: scheme.onPrimary,
                ),
                _NavItem(
                  icon: Icons.travel_explore_outlined,
                  label: 'Find',
                  selected: selectedIndex == 2,
                  activeColor: scheme.primary,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Guides',
                  selected: selectedIndex == 3,
                  activeColor: scheme.primary,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed light-on-dark tone for the inactive state - this bar is always
    // dark regardless of the app's light/dark mode, so a theme-relative
    // color (e.g. onSurfaceVariant) would be unreadable here in light mode.
    final color = selected ? activeColor : Colors.white.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraNavItem extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  const _CameraNavItem({
    required this.onTap,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.camera_alt, color: iconColor, size: 28),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                'Add',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
