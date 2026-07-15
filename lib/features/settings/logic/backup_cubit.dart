import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/services/google_drive_backup_service.dart';
import 'backup_state.dart';

/// Manages Google Drive backup operations with robust exception interception.
///
/// All public methods wrap their operations in structured try-catch blocks
/// that convert raw platform/network exceptions into localized
/// [BackupFailure] domain states for clean UI consumption.
class BackupCubit extends Cubit<BackupState> {
  final GoogleDriveBackupService _driveService;
  final GoogleAuthService _authService;

  BackupCubit({
    required GoogleDriveBackupService driveService,
    required GoogleAuthService authService,
  })  : _driveService = driveService,
        _authService = authService,
        super(const BackupInitial());

  // ─── Sign In With Google ──────────────────────────────────────
  Future<void> signInWithGoogle() async {
    emit(const BackupLoading());
    try {
      final success = await _authService.signIn();
      if (success) {
        final email = await _authService.getUserEmail();
        emit(BackupAuthenticationSuccess(userEmail: email ?? 'Google User'));
      } else {
        emit(const BackupFailure(
          errorMessage: 'تم إلغاء تسجيل الدخول.',
        ));
      }
    } on StateError catch (e) {
      // Credential configuration error (e.g. missing client_secret)
      debugPrint('BackupCubit: Credential config error: $e');
      emit(const BackupFailure(
        errorMessage: 'خطأ في إعداد بيانات المصادقة. '
            'تأكد من ضبط GOOGLE_CLIENT_SECRET_WINDOWS عبر --dart-define.',
      ));
    } on UnsupportedError catch (e) {
      debugPrint('BackupCubit: Unsupported platform: $e');
      emit(const BackupFailure(
        errorMessage: 'المنصة الحالية لا تدعم المصادقة بحساب Google.',
      ));
    } on SocketException catch (e) {
      debugPrint('BackupCubit: Network error during sign-in: $e');
      emit(const BackupFailure(
        errorMessage: 'فشل الاتصال بالشبكة. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.',
      ));
    } on TimeoutException catch (e) {
      debugPrint('BackupCubit: Sign-in timeout: $e');
      emit(const BackupFailure(
        errorMessage: 'انتهت مهلة تسجيل الدخول. حاول مرة أخرى.',
      ));
    } on HttpException catch (e) {
      debugPrint('BackupCubit: HTTP error during sign-in: $e');
      emit(const BackupFailure(
        errorMessage: 'خطأ في الاتصال بخوادم Google. حاول مرة أخرى لاحقاً.',
      ));
    } catch (e) {
      // Catch-all for unexpected errors
      debugPrint('BackupCubit: Unexpected sign-in error: $e');
      emit(BackupFailure(
        errorMessage: 'خطأ غير متوقع أثناء تسجيل الدخول: '
            '${_sanitizeErrorMessage(e)}',
      ));
    }
  }

  // ─── Silent Sign In ───────────────────────────────────────────
  Future<void> silentSignIn() async {
    emit(const BackupLoading());
    try {
      final success = await _authService.silentSignIn();
      if (success) {
        final email = await _authService.getUserEmail();
        emit(BackupAuthenticationSuccess(userEmail: email ?? 'Google User'));
      } else {
        emit(const BackupInitial());
      }
    } catch (e) {
      // Silent sign-in failures are non-critical — reset to initial state
      debugPrint('BackupCubit: Silent sign-in failed: $e');
      emit(const BackupInitial());
    }
  }

  // ─── Upload Backup to Cloud ───────────────────────────────────
  Future<void> uploadBackup(String customName) async {
    final email = await _authService.getUserEmail();
    if (email == null) {
      emit(const BackupFailure(
        errorMessage: 'يرجى تسجيل الدخول أولاً للنسخ الاحتياطي.',
      ));
      return;
    }

    emit(const BackupLoading());
    try {
      final lastSynced = await _driveService.uploadBackup(customName);
      emit(BackupSyncSuccess(lastSyncedAt: lastSynced, userEmail: email));
    } on SocketException catch (_) {
      emit(const BackupFailure(
        errorMessage: 'فشل الاتصال بالشبكة أثناء رفع النسخة الاحتياطية. '
            'تحقق من اتصالك بالإنترنت.',
      ));
    } on TimeoutException catch (_) {
      emit(const BackupFailure(
        errorMessage: 'انتهت مهلة رفع النسخة الاحتياطية. حاول مرة أخرى.',
      ));
    } catch (e) {
      debugPrint('BackupCubit: Upload error: $e');
      emit(BackupFailure(
        errorMessage: 'فشل رفع النسخة الاحتياطية: '
            '${_sanitizeErrorMessage(e)}',
      ));
    }
  }

