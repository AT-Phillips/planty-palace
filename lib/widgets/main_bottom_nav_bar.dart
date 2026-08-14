import 'package:flutter/material.dart';

import '../styles/app_theme.dart';
import '../utils/haptics.dart';

/// Custom bottom navigation: Spaces, Care, a visually prominent central
/// Camera quick-action, Find, and Guides. Two tabs sit on each side of the
/// camera so it stays centered. The camera button never changes
/// [selectedIndex] — it's an action, not a tab. Account isn't here; it's
/// reached via the profile avatar in each screen's top-right.
///
/// Deliberately a "dark anchor" bar - [Palette.nav] is a dark tone in *both*
/// light and dark themes, so the bar stays a fixed, brand-consistent anchor
/// rather than flipping light when the rest of the app does.
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

  void _tap(int index) {
    Haptics.selection();
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: p.nav,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _NavItem(
                icon: Icons.space_dashboard_outlined,
                label: 'Spaces',
                selected: selectedIndex == 0,
                onTap: () => _tap(0),
              ),
              _NavItem(
                icon: Icons.water_drop_outlined,
                label: 'Care',
                selected: selectedIndex == 1,
                onTap: () => _tap(1),
              ),
              _CameraNavItem(onTap: onCameraTap),
              _NavItem(
                icon: Icons.travel_explore_outlined,
                label: 'Find',
                selected: selectedIndex == 2,
                onTap: () => _tap(2),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                label: 'Guides',
                selected: selectedIndex == 3,
                onTap: () => _tap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // The bar is always dark, so the inactive tone comes from [Palette.navInk]
    // (a light neutral) rather than any theme-relative color, which would be
    // unreadable here in light mode.
    final color = selected ? p.fern : p.navInk.withValues(alpha: 0.65);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A soft fern-tinted rounded square behind the active icon -
              // the mockup's way of marking the current tab without a
              // heavy pill or an underline.
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? p.fern.withValues(alpha: 0.16)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised center capture button - a fern->sage gradient disc with a
/// matching glow, lifted above the bar.
class _CameraNavItem extends StatelessWidget {
  final VoidCallback onTap;

  const _CameraNavItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          Haptics.light();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The disc is 46 tall so the column (disc + label) stays within
            // the 62px bar; Transform lifts it visually without changing the
            // laid-out height, which would overflow.
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [p.fern, p.sage],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: p.fern.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -12),
              child: Text(
                'Add',
                style: TextStyle(
                  color: p.fern,
                  fontSize: 9.5,
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
