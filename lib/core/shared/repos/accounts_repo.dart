import 'package:uuid/uuid.dart';
import '../../shared/enums/account_type.dart';
import '../../shared/models/account_model.dart';
import '../../services/local_db_service.dart';
import '../../services/firebase_service.dart';

/// Repository for all account CRUD operations.
/// Writes to local Hive first, then syncs to Firebase.
class AccountsRepo {
  final FirebaseService _firebaseService;
  final _uuid = const Uuid();

  AccountsRepo({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  // ─── Get All ─────────────────────────────────────────────────
  List<AccountModel> getAllAccounts() {
    final box = LocalDbService.accountsBox;
    return box.values
        .map((v) =>
            AccountModel.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  AccountModel? getAccountById(String id) {
    final box = LocalDbService.accountsBox;
    final value = box.get(id);
    if (value == null) return null;
    return AccountModel.fromMap(Map<String, dynamic>.from(value as Map));
  }

  // ─── Create ──────────────────────────────────────────────────
  Future<AccountModel> createAccount({
    required String userId,
    required String name,
    String? phone,
    required AccountType type,
    required double openingBalance,
    required String currency,
    String? notes,
  }) async {
    final now = DateTime.now();
    final account = AccountModel(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      phone: phone,
      type: type,
      balance: openingBalance,
      openingBalance: openingBalance,
      currency: currency,
      notes: notes,
      transactionCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await LocalDbService.accountsBox.put(account.id, account.toMap());

    // Async cloud sync (fire-and-forget)
    _firebaseService.upsertAccount(account).catchError((_) {});

    return account;
  }

  // ─── Update ──────────────────────────────────────────────────
  Future<AccountModel> updateAccount(AccountModel account) async {
    final updated = account.copyWith(updatedAt: DateTime.now(), isSynced: false);
    await LocalDbService.accountsBox.put(updated.id, updated.toMap());
    _firebaseService.upsertAccount(updated).catchError((_) {});
    return updated;
  }

  // ─── Update Balance & Count ───────────────────────────────────
  Future<void> updateAccountBalance(
      String accountId, double newBalance, int transactionCount) async {
    final account = getAccountById(accountId);
    if (account == null) return;

    final updated = account.copyWith(
      balance: newBalance,
      transactionCount: transactionCount,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await LocalDbService.accountsBox.put(updated.id, updated.toMap());
    _firebaseService.upsertAccount(updated).catchError((_) {});
  }

  // ─── Delete ──────────────────────────────────────────────────
  Future<void> deleteAccount(String accountId) async {
    await LocalDbService.accountsBox.delete(accountId);
    _firebaseService.deleteAccount(accountId).catchError((_) {});
  }

  // ─── Summary ─────────────────────────────────────────────────
  ({double creditorTotal, double debtorTotal, double netBalance})
      getSummary() {
    final accounts = getAllAccounts();
    double creditorTotal = 0;
    double debtorTotal = 0;

    for (final account in accounts) {
      if (account.type == AccountType.creditor) {
        creditorTotal += account.balance;
      } else {
        debtorTotal += account.balance;
      }
    }

    return (
      creditorTotal: creditorTotal,
      debtorTotal: debtorTotal,
      netBalance: creditorTotal - debtorTotal,
    );
  }
}
