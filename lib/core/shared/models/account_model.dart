import 'package:equatable/equatable.dart';
import '../enums/account_type.dart';

class AccountModel extends Equatable {
  final String id;
  final String userId;        // Firebase UID for cloud sync
  final String name;
  final String? phone;
  final AccountType type;     // له (creditor) or عليه (debtor)
  final double balance;       // Current running balance
  final double openingBalance;// Initial balance when account was created
  final String currency;      // Currency code e.g. 'USD', 'EGP', 'LOCAL'
  final String? notes;
  final int transactionCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;        // Whether synced to Firebase

  const AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    required this.type,
    required this.balance,
    this.openingBalance = 0.0,
    this.currency = 'LOCAL',
    this.notes,
    this.transactionCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  // ─── Copy With ──────────────────────────────────────────────
  AccountModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    AccountType? type,
    double? balance,
    double? openingBalance,
    String? currency,
    String? notes,
    int? transactionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      openingBalance: openingBalance ?? this.openingBalance,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      transactionCount: transactionCount ?? this.transactionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // ─── Serialization ──────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'type': type.key,
      'balance': balance,
      'openingBalance': openingBalance,
      'currency': currency,
      'notes': notes,
      'transactionCount': transactionCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String,
      phone: map['phone'] as String?,
      type: AccountTypeExtension.fromKey(map['type'] as String? ?? 'debtor'),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'LOCAL',
      notes: map['notes'] as String?,
      transactionCount: map['transactionCount'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  // ─── Equatable ──────────────────────────────────────────────
  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        phone,
        type,
        balance,
        openingBalance,
        currency,
        notes,
        transactionCount,
        createdAt,
        updatedAt,
        isSynced,
      ];
}
