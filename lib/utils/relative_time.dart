/// A short, human-readable "time ago" string, e.g. "Started today",
/// "Started 3 days ago", "Started 2 weeks ago".
String startedAgoText(String isoDate) {
  final started = DateTime.parse(isoDate);
  final today = DateTime.now();
  final days =
      DateTime(
        today.year,
        today.month,
        today.day,
      ).difference(DateTime(started.year, started.month, started.day)).inDays;

  if (days <= 0) return 'Started today';
  if (days == 1) return 'Started yesterday';
  if (days < 14) return 'Started $days days ago';
  if (days < 60) return 'Started ${(days / 7).floor()} weeks ago';
  return 'Started ${(days / 30).floor()} months ago';
}
