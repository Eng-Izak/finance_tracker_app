class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String pinSetup = '/pin-setup';
  static const String pinLock = '/pin-lock';
  static const String home = '/home';
  static const String addAccount = '/add-account';

  // Account details: /account/:accountId
  static String accountDetails(String accountId) =>
      '/account/$accountId';
  static const String accountDetailsPattern = '/account/:accountId';

  // Add transaction: /add-transaction/:accountId
  static String addTransaction(String accountId) =>
      '/add-transaction/$accountId';
  static const String addTransactionPattern = '/add-transaction/:accountId';

  // Edit transaction: /edit-transaction/:transactionId
  static String editTransaction(String transactionId) =>
      '/edit-transaction/$transactionId';
  static const String editTransactionPattern =
      '/edit-transaction/:transactionId';

  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String currencies = '/currencies';
}
