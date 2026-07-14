import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/models/account_model.dart';
import '../shared/models/transaction_model.dart';

/// Firebase Firestore service for cloud backup and sync.
class FirebaseService {
  FirebaseFirestore? get _db =>
      Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;
  FirebaseAuth? get _auth =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;

  // ─── Collection References ───────────────────────────────────
  CollectionReference<Map<String, dynamic>>? get _usersCol =>
      _db?.collection('users');

  CollectionReference<Map<String, dynamic>>? _accountsCol(String uid) =>
      _usersCol?.doc(uid).collection('accounts');

  CollectionReference<Map<String, dynamic>>? _transactionsCol(
          String uid, String accountId) =>
      _accountsCol(uid)?.doc(accountId).collection('transactions');

  String? get _uid => _auth?.currentUser?.uid;

  // ─── Accounts ────────────────────────────────────────────────
  Future<void> upsertAccount(AccountModel account) async {
    final uid = _uid;
    if (uid == null) return;
    final accounts = _accountsCol(uid);
    if (accounts == null) return;
    await accounts
        .doc(account.id)
        .set(account.copyWith(isSynced: true).toMap(), SetOptions(merge: true));
  }

  Future<void> deleteAccount(String accountId) async {
    final uid = _uid;
    if (uid == null) return;
    final transactions = _transactionsCol(uid, accountId);
    final accounts = _accountsCol(uid);
    if (transactions == null || accounts == null) return;
    // Delete all transactions first
    final txSnap = await transactions.get();
    for (final doc in txSnap.docs) {
      await doc.reference.delete();
    }
    await accounts.doc(accountId).delete();
  }

  Future<List<AccountModel>> fetchAllAccounts() async {
    final uid = _uid;
    if (uid == null) return [];
    final accounts = _accountsCol(uid);
    if (accounts == null) return [];
    final snap = await accounts.get();
    return snap.docs
        .map((d) => AccountModel.fromMap(d.data()))
        .toList();
  }

  // ─── Transactions ────────────────────────────────────────────
  Future<void> upsertTransaction(TransactionModel tx) async {
    final uid = _uid;
    if (uid == null) return;
    final transactions = _transactionsCol(uid, tx.accountId);
    if (transactions == null) return;
    await transactions
        .doc(tx.id)
        .set(tx.copyWith(isSynced: true).toMap(), SetOptions(merge: true));
  }

  Future<void> deleteTransaction(
      String accountId, String transactionId) async {
    final uid = _uid;
    if (uid == null) return;
    final transactions = _transactionsCol(uid, accountId);
    if (transactions == null) return;
    await transactions.doc(transactionId).delete();
  }

  Future<List<TransactionModel>> fetchTransactionsForAccount(
      String accountId) async {
    final uid = _uid;
    if (uid == null) return [];
    final transactions = _transactionsCol(uid, accountId);
    if (transactions == null) return [];
    final snap = await transactions
        .orderBy('date', descending: true)
        .get();
    return snap.docs
        .map((d) => TransactionModel.fromMap(d.data()))
        .toList();
  }

  // ─── Full Sync (upload local → cloud) ───────────────────────
  Future<void> syncAllToCloud(
      List<AccountModel> accounts,
      List<TransactionModel> transactions) async {
    final uid = _uid;
    final db = _db;
    if (uid == null || db == null) return;

    final batch = db.batch();

    for (final account in accounts) {
      final ref = _accountsCol(uid)?.doc(account.id);
      if (ref == null) continue;
      batch.set(ref, account.copyWith(isSynced: true).toMap(),
          SetOptions(merge: true));
    }
    for (final tx in transactions) {
      final ref = _transactionsCol(uid, tx.accountId)?.doc(tx.id);
      if (ref == null) continue;
      batch.set(ref, tx.copyWith(isSynced: true).toMap(),
          SetOptions(merge: true));
    }

    await batch.commit();
  }
}
