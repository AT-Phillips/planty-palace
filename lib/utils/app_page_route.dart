import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Builds the app's standard push transition. Uses [CupertinoPageRoute] so
/// pushes get the native iOS slide-in-from-right animation *and* the
/// interactive swipe-from-left-edge back gesture for free - a distinctly more
/// "iOS" feel than the default [MaterialPageRoute] fade/slide-up, at zero
/// extra cost. New screens should navigate via this instead of constructing
/// a [MaterialPageRoute] directly.
///
/// Existing [MaterialPageRoute] call sites still work; they can be migrated to
/// this incrementally.
Route<T> appRoute<T>(Widget page, {String? name}) {
  return CupertinoPageRoute<T>(
    builder: (_) => page,
    settings: name == null ? null : RouteSettings(name: name),
  );
}

/// Convenience for the common `Navigator.push(context, appRoute(Page()))`.
Future<T?> pushScreen<T>(BuildContext context, Widget page, {String? name}) {
  return Navigator.of(context).push<T>(appRoute<T>(page, name: name));
}
