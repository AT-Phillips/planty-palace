/// A free-form timestamped observation about a plant - distinct from the
/// growth-photo timeline and the watering/fertilizing/repotting/pruning
/// care log.
class JournalEntry {
  final String id;
  final String text;
  final String createdAt;

  JournalEntry({required this.id, required this.text, required this.createdAt});

  Map<String, dynamic> toMap() => {'text': text, 'createdAt': createdAt};

  factory JournalEntry.fromMap(Map<String, dynamic> map, {required String id}) {
    return JournalEntry(
      id: id,
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
