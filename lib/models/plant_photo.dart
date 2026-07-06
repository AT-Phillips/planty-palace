class PlantPhoto {
  final String id;
  final String photoUrl;
  final String takenAt;

  PlantPhoto({required this.id, required this.photoUrl, required this.takenAt});

  Map<String, dynamic> toMap() => {'photoUrl': photoUrl, 'takenAt': takenAt};

  factory PlantPhoto.fromMap(Map<String, dynamic> map, {required String id}) {
    return PlantPhoto(
      id: id,
      photoUrl: map['photoUrl'] as String,
      takenAt: map['takenAt'] as String,
    );
  }
}
