import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants/app_constants.dart';

/// Singleton service for local Hive database.
/// Call [LocalDbService.init()] before using any box.
class LocalDbService {
  LocalDbService._();

  static Box<dynamic>? _accountsBox;
  static Box<dynamic>? _transactionsBox;
  static Box<dynamic>? _currenciesBox;
  static Box<dynamic>? _settingsBox;

  // ─── Initialization ─────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();

    _accountsBox =
        await Hive.openBox<dynamic>(AppConstants.hiveAccountsBox);
    _transactionsBox =
        await Hive.openBox<dynamic>(AppConstants.hiveTransactionsBox);
    _currenciesBox =
        await Hive.openBox<dynamic>(AppConstants.hiveCurrenciesBox);
    _settingsBox =
        await Hive.openBox<dynamic>(AppConstants.hiveSettingsBox);
  }

  // ─── Box Getters ────────────────────────────────────────────
  static Box<dynamic> get accountsBox => _accountsBox!;
  static Box<dynamic> get transactionsBox => _transactionsBox!;
  static Box<dynamic> get currenciesBox => _currenciesBox!;
  static Box<dynamic> get settingsBox => _settingsBox!;

  // ─── Settings Helpers ────────────────────────────────────────
  static T? getSetting<T>(String key) {
    return _settingsBox?.get(key) as T?;
  }

  static Future<void> setSetting<T>(String key, T value) async {
    await _settingsBox?.put(key, value);
  }

  static Future<void> removeSetting(String key) async {
    await _settingsBox?.delete(key);
  }

  // ─── Clear All ───────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _accountsBox?.clear();
    await _transactionsBox?.clear();
    await _currenciesBox?.clear();
    // Do NOT clear settingsBox (keep language/theme prefs)
  }

  // ─── Close ──────────────────────────────────────────────────
  static Future<void> close() async {
    await Hive.close();
  }
}
