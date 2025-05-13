class Plant {
  final int? id;
  final String name;
  final String species;
  final String imagePath;
  final String careInstructions;

  Plant({
    this.id,
    required this.name,
    required this.species,
    required this.imagePath,
    required this.careInstructions,
  });

  // Convert Plant to Map for DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'imagePath': imagePath,
      'careInstructions': careInstructions,
    };
  }

  // Create Plant from Map
  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      imagePath: map['imagePath'],
      careInstructions: map['careInstructions'],
    );
  }
}
