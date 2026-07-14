import 'package:equatable/equatable.dart';
import '../enums/transaction_type.dart';

class TransactionModel extends Equatable {
  final String id;
  final String accountId;
  final String userId;
  final double amount;
  final String currency;
  final TransactionType type;
  final DateTime date;
  final String? notes;
  final String? imagePath;     // Local path or cloud URL
  final DateTime? reminderAt;  // Scheduled local notification time
  final int? notificationId;   // flutter_local_notifications ID
  final bool isReminderSet;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const TransactionModel({
    required this.id,
    required this.accountId,
    required this.userId,
    required this.amount,
    this.currency = 'LOCAL',
    required this.type,
    required this.date,
    this.notes,
    this.imagePath,
    this.reminderAt,
    this.notificationId,
    this.isReminderSet = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  // ─── Signed Amount (positive = income, negative = expense) ─
  double get signedAmount =>
      type == TransactionType.income ? amount : -amount;

  // ─── Copy With ──────────────────────────────────────────────
  TransactionModel copyWith({
    String? id,
    String? accountId,
    String? userId,
    double? amount,
    String? currency,
    TransactionType? type,
    DateTime? date,
    String? notes,
    String? imagePath,
    DateTime? reminderAt,
    int? notificationId,
    bool? isReminderSet,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      reminderAt: reminderAt ?? this.reminderAt,
      notificationId: notificationId ?? this.notificationId,
      isReminderSet: isReminderSet ?? this.isReminderSet,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // ─── Serialization ──────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'type': type.key,
      'date': date.toIso8601String(),
      'notes': notes,
      'imagePath': imagePath,
      'reminderAt': reminderAt?.toIso8601String(),
      'notificationId': notificationId,
      'isReminderSet': isReminderSet,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      accountId: map['accountId'] as String,
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'LOCAL',
      type: TransactionTypeExtension.fromKey(
          map['type'] as String? ?? 'income'),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      notes: map['notes'] as String?,
      imagePath: map['imagePath'] as String?,
      reminderAt: map['reminderAt'] != null
          ? DateTime.parse(map['reminderAt'] as String)
          : null,
      notificationId: map['notificationId'] as int?,
      isReminderSet: map['isReminderSet'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        userId,
        amount,
        currency,
        type,
        date,
        notes,
        imagePath,
        reminderAt,
        notificationId,
        isReminderSet,
        createdAt,
        updatedAt,
        isSynced,
      ];
}
