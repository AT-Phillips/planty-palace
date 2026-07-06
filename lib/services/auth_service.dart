import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'photo_storage_service.dart';
import 'plant_repository.dart';
import 'propagation_repository.dart';

/// Wraps Firebase Auth with an anonymous-first model: every install signs in
/// anonymously automatically (no signup friction), and can later "upgrade"
/// that same account to an email/password so its data is recoverable on
/// another device. Not available on platforms Firebase isn't configured for
/// (Windows/Linux desktop, used for local dev) — callers should check
/// [isAvailable] before relying on auth state.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool get isAvailable => Firebase.apps.isNotEmpty;

  User? get currentUser => isAvailable ? FirebaseAuth.instance.currentUser : null;

  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  String? get email => currentUser?.email;

  String? get displayName => currentUser?.displayName;

  String? get photoUrl => currentUser?.photoURL;

  /// Signs in anonymously if no user is currently signed in. Call once on
  /// app start. No-ops on platforms where Firebase isn't configured.
  Future<void> ensureSignedIn() async {
    if (!isAvailable) return;
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  /// Links the current anonymous account to an email/password credential,
  /// preserving the same user ID (and therefore, once data sync is wired up,
  /// the same data) rather than creating a separate account.
  Future<void> upgradeToEmailAccount(String email, String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No signed-in user to upgrade.');
    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.linkWithCredential(credential);
  }

  /// Signs into an existing email/password account, e.g. on a new device
  /// where a previous "Save my account" upgrade was done elsewhere.
  Future<void> signInExisting(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await ensureSignedIn();
  }

  /// Updates the current user's display name and/or photo. [photoUrl] may
  /// be a real Storage download URL, or a `preset:N` sentinel identifying a
  /// built-in icon avatar - Firebase Auth treats it as an opaque string
  /// either way, so no separate profile datastore is needed.
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No signed-in user.');
    if (displayName != null) await user.updateDisplayName(displayName);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No email/password account to update.');
    }
    final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Permanently deletes the current user's Gardens, plants, propagations,
  /// care history, photos, and the auth account itself. [currentPassword]
  /// is required to reauthenticate email/password accounts (Firebase
  /// rejects deletion on a session that isn't "recently" signed in).
  Future<void> deleteAccount({String? currentPassword}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No signed-in user.');

    if (!user.isAnonymous && user.email != null && currentPassword != null) {
      final credential =
          EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
    }

    final plantRepository = PlantRepository();
    for (final plant in await plantRepository.getPlants()) {
      await plantRepository.deletePlant(plant.id!);
    }
    final propagationRepository = PropagationRepository();
    for (final propagation in await propagationRepository.getPropagations()) {
      await propagationRepository.deletePropagation(propagation.id!);
    }
    await plantRepository.deleteAllGardens();
    await PhotoStorageService().deleteProfilePhoto(user.uid);

    await user.delete();
  }
}
