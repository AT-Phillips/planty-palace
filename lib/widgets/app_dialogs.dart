import 'package:flutter/material.dart';

import '../styles/app_theme.dart';
import '../utils/haptics.dart';
import 'app_bottom_sheet.dart';
import 'primitives.dart';

/// Dialogs, menus and transient feedback, in the app's own voice.
///
/// Material's [AlertDialog] and [PopupMenuButton] were the last two stock
/// shapes left in the app. Both are strong "template" signals: the dialog for
/// its cramped 24dp padding and right-aligned text-button row, the popup menu
/// for being a *desktop* affordance (a small menu anchored to a tiny icon) in
/// a phone app, where an action sheet rising from the thumb is both easier to
/// hit and the platform-native expectation.

/// A confirmation dialog. Returns true only if the user confirms.
///
/// [destructive] renders the confirm action in the error color and gives it
/// the visual weight - the safe action stays quiet, so the dangerous one is
/// never the one you tap by muscle memory.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final p = context.palette;
      final accent =
          destructive ? Theme.of(context).colorScheme.error : p.fern;

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          decoration: BoxDecoration(
            color: p.cardRaised,
            borderRadius: AppRadius.xlAll,
            boxShadow: p.shadowHi,
          ),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.plantNameStyle(context, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: p.inkSoft,
                ),
              ),
              const SizedBox(height: 24),
              _DialogButton(
                label: confirmLabel,
                background: accent,
                foreground: Colors.white,
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              _DialogButton(
                label: cancelLabel,
                background: Colors.transparent,
                foreground: p.inkSoft,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// A single-field text prompt (New Space, Rename Space, Add note).
///
/// Returns the trimmed text, or null if cancelled or left empty - so callers
/// never have to re-check for blank input.
Future<String?> showAppPrompt(
  BuildContext context, {
  required String title,
  String? hintText,
  String? initialValue,
  String confirmLabel = 'Save',
  int maxLines = 1,
}) async {
  final controller = TextEditingController(text: initialValue);
  try {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final p = context.palette;
        void submit() =>
            Navigator.pop(context, controller.text.trim());

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            decoration: BoxDecoration(
              color: p.cardRaised,
              borderRadius: AppRadius.xlAll,
              boxShadow: p.shadowHi,
            ),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.plantNameStyle(context, size: 20),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: maxLines,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction:
                      maxLines == 1 ? TextInputAction.done : TextInputAction.newline,
                  onSubmitted: maxLines == 1 ? (_) => submit() : null,
                  decoration: InputDecoration(hintText: hintText),
                ),
                const SizedBox(height: 20),
                _DialogButton(
                  label: confirmLabel,
                  background: p.fern,
                  foreground: Colors.white,
                  onTap: submit,
                ),
                const SizedBox(height: 6),
                _DialogButton(
                  label: 'Cancel',
                  background: Colors.transparent,
                  foreground: p.inkSoft,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == null || result.isEmpty) return null;
    return result;
  } finally {
    controller.dispose();
  }
}

/// A full-width dialog action. Deliberately a stacked pair rather than the
/// Material right-aligned text-button row: on a phone, full-width stacked
/// buttons are both easier to hit and give the primary action real weight.
class _DialogButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// One option in a [showAppMenu].
class AppMenuOption<T> {
  final String label;
  final IconData icon;
  final T value;
  final bool destructive;

  /// Marks the currently-active option with a check - so a menu can double as
  /// a picker (sort order, space filter) rather than only a command list.
  final bool selected;

  const AppMenuOption({
    required this.label,
    required this.icon,
    required this.value,
    this.destructive = false,
    this.selected = false,
  });
}

/// A bottom-sheet menu - the replacement for [PopupMenuButton].
///
/// A popup anchored to a 24dp icon is a desktop pattern: on a phone it lands
/// under the user's hand, has tiny targets, and pops in from an arbitrary
/// corner. This rises from the bottom of the screen with full-width rows.
Future<T?> showAppMenu<T>(
  BuildContext context, {
  String? title,
  required List<AppMenuOption<T>> options,
}) {
  return showAppSheet<T>(
    context,
    builder: (context) {
      final p = context.palette;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 2, 24, 10),
                child: Text(title, style: AppTheme.sectionLabelStyle(context)),
              ),
            for (final option in options)
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    Haptics.selection();
                    Navigator.of(context).pop(option.value);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color:
                              option.destructive
                                  ? Theme.of(context).colorScheme.error
                                  : (option.selected ? p.fern : p.inkSoft),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight:
                                  option.selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              color:
                                  option.destructive
                                      ? Theme.of(context).colorScheme.error
                                      : p.ink,
                            ),
                          ),
                        ),
                        if (option.selected)
                          Icon(Icons.check_rounded, size: 19, color: p.fern),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

/// Transient feedback. One helper for every message in the app, so tone,
/// shape and duration are consistent instead of set per call site.
///
/// [onUndo] adds an inline undo action; [error] tints the bar so a failure
/// never looks like a success.
void showAppSnack(
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
  String undoLabel = 'Undo',
  bool error = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final p = Theme.of(context).extension<Palette>();
  final scheme = Theme.of(context).colorScheme;

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: error ? scheme.error : p?.nav,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        action:
            onUndo == null
                ? null
                : SnackBarAction(
                  label: undoLabel,
                  textColor: error ? Colors.white : (p?.fern ?? Colors.white),
                  onPressed: onUndo,
                ),
      ),
    );
}

/// A retryable failure state, for when a load genuinely fails rather than
/// merely returning nothing.
///
/// Previously every repository error was swallowed into `debugPrint`, so a
/// Firestore outage or a signed-out session rendered as an ordinary empty
/// screen - indistinguishable from "you have no plants", with nothing to act
/// on. This says what happened and offers a way out.
class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: p.coralSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 34,
                color: p.coral,
              ),
            ),
            Gap.lg,
            Text(
              'Could not load',
              textAlign: TextAlign.center,
              style: AppTheme.plantNameStyle(context, size: 19),
            ),
            Gap.sm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.45, color: p.inkSoft),
            ),
            Gap.lg,
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
