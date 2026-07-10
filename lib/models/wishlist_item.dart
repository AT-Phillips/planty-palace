/// A species the user has saved to their wishlist - a plant they want but
/// don't own yet. Populated from the Species Detail screen's heart action and
/// surfaced in the Spaces hub's "Wishlist" section.
class WishlistItem {
  /// Firestore document id. Equal to [keyFor] the scientific name, so saving
  /// the same species twice overwrites rather than duplicating, and
  /// membership checks are a single doc read.
  final String id;
  final String scientificName;
  final String? commonName;
  final String? imageUrl;

  /// ISO-8601 timestamp used only to order the wishlist newest-first.
  final String savedAt;

  WishlistItem({
    required this.id,
    required this.scientificName,
    this.commonName,
    this.imageUrl,
    required this.savedAt,
  });

  /// A stable, Firestore-safe document id derived from the scientific name
  /// (lowercased, non-alphanumerics collapsed to underscores).
  static String keyFor(String scientificName) => scientificName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  Map<String, dynamic> toMap() => {
    'scientificName': scientificName,
    'commonName': commonName,
    'imageUrl': imageUrl,
    'savedAt': savedAt,
  };

  factory WishlistItem.fromMap(Map<String, dynamic> map, {required String id}) {
    return WishlistItem(
      id: id,
      scientificName: map['scientificName'] as String? ?? '',
      commonName: map['commonName'] as String?,
      imageUrl: map['imageUrl'] as String?,
      savedAt: map['savedAt'] as String? ?? '',
    );
  }
}
