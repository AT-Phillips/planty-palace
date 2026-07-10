import 'package:flutter/material.dart';

import '../utils/haptics.dart';

/// The app's standard modern bottom sheet: rounded top corners, a grabber
/// handle, scroll-controlled height, and the card surface color. This is the
/// treatment the weather sheet pioneered - now the shared default so every
/// sheet in the app matches, instead of the handle-less plain
/// `showModalBottomSheet`s scattered around today.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: true,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );
}

/// One row in an [showAppActionSheet] - an iOS-style action menu item.
class AppSheetAction<T> {
  final IconData icon;
  final String label;
  final T value;

  /// Destructive actions (delete, remove) render in the error color.
  final bool destructive;

  const AppSheetAction({
    required this.icon,
    required this.label,
    required this.value,
    this.destructive = false,
  });
}

/// A modern replacement for the plain `showModalBottomSheet` + `ListTile`
/// action menus (e.g. the add-photo / photo-options sheets). Presents an
/// optional title/message header over a list of tappable actions, and
/// resolves to the tapped action's [AppSheetAction.value] (or null if
/// dismissed). Fires a selection haptic on tap.
Future<T?> showAppActionSheet<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<AppSheetAction<T>> actions,
}) {
  return showAppSheet<T>(
    context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    if (message != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            for (final action in actions)
              InkWell(
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context).pop(action.value);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  child: Row(
                    children: [
                      Icon(
                        action.icon,
                        size: 22,
                        color: action.destructive ? scheme.error : scheme.onSurface,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        action.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: action.destructive ? scheme.error : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
