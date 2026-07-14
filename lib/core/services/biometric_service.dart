import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants/app_constants.dart';
import '../services/local_db_service.dart';

/// Service for PIN code and biometric authentication.
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Biometric Support ───────────────────────────────────────
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric(String localizedReason) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ─── PIN Management ──────────────────────────────────────────
  bool get isPinEnabled {
    return LocalDbService.getSetting<bool>(
            AppConstants.pinEnabledKey) ??
        false;
  }

  bool get isBiometricEnabled {
    return LocalDbService.getSetting<bool>(
            AppConstants.biometricEnabledKey) ??
        false;
  }

  Future<void> savePin(String pin) async {
    await _storage.write(key: AppConstants.pinStorageKey, value: pin);
    await LocalDbService.setSetting(AppConstants.pinEnabledKey, true);
  }

  Future<String?> getPin() async {
    return _storage.read(key: AppConstants.pinStorageKey);
  }

  Future<bool> verifyPin(String enteredPin) async {
    final savedPin = await getPin();
    return savedPin != null && savedPin == enteredPin;
  }

  Future<void> deletePin() async {
    await _storage.delete(key: AppConstants.pinStorageKey);
    await LocalDbService.setSetting(AppConstants.pinEnabledKey, false);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await LocalDbService.setSetting(
        AppConstants.biometricEnabledKey, enabled);
  }
}
