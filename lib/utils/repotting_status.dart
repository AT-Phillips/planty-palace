import '../models/plant.dart';

/// Human-readable repotting status for a plant - mirrors
/// lib/utils/fertilizing_status.dart's logic exactly, for repotting instead
/// of fertilizing.
String repottingStatusText(Plant plant) {
  if (plant.lastRepotted == null || plant.repottingIntervalDays == null) {
    return 'No repotting schedule set';
  }
  final dueDate = DateTime.parse(plant.lastRepotted!)
      .add(Duration(days: plant.repottingIntervalDays!));
  final today = DateTime.now();
  final daysLeft = DateTime(dueDate.year, dueDate.month, dueDate.day)
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;

  if (daysLeft > 0) return 'Repot in $daysLeft day${daysLeft == 1 ? '' : 's'}';
  if (daysLeft == 0) return 'Repot today';
  final overdueBy = -daysLeft;
  return 'Repotting overdue by $overdueBy day${overdueBy == 1 ? '' : 's'}';
}

bool isRepottingOverdue(Plant plant) => repottingStatusText(plant).contains('overdue');

/// Days until repotting is due (negative if overdue), or null if no
/// repotting schedule is set.
int? daysUntilRepotDue(Plant plant) {
  if (plant.lastRepotted == null || plant.repottingIntervalDays == null) {
    return null;
  }
  final dueDate = DateTime.parse(plant.lastRepotted!)
      .add(Duration(days: plant.repottingIntervalDays!));
  final today = DateTime.now();
  return DateTime(dueDate.year, dueDate.month, dueDate.day)
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;
}
