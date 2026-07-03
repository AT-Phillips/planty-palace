import '../models/plant.dart';

/// Human-readable watering status for a plant, e.g. "Water today",
/// "Overdue by 2 days", or "No watering schedule set".
String wateringStatusText(Plant plant) {
  if (plant.lastWatered == null || plant.wateringIntervalDays == null) {
    return 'No watering schedule set';
  }
  final dueDate = DateTime.parse(plant.lastWatered!)
      .add(Duration(days: plant.wateringIntervalDays!));
  final today = DateTime.now();
  final daysLeft = DateTime(dueDate.year, dueDate.month, dueDate.day)
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;

  if (daysLeft > 0) return 'Water in $daysLeft day${daysLeft == 1 ? '' : 's'}';
  if (daysLeft == 0) return 'Water today';
  final overdueBy = -daysLeft;
  return 'Overdue by $overdueBy day${overdueBy == 1 ? '' : 's'}';
}

bool isOverdue(Plant plant) => wateringStatusText(plant).startsWith('Overdue');

/// Days until due (negative if overdue), or null if no schedule is set.
/// Used for sorting plants by urgency.
int? daysUntilDue(Plant plant) {
  if (plant.lastWatered == null || plant.wateringIntervalDays == null) {
    return null;
  }
  final dueDate = DateTime.parse(plant.lastWatered!)
      .add(Duration(days: plant.wateringIntervalDays!));
  final today = DateTime.now();
  return DateTime(dueDate.year, dueDate.month, dueDate.day)
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;
}
