import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
}
