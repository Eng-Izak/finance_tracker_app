import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/utils/constants/app_constants.dart';
import 'security_state.dart';

class SecurityCubit extends Cubit<SecurityState> {
  final BiometricService _biometricService;

  SecurityCubit({required BiometricService biometricService})
      : _biometricService = biometricService,
        super(const SecurityInitial());

  // ─── PIN Lock Flow ───────────────────────────────────────────
  void startPinEntry() {
    emit(const SecurityPinEntry());
  }

  void addDigit(String digit) {
    final current = state;
    if (current is SecurityPinEntry) {
      if (current.entered.length >= AppConstants.pinLength) return;
      emit(SecurityPinEntry(
        entered: current.entered + digit,
        hasError: false,
        attempts: current.attempts,
      ));
    } else if (current is SecurityPinSetupConfirm) {
      if (current.confirmPin.length >= AppConstants.pinLength) return;
      emit(SecurityPinSetupConfirm(
        firstPin: current.firstPin,
        confirmPin: current.confirmPin + digit,
        hasError: false,
      ));
    }
  }

  void removeDigit() {
    final current = state;
    if (current is SecurityPinEntry && current.entered.isNotEmpty) {
      emit(SecurityPinEntry(
        entered: current.entered.substring(0, current.entered.length - 1),
        hasError: false,
        attempts: current.attempts,
      ));
    } else if (current is SecurityPinSetupConfirm &&
        current.confirmPin.isNotEmpty) {
      emit(SecurityPinSetupConfirm(
        firstPin: current.firstPin,
        confirmPin:
            current.confirmPin.substring(0, current.confirmPin.length - 1),
        hasError: false,
      ));
    }
  }

  // ─── Verify PIN (Lock Screen) ────────────────────────────────
  Future<void> verifyPin() async {
    final current = state;
    if (current is! SecurityPinEntry) return;
    if (current.entered.length < AppConstants.pinLength) return;

    final isCorrect = await _biometricService.verifyPin(current.entered);
    if (isCorrect) {
      emit(const SecurityUnlocked());
    } else {
      emit(SecurityPinEntry(
        entered: '',
        hasError: true,
        attempts: current.attempts + 1,
      ));
    }
  }

  // ─── PIN Setup Flow ──────────────────────────────────────────
  void startPinSetup() {
    emit(const SecurityPinEntry()); // Step 1: Enter new PIN
  }

  void confirmFirstPin(String pin) {
    emit(SecurityPinSetupConfirm(firstPin: pin));
  }

  Future<void> savePin() async {
    final current = state;
    if (current is! SecurityPinSetupConfirm) return;
    if (current.confirmPin.length < AppConstants.pinLength) return;

    if (current.firstPin != current.confirmPin) {
      emit(SecurityPinSetupConfirm(
        firstPin: current.firstPin,
        confirmPin: '',
        hasError: true,
      ));
      return;
    }

    await _biometricService.savePin(current.firstPin);
    emit(const SecurityPinSaved());
  }

  // ─── Biometric Auth ──────────────────────────────────────────
  Future<void> authenticateWithBiometric(String reason) async {
    final success = await _biometricService.authenticateWithBiometric(reason);
    if (success) {
      emit(const SecurityUnlocked());
    } else {
      emit(const SecurityLocked());
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────
  bool get isPinEnabled => _biometricService.isPinEnabled;
  bool get isBiometricEnabled => _biometricService.isBiometricEnabled;

  Future<bool> isBiometricAvailable() =>
      _biometricService.isBiometricAvailable();
}
