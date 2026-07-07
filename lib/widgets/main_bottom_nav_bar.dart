import 'package:flutter/material.dart';

/// Custom bottom navigation: Spaces, Care, a visually prominent central
/// Camera quick-action, and Find. The camera button never changes
/// [selectedIndex] — it's an action, not a tab. Account isn't here; it's
/// reached via the profile avatar in each screen's top-right.
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

    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
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
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.water_drop_outlined,
              label: 'Care',
              selected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            _CameraNavItem(onTap: onCameraTap),
            _NavItem(
              icon: Icons.travel_explore_outlined,
              label: 'Find',
              selected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

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
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraNavItem extends StatelessWidget {
  final VoidCallback onTap;

  const _CameraNavItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                  color: scheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.camera_alt, color: scheme.onPrimary, size: 28),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                'Add',
                style: TextStyle(
                  color: scheme.primary,
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
