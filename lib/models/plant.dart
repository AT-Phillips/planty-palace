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
  final String? lastFertilized;
  final int? fertilizingIntervalDays;
  final String? lastRepotted;
  final int? repottingIntervalDays;
  final String? lastPruned;
  final int? pruningIntervalDays;

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
    this.lastFertilized,
    this.fertilizingIntervalDays,
    this.lastRepotted,
    this.repottingIntervalDays,
    this.lastPruned,
    this.pruningIntervalDays,
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
      'lastFertilized': lastFertilized,
      'fertilizingIntervalDays': fertilizingIntervalDays,
      'lastRepotted': lastRepotted,
      'repottingIntervalDays': repottingIntervalDays,
      'lastPruned': lastPruned,
      'pruningIntervalDays': pruningIntervalDays,
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
      lastFertilized: map['lastFertilized'],
      fertilizingIntervalDays: map['fertilizingIntervalDays'],
      lastRepotted: map['lastRepotted'],
      repottingIntervalDays: map['repottingIntervalDays'],
      lastPruned: map['lastPruned'],
      pruningIntervalDays: map['pruningIntervalDays'],
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
    String? lastFertilized,
    int? fertilizingIntervalDays,
    String? lastRepotted,
    int? repottingIntervalDays,
    String? lastPruned,
    int? pruningIntervalDays,
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
      lastFertilized: lastFertilized ?? this.lastFertilized,
      fertilizingIntervalDays: fertilizingIntervalDays ?? this.fertilizingIntervalDays,
      lastRepotted: lastRepotted ?? this.lastRepotted,
      repottingIntervalDays: repottingIntervalDays ?? this.repottingIntervalDays,
      lastPruned: lastPruned ?? this.lastPruned,
      pruningIntervalDays: pruningIntervalDays ?? this.pruningIntervalDays,
    );
  }
}
