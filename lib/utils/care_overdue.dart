import '../models/plant.dart';
import 'fertilizing_status.dart';
import 'pruning_status.dart';
import 'repotting_status.dart';
import 'watering_status.dart';

/// True if any of a plant's care schedules (watering, fertilizing,
/// repotting, pruning) is currently overdue.
bool hasAnyOverdueCare(Plant plant) {
  return isOverdue(plant) ||
      isFertilizingOverdue(plant) ||
      isRepottingOverdue(plant) ||
      isPruningOverdue(plant);
}

enum PlantSortOption { name, dateAdded, urgency }

/// The soonest due-in-days across watering/fertilizing/repotting/pruning
/// (whichever is more urgent), or null if none has a schedule set.
int? mostUrgentDueIn(Plant plant) {
  final candidates =
      [
        daysUntilDue(plant),
        daysUntilFertilizeDue(plant),
        daysUntilRepotDue(plant),
        daysUntilPruneDue(plant),
      ].whereType<int>().toList();
  if (candidates.isEmpty) return null;
  return candidates.reduce((a, b) => a < b ? a : b);
}

void sortPlants(List<Plant> plants, PlantSortOption option) {
  switch (option) {
    case PlantSortOption.name:
      plants.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      break;
    case PlantSortOption.dateAdded:
      plants.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      break;
    case PlantSortOption.urgency:
      plants.sort((a, b) {
        final aDue = mostUrgentDueIn(a);
        final bDue = mostUrgentDueIn(b);
        if (aDue == null && bDue == null) return 0;
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        return aDue.compareTo(bDue);
      });
      break;
  }
}
