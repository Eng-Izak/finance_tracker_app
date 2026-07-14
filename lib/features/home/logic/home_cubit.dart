import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/shared/repos/accounts_repo.dart';
import '../../../core/shared/repos/transactions_repo.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/utils/constants/app_constants.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final AccountsRepo _accountsRepo;
  final TransactionsRepo _transactionsRepo;

  HomeCubit({
    required AccountsRepo accountsRepo,
    required TransactionsRepo transactionsRepo,
  })  : _accountsRepo = accountsRepo,
        _transactionsRepo = transactionsRepo,
        super(const HomeInitial());

  // ─── Load Data ───────────────────────────────────────────────
  Future<void> loadAccounts() async {
    emit(const HomeLoading());
    try {
      final accounts = _accountsRepo.getAllAccounts();
      final summary = _accountsRepo.getSummary();
      final currency = LocalDbService.getSetting<String>(
              AppConstants.localCurrencyKey) ??
          AppConstants.defaultCurrency;

      emit(HomeLoaded(
        accounts: accounts,
        creditorTotal: summary.creditorTotal,
        debtorTotal: summary.debtorTotal,
        netBalance: summary.netBalance,
        currency: currency,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  // ─── Refresh ─────────────────────────────────────────────────
  Future<void> refresh() async {
    await loadAccounts();
  }

  // ─── Delete Account ──────────────────────────────────────────
  Future<void> deleteAccount(String accountId) async {
    await _accountsRepo.deleteAccount(accountId);
    // Also delete all transactions for this account
    final txs = _transactionsRepo.getTransactionsForAccount(accountId);
    for (final tx in txs) {
      await _transactionsRepo.deleteTransaction(tx);
    }
    await loadAccounts();
  }

  // ─── Search ──────────────────────────────────────────────────
  void searchAccounts(String query) {
    final current = state;
    if (current is! HomeLoaded) return;

    if (query.isEmpty) {
      loadAccounts();
      return;
    }

    final allAccounts = _accountsRepo.getAllAccounts();
    final filtered = allAccounts
        .where((a) =>
            a.name.toLowerCase().contains(query.toLowerCase()) ||
            (a.phone?.contains(query) ?? false))
        .toList();

    emit(current.copyWith(accounts: filtered));
  }
}
