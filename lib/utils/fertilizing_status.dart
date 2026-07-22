import '../models/plant.dart';

/// Human-readable fertilizing status for a plant - mirrors
/// lib/utils/watering_status.dart's logic exactly, for fertilizing instead
/// of watering.
String fertilizingStatusText(Plant plant) {
  if (plant.lastFertilized == null || plant.fertilizingIntervalDays == null) {
    return 'No fertilizing schedule set';
  }
  final dueDate = DateTime.parse(
    plant.lastFertilized!,
  ).add(Duration(days: plant.fertilizingIntervalDays!));
  final today = DateTime.now();
  final daysLeft =
      DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      ).difference(DateTime(today.year, today.month, today.day)).inDays;

  if (daysLeft > 0) {
    return 'Fertilize in $daysLeft day${daysLeft == 1 ? '' : 's'}';
  }
  if (daysLeft == 0) return 'Fertilize today';
  final overdueBy = -daysLeft;
  return 'Fertilizing overdue by $overdueBy day${overdueBy == 1 ? '' : 's'}';
}

bool isFertilizingOverdue(Plant plant) =>
    fertilizingStatusText(plant).contains('overdue');

/// Days until fertilizing is due (negative if overdue), or null if no
/// fertilizing schedule is set.
int? daysUntilFertilizeDue(Plant plant) {
  if (plant.lastFertilized == null || plant.fertilizingIntervalDays == null) {
    return null;
  }
  final dueDate = DateTime.parse(
    plant.lastFertilized!,
  ).add(Duration(days: plant.fertilizingIntervalDays!));
  final today = DateTime.now();
  return DateTime(
    dueDate.year,
    dueDate.month,
    dueDate.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
}
