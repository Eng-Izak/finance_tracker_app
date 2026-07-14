import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/shared/enums/transaction_type.dart';
import '../../../core/shared/models/transaction_model.dart';
import '../../../core/shared/repos/transactions_repo.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../core/dependency_injection/service_locator.dart';
import 'transactions_state.dart';

class TransactionsCubit extends Cubit<TransactionsState> {
  final TransactionsRepo _repo;
  final NotificationService _notificationService;

  TransactionsCubit({
    required TransactionsRepo transactionsRepo,
    required NotificationService notificationService,
  })  : _repo = transactionsRepo,
        _notificationService = notificationService,
        super(const TransactionsInitial());

  Future<void> loadTransactions(String accountId) async {
    emit(const TransactionsLoading());
    try {
      final txs = _repo.getTransactionsForAccount(accountId);
      emit(TransactionsLoaded(txs));
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> addTransaction({
    required String accountId,
    required double amount,
    required String currency,
    required TransactionType type,
    required DateTime date,
    String? notes,
    String? imagePath,
    DateTime? reminderAt,
    String? reminderTitle,
  }) async {
    emit(const TransactionsLoading());
    try {
      final userId = sl<AuthRepository>().userId;

      int? notificationId;
      if (reminderAt != null) {
        notificationId = await _notificationService.scheduleReminder(
          title: reminderTitle ?? 'Transaction Reminder',
          body: 'You have a scheduled transaction for ${amount.toStringAsFixed(2)} $currency',
          scheduledAt: reminderAt,
        );
      }

      final tx = await _repo.createTransaction(
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
      );

      emit(TransactionSaved(tx));
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    // Cancel notification if set
    if (tx.isReminderSet && tx.notificationId != null) {
      await _notificationService.cancelNotification(tx.notificationId!);
    }
    await _repo.deleteTransaction(tx);
    emit(TransactionsLoaded(_repo.getTransactionsForAccount(tx.accountId)));
  }

  Future<void> updateTransaction({
    required TransactionModel tx,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String? notes,
    String? imagePath,
    DateTime? reminderAt,
    String? reminderTitle,
  }) async {
    emit(const TransactionsLoading());
    try {
      int? notificationId = tx.notificationId;

      // If reminder was updated or removed
      if (tx.isReminderSet && tx.notificationId != null && (reminderAt == null || reminderAt != tx.reminderAt)) {
        await _notificationService.cancelNotification(tx.notificationId!);
        notificationId = null;
      }

      if (reminderAt != null && reminderAt != tx.reminderAt) {
        notificationId = await _notificationService.scheduleReminder(
          title: reminderTitle ?? 'Transaction Reminder',
          body: 'You have a scheduled transaction for ${amount.toStringAsFixed(2)} ${tx.currency}',
          scheduledAt: reminderAt,
        );
      }

      final updatedTx = tx.copyWith(
        amount: amount,
        type: type,
        date: date,
        notes: notes,
        imagePath: imagePath,
        reminderAt: reminderAt,
        isReminderSet: reminderAt != null,
        notificationId: notificationId,
        updatedAt: DateTime.now(),
      );

      final result = await _repo.updateTransaction(updatedTx);
      emit(TransactionSaved(result));
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }
}
