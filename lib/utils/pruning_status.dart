import '../models/plant.dart';

/// Human-readable pruning status for a plant - mirrors
/// lib/utils/fertilizing_status.dart's logic exactly, for pruning instead
/// of fertilizing.
String pruningStatusText(Plant plant) {
  if (plant.lastPruned == null || plant.pruningIntervalDays == null) {
    return 'No pruning schedule set';
  }
  final dueDate = DateTime.parse(
    plant.lastPruned!,
  ).add(Duration(days: plant.pruningIntervalDays!));
  final today = DateTime.now();
  final daysLeft =
      DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      ).difference(DateTime(today.year, today.month, today.day)).inDays;

  if (daysLeft > 0) return 'Prune in $daysLeft day${daysLeft == 1 ? '' : 's'}';
  if (daysLeft == 0) return 'Prune today';
  final overdueBy = -daysLeft;
  return 'Pruning overdue by $overdueBy day${overdueBy == 1 ? '' : 's'}';
}

bool isPruningOverdue(Plant plant) =>
    pruningStatusText(plant).contains('overdue');

/// Days until pruning is due (negative if overdue), or null if no pruning
/// schedule is set.
int? daysUntilPruneDue(Plant plant) {
  if (plant.lastPruned == null || plant.pruningIntervalDays == null) {
    return null;
  }
  final dueDate = DateTime.parse(
    plant.lastPruned!,
  ).add(Duration(days: plant.pruningIntervalDays!));
  final today = DateTime.now();
  return DateTime(
    dueDate.year,
    dueDate.month,
    dueDate.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
}
