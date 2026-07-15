import 'package:equatable/equatable.dart';

abstract class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => [];
}

class BackupInitial extends BackupState {
  const BackupInitial();
}

class BackupLoading extends BackupState {
  const BackupLoading();
}

class BackupAuthenticationSuccess extends BackupState {
  final String userEmail;

  const BackupAuthenticationSuccess({required this.userEmail});

  @override
  List<Object?> get props => [userEmail];
}

class BackupSyncSuccess extends BackupState {
  final DateTime lastSyncedAt;
  final String userEmail;

  const BackupSyncSuccess({required this.lastSyncedAt, required this.userEmail});

  @override
  List<Object?> get props => [lastSyncedAt, userEmail];
}

class BackupFailure extends BackupState {
  final String errorMessage;

  const BackupFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

class BackupListLoaded extends BackupState {
  final List<Map<String, dynamic>> backups;
  final String userEmail;

  const BackupListLoaded({required this.backups, required this.userEmail});

  @override
  List<Object?> get props => [backups, userEmail];
}
