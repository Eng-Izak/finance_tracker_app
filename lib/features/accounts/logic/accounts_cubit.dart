import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/shared/enums/account_type.dart';
import '../../../core/shared/repos/accounts_repo.dart';
import '../../../core/shared/repos/transactions_repo.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../core/dependency_injection/service_locator.dart';
import 'accounts_state.dart';

class AccountsCubit extends Cubit<AccountsState> {
  final AccountsRepo _accountsRepo;
  final TransactionsRepo _transactionsRepo;

  AccountsCubit({
    required AccountsRepo accountsRepo,
    required TransactionsRepo transactionsRepo,
  })  : _accountsRepo = accountsRepo,
        _transactionsRepo = transactionsRepo,
        super(const AccountsInitial());

  Future<void> createAccount({
    required String name,
    String? phone,
    required AccountType type,
    required double openingBalance,
    required String currency,
    String? notes,
  }) async {
    emit(const AccountsLoading());
    try {
      final userId = sl<AuthRepository>().userId;
      final account = await _accountsRepo.createAccount(
        userId: userId,
        name: name,
        phone: phone,
        type: type,
        openingBalance: openingBalance,
        currency: currency,
        notes: notes,
      );
      emit(AccountSaved(account));
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    String? phone,
    required AccountType type,
    required String currency,
    String? notes,
  }) async {
    emit(const AccountsLoading());
    try {
      final existing = _accountsRepo.getAccountById(id);
      if (existing == null) {
        emit(const AccountsError('Account not found'));
        return;
      }
      final updated = await _accountsRepo.updateAccount(
        existing.copyWith(
          name: name,
          phone: phone,
          type: type,
          currency: currency,
          notes: notes,
        ),
      );
      emit(AccountSaved(updated));
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> deleteAccount(String id) async {
    emit(const AccountsLoading());
    try {
      // 1. Delete all transactions associated with this account
      final txs = _transactionsRepo.getTransactionsForAccount(id);
      for (final tx in txs) {
        await _transactionsRepo.deleteTransaction(tx);
      }
      // 2. Delete the account itself
      await _accountsRepo.deleteAccount(id);
      emit(const AccountDeleted());
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }
}
