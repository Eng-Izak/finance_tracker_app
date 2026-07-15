import '../../../../core/dependency_injection/service_locator.dart';
import '../../../../core/services/google_auth_service.dart';

class AuthRepository {
  String? _cachedEmail;
  String? _cachedUserId;
  String? _cachedDisplayName;

  // ─── Load Cached User from Storage ───────────────────────────
  Future<void> loadCachedUser() async {
    final googleAuth = sl<GoogleAuthService>();
    final email = await googleAuth.getUserEmail();
    if (email != null) {
      _cachedEmail = email;
      _cachedUserId = email;
      _cachedDisplayName = email.split('@').first;
    } else {
      _cachedEmail = null;
      _cachedUserId = null;
      _cachedDisplayName = null;
    }
  }

  // ─── Google Sign In ──────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      final googleAuth = sl<GoogleAuthService>();
      final success = await googleAuth.signIn();
      if (success) {
        await loadCachedUser();
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────
  Future<void> signOut() async {
    final googleAuth = sl<GoogleAuthService>();
    await googleAuth.signOut();
    _cachedEmail = null;
    _cachedUserId = null;
    _cachedDisplayName = null;
  }

  // ─── Getters ─────────────────────────────────────────────────
  bool get isLoggedIn => _cachedEmail != null;
  String get userId => _cachedUserId ?? 'local_user';
  String get userDisplayName => _cachedDisplayName ?? 'Local User';
  String get userEmail => _cachedEmail ?? 'local@example.com';
  String? get userPhotoUrl => null;
}
