class AppConstants {
  AppConstants._();

  static const String appName = 'Finance Tracker';
  static const String appVersion = '1.0.0';

  // ─── Hive Box Names ─────────────────────────────────────────
  static const String hiveAccountsBox = 'accounts_box';
  static const String hiveTransactionsBox = 'transactions_box';
  static const String hiveCurrenciesBox = 'currencies_box';
  static const String hiveSettingsBox = 'settings_box';

  // ─── Secure Storage Keys ────────────────────────────────────
  static const String pinStorageKey = 'user_pin';

  // ─── Settings Keys ──────────────────────────────────────────
  static const String languageKey = 'app_language';
  static const String themeKey = 'app_theme';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String pinEnabledKey = 'pin_enabled';
  static const String localCurrencyKey = 'local_currency_code';
  static const String lastSyncKey = 'last_sync_timestamp';
  static const String onboardingDoneKey = 'onboarding_done';
  static const String notificationIdCounterKey = 'notification_id_counter';

  // ─── Exchange Rate API ──────────────────────────────────────
  /// Free API – no key needed.  Docs: https://www.frankfurter.app
  static const String exchangeRateBaseUrl = 'https://api.frankfurter.app';
  static const Duration exchangeRateCacheDuration = Duration(hours: 6);

  // ─── Defaults ───────────────────────────────────────────────
  static const String defaultLanguage = 'ar'; // Arabic RTL
  static const String defaultCurrency = 'LOCAL';
  static const String defaultCurrencyCode = 'USD'; // base for exchange rates
  static const int pinLength = 4;

  // ─── Notification Channels ──────────────────────────────────
  static const String notificationChannelId = 'finance_tracker_reminders';
  static const String notificationChannelName = 'Transaction Reminders';
  static const String notificationChannelDesc =
      'Reminders for financial transactions';

  // ─── Animation Durations ────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);

  // ─── Spacing ────────────────────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  // ─── Border Radius ──────────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;
}
