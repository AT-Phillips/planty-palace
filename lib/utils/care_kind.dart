import 'package:flutter/material.dart';

import '../models/plant.dart';
import 'fertilizing_status.dart';
import 'pruning_status.dart';
import 'repotting_status.dart';
import 'watering_status.dart';

/// The four care schedules a plant can have. Centralizes the
/// water/fertilize/repot/prune symmetry that was previously copy-pasted
/// across the detail screen, care screen, and status utilities - so a widget
/// can iterate `CareKind.values` and ask each kind for its label, icon,
/// interval, days-until-due, and status text uniformly.
enum CareKind { water, feed, repot, prune }

extension CareKindInfo on CareKind {
  /// Imperative label for the action button / tile ("Water", "Feed", ...).
  String get label => switch (this) {
    CareKind.water => 'Water',
    CareKind.feed => 'Feed',
    CareKind.repot => 'Repot',
    CareKind.prune => 'Prune',
  };

  /// Past-tense confirmation ("Watered", "Fertilized", ...).
  String get pastTense => switch (this) {
    CareKind.water => 'Watered',
    CareKind.feed => 'Fertilized',
    CareKind.repot => 'Repotted',
    CareKind.prune => 'Pruned',
  };

  IconData get icon => switch (this) {
    CareKind.water => Icons.water_drop_outlined,
    CareKind.feed => Icons.eco_outlined,
    CareKind.repot => Icons.yard_outlined,
    CareKind.prune => Icons.content_cut,
  };

  /// The care-log `type` string this kind persists as (kept in sync with the
  /// existing repository/care-history values).
  String get logType => switch (this) {
    CareKind.water => 'watering',
    CareKind.feed => 'fertilizing',
    CareKind.repot => 'repotting',
    CareKind.prune => 'pruning',
  };

  /// The plant's configured interval for this kind, or null if unscheduled.
  int? intervalDays(Plant plant) => switch (this) {
    CareKind.water => plant.wateringIntervalDays,
    CareKind.feed => plant.fertilizingIntervalDays,
    CareKind.repot => plant.repottingIntervalDays,
    CareKind.prune => plant.pruningIntervalDays,
  };

  /// Days until this kind is next due (negative if overdue), or null if
  /// unscheduled. Delegates to the existing top-level status utilities.
  int? dueInDays(Plant plant) => switch (this) {
    CareKind.water => daysUntilDue(plant),
    CareKind.feed => daysUntilFertilizeDue(plant),
    CareKind.repot => daysUntilRepotDue(plant),
    CareKind.prune => daysUntilPruneDue(plant),
  };

  bool overdue(Plant plant) => switch (this) {
    CareKind.water => isOverdue(plant),
    CareKind.feed => isFertilizingOverdue(plant),
    CareKind.repot => isRepottingOverdue(plant),
    CareKind.prune => isPruningOverdue(plant),
  };

  /// Full human-readable status ("Water in 3 days", "Overdue by 2 days", ...).
  String statusText(Plant plant) => switch (this) {
    CareKind.water => wateringStatusText(plant),
    CareKind.feed => fertilizingStatusText(plant),
    CareKind.repot => repottingStatusText(plant),
    CareKind.prune => pruningStatusText(plant),
  };

  /// Whether this plant has this kind scheduled at all.
  bool isScheduled(Plant plant) => intervalDays(plant) != null;
}
