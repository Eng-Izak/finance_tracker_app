import 'package:equatable/equatable.dart';
import '../../../core/shared/models/account_model.dart';

abstract class AccountsState extends Equatable {
  const AccountsState();
  @override
  List<Object?> get props => [];
}

class AccountsInitial extends AccountsState {
  const AccountsInitial();
}

class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

class AccountSaved extends AccountsState {
  final AccountModel account;
  const AccountSaved(this.account);
  @override
  List<Object?> get props => [account];
}

class AccountDeleted extends AccountsState {
  const AccountDeleted();
}

class AccountsError extends AccountsState {
  final String message;
  const AccountsError(this.message);
  @override
  List<Object?> get props => [message];
}
