import 'package:equatable/equatable.dart';
import '../../../core/shared/models/currency_model.dart';

abstract class CurrenciesState extends Equatable {
  const CurrenciesState();
  @override
  List<Object?> get props => [];
}

class CurrenciesInitial extends CurrenciesState {
  const CurrenciesInitial();
}

class CurrenciesLoading extends CurrenciesState {
  const CurrenciesLoading();
}

class CurrenciesLoaded extends CurrenciesState {
  final List<CurrencyModel> currencies;
  final bool isRefreshing;
  const CurrenciesLoaded(this.currencies, {this.isRefreshing = false});
  @override
  List<Object?> get props => [currencies, isRefreshing];
}

class CurrenciesError extends CurrenciesState {
  final String message;
  const CurrenciesError(this.message);
  @override
  List<Object?> get props => [message];
}
