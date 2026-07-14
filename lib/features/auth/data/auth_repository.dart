import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  FirebaseAuth? get _auth =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Current User ─────────────────────────────────────────────
  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();
  bool get isLoggedIn => _auth?.currentUser != null;

  // ─── Google Sign In ──────────────────────────────────────────
  Future<User?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not configured. Google Sign-In is disabled.');
    }
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────
  Future<void> signOut() async {
    final auth = _auth;
    final futures = <Future<dynamic>>[
      _googleSignIn.signOut(),
    ];
    if (auth != null) {
      futures.add(auth.signOut());
    }
    await Future.wait(futures);
  }

  // ─── User Info ───────────────────────────────────────────────
  String get userId => _auth?.currentUser?.uid ?? 'local_user';
  String get userDisplayName =>
      _auth?.currentUser?.displayName ?? 'Local User';
  String get userEmail => _auth?.currentUser?.email ?? 'local@example.com';
  String? get userPhotoUrl => _auth?.currentUser?.photoURL;
}
