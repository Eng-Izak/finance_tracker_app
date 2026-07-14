import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoaded extends SettingsState {
  final String language;
  final String theme;
  final bool isPinEnabled;
  final bool isBiometricEnabled;
  final String? lastSync;

  const SettingsLoaded({
    required this.language,
    required this.theme,
    required this.isPinEnabled,
    required this.isBiometricEnabled,
    this.lastSync,
  });

  @override
  List<Object?> get props =>
      [language, theme, isPinEnabled, isBiometricEnabled, lastSync];
}

class SettingsUpdated extends SettingsState {
  final String message;
  const SettingsUpdated(this.message);
  @override
  List<Object?> get props => [message];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}

class SettingsLoggedOut extends SettingsState {
  const SettingsLoggedOut();
}
