class Plant {
  final String? id;
  final String name;
  final String species;
  final String imagePath;
  final String? photoUrl;
  final String careInstructions;
  final String? gardenId;
  final String? lastWatered;
  final int? wateringIntervalDays;

  Plant({
    this.id,
    required this.name,
    required this.species,
    required this.imagePath,
    this.photoUrl,
    required this.careInstructions,
    this.gardenId,
    this.lastWatered,
    this.wateringIntervalDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'species': species,
      'imagePath': imagePath,
      'photoUrl': photoUrl,
      'careInstructions': careInstructions,
      'gardenId': gardenId,
      'lastWatered': lastWatered,
      'wateringIntervalDays': wateringIntervalDays,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map, {String? id}) {
    return Plant(
      id: id,
      name: map['name'],
      species: map['species'],
      imagePath: map['imagePath'] ?? '',
      photoUrl: map['photoUrl'],
      careInstructions: map['careInstructions'] ?? '',
      gardenId: map['gardenId'],
      lastWatered: map['lastWatered'],
      wateringIntervalDays: map['wateringIntervalDays'],
    );
  }

  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? imagePath,
    String? photoUrl,
    String? careInstructions,
    String? gardenId,
    String? lastWatered,
    int? wateringIntervalDays,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      imagePath: imagePath ?? this.imagePath,
      photoUrl: photoUrl ?? this.photoUrl,
      careInstructions: careInstructions ?? this.careInstructions,
      gardenId: gardenId ?? this.gardenId,
      lastWatered: lastWatered ?? this.lastWatered,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
    );
  }
}
