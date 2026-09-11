import '../models/plant.dart';
import 'care_kind.dart';
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

/// Which care kind is the most urgent for a plant right now, or null if it
/// has no schedules at all.
///
/// The hub's to-do row needs this, not just the number of days: a plant can
/// be listed because its *feeding* is overdue while its watering is fine, and
/// an action button that always watered would neither clear the row nor match
/// the label above it.
CareKind? mostUrgentKind(Plant plant) {
  CareKind? best;
  int? bestDue;
  for (final kind in CareKind.values) {
    final due = kind.dueInDays(plant);
    if (due == null) continue;
    if (bestDue == null || due < bestDue) {
      bestDue = due;
      best = kind;
    }
  }
  return best;
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
