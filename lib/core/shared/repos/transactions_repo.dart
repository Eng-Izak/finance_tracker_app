import 'package:uuid/uuid.dart';
import '../../shared/enums/transaction_type.dart';
import '../../shared/models/transaction_model.dart';
import '../../services/local_db_service.dart';
import '../../services/firebase_service.dart';
import 'accounts_repo.dart';

/// Repository for all transaction CRUD operations.
class TransactionsRepo {
  final FirebaseService _firebaseService;
  final AccountsRepo _accountsRepo;
  final _uuid = const Uuid();

  TransactionsRepo({
    required FirebaseService firebaseService,
    required AccountsRepo accountsRepo,
  })  : _firebaseService = firebaseService,
        _accountsRepo = accountsRepo;

  // ─── Get All For Account ─────────────────────────────────────
  List<TransactionModel> getTransactionsForAccount(String accountId) {
    final box = LocalDbService.transactionsBox;
    return box.values
        .map((v) =>
            TransactionModel.fromMap(Map<String, dynamic>.from(v as Map)))
        .where((t) => t.accountId == accountId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ─── Get All Transactions ────────────────────────────────────
  List<TransactionModel> getAllTransactions() {
    final box = LocalDbService.transactionsBox;
    return box.values
        .map((v) =>
            TransactionModel.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  TransactionModel? getTransactionById(String id) {
    final value = LocalDbService.transactionsBox.get(id);
    if (value == null) return null;
    return TransactionModel.fromMap(Map<String, dynamic>.from(value as Map));
  }

  // ─── Create ──────────────────────────────────────────────────
  Future<TransactionModel> createTransaction({
    required String accountId,
    required String userId,
    required double amount,
    required String currency,
    required TransactionType type,
    required DateTime date,
    String? notes,
    String? imagePath,
    DateTime? reminderAt,
    int? notificationId,
  }) async {
    final now = DateTime.now();
    final tx = TransactionModel(
      id: _uuid.v4(),
      accountId: accountId,
      userId: userId,
      amount: amount,
      currency: currency,
      type: type,
      date: date,
      notes: notes,
      imagePath: imagePath,
      reminderAt: reminderAt,
      notificationId: notificationId,
      isReminderSet: reminderAt != null,
      createdAt: now,
      updatedAt: now,
    );

    await LocalDbService.transactionsBox.put(tx.id, tx.toMap());

    // Recompute account balance
    await _recomputeAccountBalance(accountId);

    // Async cloud sync
    _firebaseService.upsertTransaction(tx).catchError((_) {});

    return tx;
  }

  // ─── Update ──────────────────────────────────────────────────
  Future<TransactionModel> updateTransaction(TransactionModel tx) async {
    final updated = tx.copyWith(updatedAt: DateTime.now(), isSynced: false);
    await LocalDbService.transactionsBox.put(updated.id, updated.toMap());
    await _recomputeAccountBalance(tx.accountId);
    _firebaseService.upsertTransaction(updated).catchError((_) {});
    return updated;
  }

  // ─── Delete ──────────────────────────────────────────────────
  Future<void> deleteTransaction(TransactionModel tx) async {
    await LocalDbService.transactionsBox.delete(tx.id);
    await _recomputeAccountBalance(tx.accountId);
    _firebaseService
        .deleteTransaction(tx.accountId, tx.id)
        .catchError((_) {});
  }

  // ─── Recompute Balance ───────────────────────────────────────
  Future<void> _recomputeAccountBalance(String accountId) async {
    final account = _accountsRepo.getAccountById(accountId);
    if (account == null) return;

    final txs = getTransactionsForAccount(accountId);
    double balance = account.openingBalance;

    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }

    await _accountsRepo.updateAccountBalance(
        accountId, balance, txs.length);
  }

  // ─── Statistics Helpers ──────────────────────────────────────
  ({double totalIncome, double totalExpense}) getStatsByDateRange({
    required DateTime from,
    required DateTime to,
    String? accountId,
  }) {
    var txs = getAllTransactions().where((t) {
      return t.date.isAfter(from.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(to.add(const Duration(days: 1)));
    }).toList();

    if (accountId != null) {
      txs = txs.where((t) => t.accountId == accountId).toList();
    }

    double income = 0;
    double expense = 0;
    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return (totalIncome: income, totalExpense: expense);
  }

  /// Monthly breakdown for the bar chart.
  Map<int, ({double income, double expense})> getMonthlyBreakdown(int year) {
    final txs = getAllTransactions()
        .where((t) => t.date.year == year)
        .toList();

    final Map<int, ({double income, double expense})> result = {};
    for (int m = 1; m <= 12; m++) {
      result[m] = (income: 0.0, expense: 0.0);
    }

    for (final tx in txs) {
      final m = tx.date.month;
      final current = result[m]!;
      if (tx.type == TransactionType.income) {
        result[m] = (
          income: current.income + tx.amount,
          expense: current.expense
        );
      } else {
        result[m] = (
          income: current.income,
          expense: current.expense + tx.amount
        );
      }
    }

    return result;
  }
}
