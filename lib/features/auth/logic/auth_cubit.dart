import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/local_db_service.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial());

  // ─── Check Auth Status ───────────────────────────────────────
  Future<void> checkAuthStatus() async {
    await _authRepository.loadCachedUser();
    final isGoogleLoggedIn = _authRepository.isLoggedIn;
    final isOffline =
        LocalDbService.getSetting<bool>("is_offline_user") ?? false;

    if (isGoogleLoggedIn) {
      emit(AuthAuthenticated(
        userId: _authRepository.userId,
        displayName: _authRepository.userDisplayName,
        email: _authRepository.userEmail,
      ));
    } else if (isOffline) {
      emit(const AuthAuthenticated(
        userId: 'local_user',
        displayName: 'Local User',
        email: 'local@example.com',
      ));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  // ─── Google Sign In ──────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final success = await _authRepository.signInWithGoogle();
      if (success) {
        await LocalDbService.setSetting<bool>("is_offline_user", false);
        emit(AuthAuthenticated(
          userId: _authRepository.userId,
          displayName: _authRepository.userDisplayName,
          email: _authRepository.userEmail,
        ));
      } else {
        // User cancelled
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ─── Sign In Offline ─────────────────────────────────────────
  Future<void> signInOffline() async {
    emit(const AuthLoading());
    try {
      await LocalDbService.setSetting<bool>("is_offline_user", true);
      emit(const AuthAuthenticated(
        userId: 'local_user',
        displayName: 'Local User',
        email: 'local@example.com',
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      await LocalDbService.setSetting<bool>("is_offline_user", false);
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ─── Getters ─────────────────────────────────────────────────
  String get userId => _authRepository.userId;
  String get userDisplayName => _authRepository.userDisplayName;
  String get userEmail => _authRepository.userEmail;
  String? get userPhotoUrl => _authRepository.userPhotoUrl;
  bool get isLoggedIn =>
      _authRepository.isLoggedIn ||
      (LocalDbService.getSetting<bool>("is_offline_user") ?? false);
}
