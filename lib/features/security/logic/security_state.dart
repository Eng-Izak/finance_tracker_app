import 'package:equatable/equatable.dart';

abstract class SecurityState extends Equatable {
  const SecurityState();
  @override
  List<Object?> get props => [];
}

class SecurityInitial extends SecurityState {
  const SecurityInitial();
}

class SecurityPinEntry extends SecurityState {
  final String entered;
  final bool hasError;
  final int attempts;
  const SecurityPinEntry({
    this.entered = '',
    this.hasError = false,
    this.attempts = 0,
  });
  @override
  List<Object?> get props => [entered, hasError, attempts];
}

class SecurityPinSetupConfirm extends SecurityState {
  final String firstPin;
  final String confirmPin;
  final bool hasError;
  const SecurityPinSetupConfirm({
    required this.firstPin,
    this.confirmPin = '',
    this.hasError = false,
  });
  @override
  List<Object?> get props => [firstPin, confirmPin, hasError];
}

class SecurityUnlocked extends SecurityState {
  const SecurityUnlocked();
}

class SecurityLocked extends SecurityState {
  const SecurityLocked();
}

class SecurityPinSaved extends SecurityState {
  const SecurityPinSaved();
}

class SecurityError extends SecurityState {
  final String message;
  const SecurityError(this.message);
  @override
  List<Object?> get props => [message];
}
