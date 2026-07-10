import 'package:flutter/services.dart';

/// Thin, intention-named wrapper over [HapticFeedback] so call sites read as
/// what they *mean* ("a care action succeeded") rather than which physical
/// impact to play. Keeps haptic usage consistent app-wide and gives one
/// place to tune or globally disable feedback later.
///
/// On platforms without haptics (or with them disabled), the underlying
/// platform channel calls are safe no-ops, so callers never need to guard.
class Haptics {
  const Haptics._();

  /// A light tap - for selecting a segment, opening a sheet, toggling a chip.
  static void selection() => HapticFeedback.selectionClick();

  /// A soft bump - a lightweight confirmation (e.g. adding a photo).
  static void light() => HapticFeedback.lightImpact();

  /// A firmer bump - a committing action the user should feel land, e.g.
  /// completing a slide-to-confirm care log.
  static void medium() => HapticFeedback.mediumImpact();

  /// A pronounced bump - reserved for the most consequential confirmations.
  static void heavy() => HapticFeedback.heavyImpact();

  /// A warning-style buzz - for a blocked/failed action.
  static void warning() => HapticFeedback.vibrate();
}
