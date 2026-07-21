import 'dart:io';

/// Platform-aware credential resolver for Google OAuth2.
///
/// Architecture:
///   Windows → Uses Web Application Client (clientId + clientSecret)
///             via openid_client loopback flow.
///   Android → Uses Native Android Client (clientId only)
///             via google_sign_in (Google Play Services + SHA-1).
///
/// Credentials MUST be injected at compile time via --dart-define:
///   flutter run --dart-define=GOOGLE_CLIENT_ID_WINDOWS=xxx \
///               --dart-define=GOOGLE_CLIENT_SECRET_WINDOWS=xxx \
///               --dart-define=GOOGLE_CLIENT_ID_ANDROID=xxx
class GoogleAuthConfig {
  GoogleAuthConfig._();

  // ─── Compile-time environment keys ────────────────────────────
  static const String _winClientIdKey = 'GOOGLE_CLIENT_ID_WINDOWS';
  static const String _winClientSecretKey = 'GOOGLE_CLIENT_SECRET_WINDOWS';
  static const String _androidClientIdKey = 'GOOGLE_CLIENT_ID_ANDROID';

  // ═══════════════════════════════════════════════════════════════
  // ─── Windows: Web Application Credentials ─────────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Windows OAuth2 Client ID (Web Application type in Google Cloud Console).
  static const String windowsClientId = String.fromEnvironment(_winClientIdKey);

  /// Windows OAuth2 Client Secret (Web Application type in Google Cloud Console).
  static const String windowsClientSecret =
      String.fromEnvironment(_winClientSecretKey);

  // ═══════════════════════════════════════════════════════════════
  // ─── Android: Native Application Credentials ──────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Android OAuth2 Client ID (Android type in Google Cloud Console).
  static const String androidClientId =
      String.fromEnvironment(_androidClientIdKey);

  // ═══════════════════════════════════════════════════════════════
  // ─── Platform-Resolved Getters ────────────────────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Resolves the correct Client ID based on the active platform.
  static String get clientId {
    if (Platform.isWindows) {
      if (windowsClientId.isEmpty) {
        throw StateError(
          'GOOGLE_CLIENT_ID_WINDOWS is missing. '
          'Inject via: --dart-define=GOOGLE_CLIENT_ID_WINDOWS=YOUR_CLIENT_ID',
        );
      }
      return windowsClientId;
    }
    if (Platform.isAndroid) {
      if (androidClientId.isEmpty) {
        throw StateError(
          'GOOGLE_CLIENT_ID_ANDROID is missing. '
          'Inject via: --dart-define=GOOGLE_CLIENT_ID_ANDROID=YOUR_CLIENT_ID',
        );
      }
      return androidClientId;
    }
    throw UnsupportedError(
      'Unsupported platform for Google OAuth2 Authentication.',
    );
  }

  /// Resolves the Client Secret for Windows.
  /// Returns null on Android (secret-less SHA-1 based auth).
  static String? get clientSecret {
    if (Platform.isAndroid) {
      return null;
    }
    if (Platform.isWindows) {
      if (windowsClientSecret.isEmpty) {
        throw StateError(
          'GOOGLE_CLIENT_SECRET_WINDOWS is empty. '
          'Windows Desktop OAuth2 requires a valid client_secret. '
          'Inject via: --dart-define=GOOGLE_CLIENT_SECRET_WINDOWS=YOUR_SECRET',
        );
      }
      return windowsClientSecret;
    }
    throw UnsupportedError(
      'Unsupported platform for Google OAuth2 Authentication.',
    );
  }

  /// The Web Client ID used as serverClientId for google_sign_in on Android.
  static String get serverClientId {
    if (windowsClientId.isEmpty) {
      throw StateError(
        'GOOGLE_CLIENT_ID_WINDOWS is required as serverClientId on Android. '
        'Inject via: --dart-define=GOOGLE_CLIENT_ID_WINDOWS=YOUR_WEB_CLIENT_ID',
      );
    }
    return windowsClientId;
  }
}
