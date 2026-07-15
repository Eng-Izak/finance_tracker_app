import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client_io.dart' as oidc;
import 'package:openid_client/openid_client.dart' as oidc_core;
import 'package:url_launcher/url_launcher.dart';
import 'google_auth_config.dart';

/// Unified Google OAuth2 authentication service with platform-specific flows.
///
/// Architecture:
///   Windows → openid_client (OIDC Authorization Code + loopback redirect)
///             Passes both clientId AND clientSecret to satisfy Google's
///             token endpoint requirements for Desktop/Web Application clients.
///
///   Android → google_sign_in (Google Play Services native flow)
///             Uses SHA-1 + package name for identity verification.
///             No client secret required.
class GoogleAuthService {
  // ─── Shared OAuth2 Scopes ─────────────────────────────────────
  static const List<String> _scopes = [
    'openid',
    'email',
    'profile',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  // ─── Secure Token Storage ─────────────────────────────────────
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _accessTokenKey = 'gdrive_access_token';
  static const String _refreshTokenKey = 'gdrive_refresh_token';
  static const String _expiresAtKey = 'gdrive_expires_at';
  static const String _userEmailKey = 'gdrive_user_email';

  // ─── Android: Google Play Services Instance ───────────────────
  /// Lazy-initialized GoogleSignIn configured with Drive scopes
  /// and the Web Client ID as serverClientId for token issuance.
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
    serverClientId: GoogleAuthConfig.serverClientId,
  );

