class Plant {
  final String? id;
  final String name;
  final String species;
  final String imagePath;
  final String? photoUrl;
  final String careInstructions;
  final String? gardenId;
  final String? createdAt;
  final String? lastWatered;
  final int? wateringIntervalDays;
  final String? lastFertilized;
  final int? fertilizingIntervalDays;
  final String? lastRepotted;
  final int? repottingIntervalDays;
  final String? lastPruned;
  final int? pruningIntervalDays;

  // Reference facts about the species, sourced from Perenual at add-time
  // (see PerenualSpeciesDetail) and stored on the plant itself so they don't
  // need a repeat API call and survive even if that species later becomes
  // unavailable. Nullable throughout - never fabricated, only ever what
  // Perenual actually returned for this species.
  final String? speciesDescription;
  final String? speciesOrigin;
  final String? speciesFamily;
  final String? speciesImageUrl;
  final bool? poisonousToHumans;
  final bool? poisonousToPets;

  Plant({
    this.id,
    required this.name,
    required this.species,
    required this.imagePath,
    this.photoUrl,
    required this.careInstructions,
    this.gardenId,
    this.createdAt,
    this.lastWatered,
    this.wateringIntervalDays,
    this.lastFertilized,
    this.fertilizingIntervalDays,
    this.lastRepotted,
    this.repottingIntervalDays,
    this.lastPruned,
    this.pruningIntervalDays,
    this.speciesDescription,
    this.speciesOrigin,
    this.speciesFamily,
    this.speciesImageUrl,
    this.poisonousToHumans,
    this.poisonousToPets,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'species': species,
      'imagePath': imagePath,
      'photoUrl': photoUrl,
      'careInstructions': careInstructions,
      'gardenId': gardenId,
      'createdAt': createdAt,
      'lastWatered': lastWatered,
      'wateringIntervalDays': wateringIntervalDays,
      'lastFertilized': lastFertilized,
      'fertilizingIntervalDays': fertilizingIntervalDays,
      'lastRepotted': lastRepotted,
      'repottingIntervalDays': repottingIntervalDays,
      'lastPruned': lastPruned,
      'pruningIntervalDays': pruningIntervalDays,
      'speciesDescription': speciesDescription,
      'speciesOrigin': speciesOrigin,
      'speciesFamily': speciesFamily,
      'speciesImageUrl': speciesImageUrl,
      'poisonousToHumans': poisonousToHumans,
      'poisonousToPets': poisonousToPets,
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
      // Older plants created before this field existed don't have it - fall
      // back to lastWatered (set to "now" at creation time historically) so
      // sort-by-date-added still puts them in a sensible position.
      createdAt: map['createdAt'] ?? map['lastWatered'],
      lastWatered: map['lastWatered'],
      wateringIntervalDays: map['wateringIntervalDays'],
      lastFertilized: map['lastFertilized'],
      fertilizingIntervalDays: map['fertilizingIntervalDays'],
      lastRepotted: map['lastRepotted'],
      repottingIntervalDays: map['repottingIntervalDays'],
      lastPruned: map['lastPruned'],
      pruningIntervalDays: map['pruningIntervalDays'],
      speciesDescription: map['speciesDescription'],
      speciesOrigin: map['speciesOrigin'],
      speciesFamily: map['speciesFamily'],
      speciesImageUrl: map['speciesImageUrl'],
      poisonousToHumans: map['poisonousToHumans'],
      poisonousToPets: map['poisonousToPets'],
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
    String? createdAt,
    String? lastWatered,
    int? wateringIntervalDays,
    String? lastFertilized,
    int? fertilizingIntervalDays,
    String? lastRepotted,
    int? repottingIntervalDays,
    String? lastPruned,
    int? pruningIntervalDays,
    String? speciesDescription,
    String? speciesOrigin,
    String? speciesFamily,
    String? speciesImageUrl,
    bool? poisonousToHumans,
    bool? poisonousToPets,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      imagePath: imagePath ?? this.imagePath,
      photoUrl: photoUrl ?? this.photoUrl,
      careInstructions: careInstructions ?? this.careInstructions,
      gardenId: gardenId ?? this.gardenId,
      createdAt: createdAt ?? this.createdAt,
      lastWatered: lastWatered ?? this.lastWatered,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      lastFertilized: lastFertilized ?? this.lastFertilized,
      fertilizingIntervalDays:
          fertilizingIntervalDays ?? this.fertilizingIntervalDays,
      lastRepotted: lastRepotted ?? this.lastRepotted,
      repottingIntervalDays:
          repottingIntervalDays ?? this.repottingIntervalDays,
      lastPruned: lastPruned ?? this.lastPruned,
      pruningIntervalDays: pruningIntervalDays ?? this.pruningIntervalDays,
      speciesDescription: speciesDescription ?? this.speciesDescription,
      speciesOrigin: speciesOrigin ?? this.speciesOrigin,
      speciesFamily: speciesFamily ?? this.speciesFamily,
      speciesImageUrl: speciesImageUrl ?? this.speciesImageUrl,
      poisonousToHumans: poisonousToHumans ?? this.poisonousToHumans,
      poisonousToPets: poisonousToPets ?? this.poisonousToPets,
    );
  }
}
