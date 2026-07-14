/// Represents the account's financial direction:
/// - [creditor] = "له" → Others owe ME money (my receivable)
/// - [debtor]   = "عليه" → I owe this person money (my payable)
enum AccountType {
  creditor, // له – green
  debtor,   // عليه – orange
}

extension AccountTypeExtension on AccountType {
  String get key => name; // 'creditor' or 'debtor'

  static AccountType fromKey(String key) {
    return AccountType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => AccountType.debtor,
    );
  }
}
