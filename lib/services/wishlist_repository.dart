import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wishlist_item.dart';
import 'auth_service.dart';

/// Firestore-backed store for the user's wishlist (species they want but
/// don't own yet). Lives under `users/{uid}/wishlist`, the same user-scoped
/// tree as plants and propagations, so it needs no new security rules.
/// Mirrors PropagationRepository's shape (this codebase favours small
/// parallel repositories over a shared generic base).
class WishlistRepository {
  String get _uid {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'No signed-in user - ensureSignedIn() must run before any data access.',
      );
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _wishlist => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('wishlist');

  Future<List<WishlistItem>> getWishlist() async {
    final snapshot = await _wishlist.orderBy('savedAt', descending: true).get();
    return snapshot.docs
        .map((d) => WishlistItem.fromMap(d.data(), id: d.id))
        .toList();
  }

  Future<int> getWishlistCount() async {
    final aggregate = await _wishlist.count().get();
    return aggregate.count ?? 0;
  }

  Future<bool> isSaved(String scientificName) async {
    final doc = await _wishlist.doc(WishlistItem.keyFor(scientificName)).get();
    return doc.exists;
  }

  Future<void> add({
    required String scientificName,
    String? commonName,
    String? imageUrl,
  }) async {
    final key = WishlistItem.keyFor(scientificName);
    await _wishlist.doc(key).set({
      'scientificName': scientificName,
      'commonName': commonName,
      'imageUrl': imageUrl,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> remove(String scientificName) async {
    await _wishlist.doc(WishlistItem.keyFor(scientificName)).delete();
  }

  /// Flips saved state for a species and returns the new value (true = now
  /// saved).
  Future<bool> toggle({
    required String scientificName,
    String? commonName,
    String? imageUrl,
  }) async {
    if (await isSaved(scientificName)) {
      await remove(scientificName);
      return false;
    }
    await add(
      scientificName: scientificName,
      commonName: commonName,
      imageUrl: imageUrl,
    );
    return true;
  }
}