  // ═══════════════════════════════════════════════════════════════
  // ─── Public API ───────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Interactive sign-in. Routes to the correct platform-specific flow.
  Future<bool> signIn() async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Web platform is not supported.');
      } else if (Platform.isAndroid) {
        return await _authenticateAndroid();
      } else if (Platform.isWindows) {
        return await _authenticateWindows();
      }
      throw UnsupportedError('Active platform is not supported.');
    } catch (e) {
      debugPrint('GoogleAuthService signIn Error: $e');
      rethrow;
    }
  }

  /// Silent/background sign-in — refreshes credentials without user interaction.
  Future<bool> silentSignIn() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        return await _silentSignInAndroid();
      }
      // Windows: refresh token flow
      return await _silentSignInWindows();
    } catch (e) {
      debugPrint('GoogleAuthService silentSignIn Error: $e');
      await signOut();
      return false;
    }
  }

  /// Returns a valid access token, refreshing if needed.
  Future<String?> getAccessToken() async {
    if (!kIsWeb && Platform.isAndroid) {
      return await _getAndroidAccessToken();
    }
    return await _getWindowsAccessToken();
  }

  /// Returns the cached authenticated user email.
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// Signs out and clears all stored credentials.
  Future<void> signOut() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Best-effort sign-out from Google Play Services
      }
    }
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _userEmailKey);
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Android: Google Play Services Flow ───────────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Interactive sign-in using Google Play Services (no secret needed).
  Future<bool> _authenticateAndroid() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false; // User cancelled

      final auth = await account.authentication;
      final accessToken = auth.accessToken;

      if (accessToken == null) {
        throw Exception('Failed to obtain access token from Google Sign-In.');
      }

      final expiresAt = DateTime.now().add(const Duration(minutes: 55));
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(
        key: _expiresAtKey,
        value: expiresAt.toIso8601String(),
      );
      await _storage.write(key: _userEmailKey, value: account.email);

      return true;
    } catch (e) {
      debugPrint('GoogleAuthService Android signIn Error: $e');
      rethrow;
    }
  }

  /// Silent token refresh via Google Play Services.
  Future<bool> _silentSignInAndroid() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) return false;

      final expiresAt = DateTime.now().add(const Duration(minutes: 55));
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(
        key: _expiresAtKey,
        value: expiresAt.toIso8601String(),
      );
      await _storage.write(key: _userEmailKey, value: account.email);

      return true;
    } catch (e) {
      debugPrint('GoogleAuthService Android silentSignIn Error: $e');
      return false;
    }
  }

  /// Get a fresh access token on Android, refreshing if needed.
  Future<String?> _getAndroidAccessToken() async {
    try {
      final account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account == null) return null;

      final auth = await account.authentication;
      final accessToken = auth.accessToken;

      if (accessToken != null) {
        final expiresAt = DateTime.now().add(const Duration(minutes: 55));
        await _storage.write(key: _accessTokenKey, value: accessToken);
        await _storage.write(
          key: _expiresAtKey,
          value: expiresAt.toIso8601String(),
        );
      }
      return accessToken;
    } catch (e) {
      debugPrint('GoogleAuthService Android getAccessToken Error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Windows: openid_client OIDC Loopback Flow ────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Interactive sign-in on Windows using openid_client.
  ///
  /// CRITICAL FIX: Constructs the [Client] with both clientId AND
  /// clientSecret. Without clientSecret, Google's token endpoint
  /// rejects the authorization code exchange with:
  ///   "error": "invalid_request",
  ///   "error_description": "client_secret is missing"
  Future<bool> _authenticateWindows() async {
    try {
      // 1. Discover Google's OpenID Connect configuration
      final issuer = await oidc_core.Issuer.discover(
        Uri.parse('https://accounts.google.com'),
      );

      // 2. Create Client with BOTH clientId and clientSecret
      //    This is the critical fix — Google's token endpoint
      //    requires client_secret for Desktop/Web Application clients.
      final client = oidc_core.Client(
        issuer,
        GoogleAuthConfig.windowsClientId,
        clientSecret: GoogleAuthConfig.windowsClientSecret,
      );

      // 3. Run the desktop loopback authentication loop
      final authenticator = oidc.Authenticator(
        client,
        scopes: _scopes,
        urlLancher: (url) async {
          final uri = Uri.parse(url);
          if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
            throw Exception('Could not launch authorization URL in browser.');
          }
        },
      );

      final credential = await authenticator.authorize();

      // 4. Extract and persist tokens
      final tokenResponse = await credential.getTokenResponse();
      final accessToken = tokenResponse.accessToken;
      final refreshToken = tokenResponse.refreshToken;
      final expiresIn = tokenResponse.expiresIn;

      if (accessToken == null) {
        throw Exception('Token exchange completed but access_token is null.');
      }

      // Persist access token
      final expiresAt = expiresIn != null
          ? DateTime.now().add(expiresIn)
          : DateTime.now().add(const Duration(minutes: 55));

      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(
        key: _expiresAtKey,
        value: expiresAt.toIso8601String(),
      );

      // Persist refresh token for silent re-authentication
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }

      // Extract user email from ID token or userinfo endpoint
      final userInfo = await credential.getUserInfo();
      final email = userInfo.email;
      if (email != null && email.isNotEmpty) {
        await _storage.write(key: _userEmailKey, value: email);
      } else {
        // Fallback: fetch from userinfo HTTP endpoint
        final fetchedEmail = await _fetchUserEmail(accessToken);
        if (fetchedEmail != null) {
          await _storage.write(key: _userEmailKey, value: fetchedEmail);
        }
      }

      return true;
    } catch (e) {
      debugPrint('GoogleAuthService Windows signIn Error: $e');
      rethrow;
    }
  }

  /// Silent sign-in on Windows using stored refresh token.
  Future<bool> _silentSignInWindows() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    // Use the manual HTTP token refresh since openid_client doesn't
    // directly support refresh-only flows without re-discovery.
    final tokens = await _refreshAccessToken(refreshToken);
    await _saveTokenMap(tokens);

    final email = await _storage.read(key: _userEmailKey);
    if (email == null) {
      final newEmail =
          await _fetchUserEmail(tokens['access_token'] as String);
      if (newEmail != null) {
        await _storage.write(key: _userEmailKey, value: newEmail);
      }
    }
    return true;
  }

  /// Get a valid access token on Windows, refreshing if near expiry.
  Future<String?> _getWindowsAccessToken() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final expiresAtStr = await _storage.read(key: _expiresAtKey);

    if (accessToken == null || expiresAtStr == null) return null;

    final expiresAt = DateTime.parse(expiresAtStr);
    // Proactively refresh 5 minutes before actual expiry
    if (DateTime.now()
        .isAfter(expiresAt.subtract(const Duration(minutes: 5)))) {
      final success = await silentSignIn();
      if (!success) return null;
      return _storage.read(key: _accessTokenKey);
    }

    return accessToken;
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Windows: Manual Token Refresh (HTTP) ─────────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Refresh access token using stored refresh_token.
  /// Explicitly passes client_secret as required by Google for Desktop clients.
  Future<Map<String, dynamic>> _refreshAccessToken(
    String refreshToken,
  ) async {
    final bodyParams = <String, String>{
      'client_id': GoogleAuthConfig.windowsClientId,
      'client_secret': GoogleAuthConfig.windowsClientSecret,
      'refresh_token': refreshToken,
      'grant_type': 'refresh_token',
    };

    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: bodyParams,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'فشل تجديد رمز الوصول: ${response.statusCode} – ${response.body}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Shared: UserInfo & Token Persistence ─────────────────────
  // ═══════════════════════════════════════════════════════════════

  /// Fetch user email from Google's OpenID Connect userinfo endpoint.
  Future<String?> _fetchUserEmail(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://openidconnect.googleapis.com/v1/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['email'] as String?;
      }
    } catch (_) {
      // Non-critical — email is cosmetic, do not propagate failure
    }
    return null;
  }

  /// Persist token map from manual HTTP token exchange/refresh.
  Future<void> _saveTokenMap(Map<String, dynamic> tokens) async {
    final accessToken = tokens['access_token'] as String;
    final expiresIn = tokens['expires_in'] as int;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(
      key: _expiresAtKey,
      value: expiresAt.toIso8601String(),
    );

    final refreshToken = tokens['refresh_token'] as String?;
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }
}
