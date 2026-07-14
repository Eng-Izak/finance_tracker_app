import 'package:equatable/equatable.dart';
import '../../../core/shared/models/transaction_model.dart';

abstract class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class TransactionsLoaded extends TransactionsState {
  final List<TransactionModel> transactions;
  const TransactionsLoaded(this.transactions);
  @override
  List<Object?> get props => [transactions];
}

class TransactionSaved extends TransactionsState {
  final TransactionModel transaction;
  const TransactionSaved(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class TransactionsError extends TransactionsState {
  final String message;
  const TransactionsError(this.message);
  @override
  List<Object?> get props => [message];
}
