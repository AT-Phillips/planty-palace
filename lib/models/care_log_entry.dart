/// One entry in a plant's care history - either a watering or a
/// fertilizing event.
class CareLogEntry {
  final String type; // 'watering' | 'fertilizing'
  final String timestamp;

  CareLogEntry({required this.type, required this.timestamp});
}
