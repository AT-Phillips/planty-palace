class Propagation {
  final String? id;
  final String name;
  final String method;
  final String startedAt;
  final String notes;
  final String? parentPlantId;
  final String? parentSpeciesSnapshot;
  final String? photoUrl;
  final String imagePath;
  final bool isPromoted;
  final String? promotedPlantId;

  Propagation({
    this.id,
    required this.name,
    required this.method,
    required this.startedAt,
    this.notes = '',
    this.parentPlantId,
    this.parentSpeciesSnapshot,
    this.photoUrl,
    this.imagePath = '',
    this.isPromoted = false,
    this.promotedPlantId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'method': method,
      'startedAt': startedAt,
      'notes': notes,
      'parentPlantId': parentPlantId,
      'parentSpeciesSnapshot': parentSpeciesSnapshot,
      'photoUrl': photoUrl,
      'imagePath': imagePath,
      'isPromoted': isPromoted,
      'promotedPlantId': promotedPlantId,
    };
  }

  factory Propagation.fromMap(Map<String, dynamic> map, {String? id}) {
    return Propagation(
      id: id,
      name: map['name'] ?? '',
      method: map['method'] ?? 'Other',
      startedAt: map['startedAt'] ?? DateTime.now().toIso8601String(),
      notes: map['notes'] ?? '',
      parentPlantId: map['parentPlantId'],
      parentSpeciesSnapshot: map['parentSpeciesSnapshot'],
      photoUrl: map['photoUrl'],
      imagePath: map['imagePath'] ?? '',
      isPromoted: map['isPromoted'] ?? false,
      promotedPlantId: map['promotedPlantId'],
    );
  }

  Propagation copyWith({
    String? id,
    String? name,
    String? method,
    String? startedAt,
    String? notes,
    String? parentPlantId,
    String? parentSpeciesSnapshot,
    String? photoUrl,
    String? imagePath,
    bool? isPromoted,
    String? promotedPlantId,
  }) {
    return Propagation(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      startedAt: startedAt ?? this.startedAt,
      notes: notes ?? this.notes,
      parentPlantId: parentPlantId ?? this.parentPlantId,
      parentSpeciesSnapshot:
          parentSpeciesSnapshot ?? this.parentSpeciesSnapshot,
      photoUrl: photoUrl ?? this.photoUrl,
      imagePath: imagePath ?? this.imagePath,
      isPromoted: isPromoted ?? this.isPromoted,
      promotedPlantId: promotedPlantId ?? this.promotedPlantId,
    );
  }
}
