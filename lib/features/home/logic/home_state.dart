import 'package:equatable/equatable.dart';
import '../../../core/shared/models/account_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<AccountModel> accounts;
  final double creditorTotal;
  final double debtorTotal;
  final double netBalance;
  final String currency;

  const HomeLoaded({
    required this.accounts,
    required this.creditorTotal,
    required this.debtorTotal,
    required this.netBalance,
    this.currency = 'LOCAL',
  });

  HomeLoaded copyWith({
    List<AccountModel>? accounts,
    double? creditorTotal,
    double? debtorTotal,
    double? netBalance,
    String? currency,
  }) {
    return HomeLoaded(
      accounts: accounts ?? this.accounts,
      creditorTotal: creditorTotal ?? this.creditorTotal,
      debtorTotal: debtorTotal ?? this.debtorTotal,
      netBalance: netBalance ?? this.netBalance,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [
        accounts,
        creditorTotal,
        debtorTotal,
        netBalance,
        currency,
      ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
