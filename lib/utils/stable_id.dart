/// Deterministically maps a Firestore document ID (String) to a 32-bit int,
/// for use as a `flutter_local_notifications` notification ID — that API
/// requires a plain int, and the same document must always hash to the same
/// int across app runs/platforms so scheduling/cancelling can find the right
/// notification. Dart's built-in `String.hashCode` is *not* guaranteed
/// stable across runs or platforms and must not be used for this.
///
/// FNV-1a 32-bit hash - simple, fast, and deterministic.
int stableNotificationId(String docId) {
  var hash = 0x811C9DC5;
  for (final codeUnit in docId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF; // keep it a positive 32-bit int
}
