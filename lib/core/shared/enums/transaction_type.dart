/// Represents a single transaction direction within an account:
/// - [income]  = money received / credited to this account
/// - [expense] = money paid / debited from this account
enum TransactionType {
  income,  // دخل – adds to balance
  expense, // مصروف – reduces balance
}

extension TransactionTypeExtension on TransactionType {
  String get key => name;

  static TransactionType fromKey(String key) {
    return TransactionType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => TransactionType.income,
    );
  }
}