  // ─── Download & Restore Backup From Cloud ─────────────────────
  Future<void> downloadBackup(String fileId) async {
    final email = await _authService.getUserEmail();
    if (email == null) {
      emit(const BackupFailure(
        errorMessage: 'يرجى تسجيل الدخول أولاً للاستعادة.',
      ));
      return;
    }

    emit(const BackupLoading());
    try {
      await _driveService.downloadBackup(fileId);
      emit(BackupSyncSuccess(lastSyncedAt: DateTime.now(), userEmail: email));
    } on SocketException catch (_) {
      emit(const BackupFailure(
        errorMessage: 'فشل الاتصال بالشبكة أثناء استعادة النسخة الاحتياطية. '
            'تحقق من اتصالك بالإنترنت.',
      ));
    } on TimeoutException catch (_) {
      emit(const BackupFailure(
        errorMessage: 'انتهت مهلة استعادة النسخة الاحتياطية. حاول مرة أخرى.',
      ));
    } catch (e) {
      debugPrint('BackupCubit: Download error: $e');
      emit(BackupFailure(
        errorMessage: 'فشل استعادة النسخة الاحتياطية: '
            '${_sanitizeErrorMessage(e)}',
      ));
    }
  }

  // ─── Fetch Available Backups from Cloud ────────────────────────
  Future<void> loadBackupsList() async {
    final email = await _authService.getUserEmail();
    if (email == null) {
      emit(const BackupFailure(
        errorMessage: 'يرجى تسجيل الدخول أولاً لعرض النسخ الاحتياطية.',
      ));
      return;
    }

    emit(const BackupLoading());
    try {
      final backups = await _driveService.listBackups();
      emit(BackupListLoaded(backups: backups, userEmail: email));
    } on SocketException catch (_) {
      emit(const BackupFailure(
        errorMessage: 'فشل الاتصال بالشبكة أثناء جلب النسخ الاحتياطية. '
            'تحقق من اتصالك بالإنترنت.',
      ));
    } on TimeoutException catch (_) {
      emit(const BackupFailure(
        errorMessage: 'انتهت مهلة جلب قائمة النسخ الاحتياطية. حاول مرة أخرى.',
      ));
    } catch (e) {
      debugPrint('BackupCubit: listBackups error: $e');
      emit(BackupFailure(
        errorMessage: 'فشل جلب قائمة النسخ الاحتياطية: '
            '${_sanitizeErrorMessage(e)}',
      ));
    }
  }

  // ─── Reset State back to Main Authenticated Screen ─────────────
  void resetToAuthenticated() async {
    final email = await _authService.getUserEmail();
    if (email != null) {
      emit(BackupAuthenticationSuccess(userEmail: email));
    } else {
      emit(const BackupInitial());
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    emit(const BackupLoading());
    try {
      await _authService.signOut();
      emit(const BackupInitial());
    } catch (e) {
      debugPrint('BackupCubit: Sign-out error: $e');
      emit(BackupFailure(
        errorMessage: 'خطأ أثناء تسجيل الخروج: '
            '${_sanitizeErrorMessage(e)}',
      ));
    }
  }

  // ─── Error Sanitization ───────────────────────────────────────
  /// Converts raw exception objects into clean, user-facing messages.
  /// Strips internal stack traces, class names, and sensitive data
  /// that should not be exposed in the UI.
  String _sanitizeErrorMessage(Object error) {
    final raw = error.toString();

    // Strip 'Exception: ' prefix if present
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }

    // Strip 'PlatformException(...)' wrapper
    if (raw.startsWith('PlatformException(')) {
      final inner = raw.substring(
        'PlatformException('.length,
        raw.length - 1,
      );
      final parts = inner.split(', ');
      // Return the message part (second element) if available
      if (parts.length >= 2 && parts[1].isNotEmpty && parts[1] != 'null') {
        return parts[1];
      }
      return parts.first;
    }

    // Truncate excessively long error messages
    if (raw.length > 200) {
      return '${raw.substring(0, 200)}…';
    }

    return raw;
  }
}
