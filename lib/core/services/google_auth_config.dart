import 'dart:io';

/// Platform-aware credential resolver for Google OAuth2.
///
/// Architecture:
///   Windows → Uses Web Application Client (clientId + clientSecret)
///             via openid_client loopback flow.
///   Android → Uses Native Android Client (clientId only)
///             via google_sign_in (Google Play Services + SHA-1).
///
/// Credentials can be injected at compile time via --dart-define:
///   flutter run --dart-define=GOOGLE_CLIENT_ID_WINDOWS=xxx
///   flutter run --dart-define=GOOGLE_CLIENT_SECRET_WINDOWS=xxx
///   flutter run --dart-define=GOOGLE_CLIENT_ID_ANDROID=xxx
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
  static const String windowsClientId = String.fromEnvironment(
    _winClientIdKey,
    defaultValue:
        '743197645224-0s8t246cgauhn7v7ifv6ml3qmn1g1sur.apps.googleusercontent.com',
  );

  /// Windows OAuth2 Client Secret (Web Application type in Google Cloud Console).
  /// CRITICAL: This must NEVER be an empty string when used on Windows.
  /// Google's token endpoint rejects requests without a valid client_secret
  /// for Desktop/Web Application type clients.
  static const String windowsClientSecret = String.fromEnvironment(
    _winClientSecretKey,
    defaultValue: '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',
  );

  // ═══════════════════════════════════════════════════════════════
  // ─── Android: Native Application Credentials ──────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Android OAuth2 Client ID (Android type in Google Cloud Console).
  /// Identity is verified via package name + SHA-1 fingerprint.
  static const String androidClientId = String.fromEnvironment(
    _androidClientIdKey,
    defaultValue:
        '743197645224-skhvumql647s37fo2bk0a5verbi2mt3e.apps.googleusercontent.com',
  );

  // ═══════════════════════════════════════════════════════════════
  // ─── Platform-Resolved Getters ────────────────────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Resolves the correct Client ID based on the active platform.
  static String get clientId {
    if (Platform.isWindows) return windowsClientId;
    if (Platform.isAndroid) return androidClientId;
    throw UnsupportedError(
      'Unsupported platform for Google OAuth2 Authentication.',
    );
  }

  /// Resolves the Client Secret for Windows.
  /// Returns null on Android (secret-less SHA-1 based auth).
  /// Throws [StateError] on Windows if the secret is empty/missing.
  static String? get clientSecret {
    if (Platform.isAndroid) {
      // Android uses signature-based (SHA-1) identity verification.
      // No client secret is required or allowed.
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
  /// Google Play Services needs this to issue access tokens with
  /// the requested API scopes (e.g. Drive appdata).
  static String get serverClientId => windowsClientId;
}
