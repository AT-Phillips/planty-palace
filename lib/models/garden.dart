class Garden {
  final int? id;
  final String name;

  Garden({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Garden.fromMap(Map<String, dynamic> map) {
    return Garden(
      id: map['id'],
      name: map['name'],
    );
  }
}
