class Garden {
  final String? id;
  final String name;

  Garden({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  factory Garden.fromMap(Map<String, dynamic> map, {String? id}) {
    return Garden(
      id: id,
      name: map['name'],
    );
  }
}
