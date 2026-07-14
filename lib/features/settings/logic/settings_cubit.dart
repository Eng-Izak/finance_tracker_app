import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/shared/repos/accounts_repo.dart';
import '../../../core/shared/repos/transactions_repo.dart';
import '../../../core/utils/constants/app_constants.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final BiometricService _biometricService;
  final ExportService _exportService;
  final FirebaseService _firebaseService;
  final AccountsRepo _accountsRepo;
  final TransactionsRepo _transactionsRepo;

  SettingsCubit({
    required BiometricService biometricService,
    required ExportService exportService,
    required FirebaseService firebaseService,
    required AccountsRepo accountsRepo,
    required TransactionsRepo transactionsRepo,
  })  : _biometricService = biometricService,
        _exportService = exportService,
        _firebaseService = firebaseService,
        _accountsRepo = accountsRepo,
        _transactionsRepo = transactionsRepo,
        super(const SettingsInitial());

  void loadSettings() {
    final lang = LocalDbService.getSetting<String>(AppConstants.languageKey) ?? 'ar';
    final theme = LocalDbService.getSetting<String>(AppConstants.themeKey) ?? 'light';
    final lastSync = LocalDbService.getSetting<String>(AppConstants.lastSyncKey);

    emit(SettingsLoaded(
      language: lang,
      theme: theme,
      isPinEnabled: _biometricService.isPinEnabled,
      isBiometricEnabled: _biometricService.isBiometricEnabled,
      lastSync: lastSync,
    ));
  }

  Future<void> changeTheme(String theme) async {
    await LocalDbService.setSetting(AppConstants.themeKey, theme);
    loadSettings();
  }

  Future<void> toggleBiometric(bool enabled) async {
    await _biometricService.setBiometricEnabled(enabled);
    loadSettings();
  }

  Future<void> disablePin() async {
    await _biometricService.deletePin();
    loadSettings();
  }

  Future<void> exportToPdf() async {
    final accounts = _accountsRepo.getAllAccounts();
    final txs = _transactionsRepo.getAllTransactions();
    final summary = _accountsRepo.getSummary();

    await _exportService.exportToPdf(
      accounts: accounts,
      transactions: txs,
      creditorTotal: summary.creditorTotal,
      debtorTotal: summary.debtorTotal,
      balance: summary.netBalance,
    );

    emit(const SettingsUpdated('PDF exported'));
    loadSettings();
  }

  Future<void> exportToCsv() async {
    final accounts = _accountsRepo.getAllAccounts();
    final txs = _transactionsRepo.getAllTransactions();
    await _exportService.exportToCsv(accounts: accounts, transactions: txs);
    emit(const SettingsUpdated('CSV exported'));
    loadSettings();
  }

  Future<void> syncToCloud() async {
    try {
      final accounts = _accountsRepo.getAllAccounts();
      final txs = _transactionsRepo.getAllTransactions();
      await _firebaseService.syncAllToCloud(accounts, txs);

      final now = DateTime.now().toIso8601String();
      await LocalDbService.setSetting(AppConstants.lastSyncKey, now);

      emit(const SettingsUpdated('Synced to cloud'));
      loadSettings();
    } catch (e) {
      emit(SettingsError(e.toString()));
      loadSettings();
    }
  }

  Future<void> logout(Future<void> Function() onLogout) async {
    await LocalDbService.clearAll();
    await onLogout();
    emit(const SettingsLoggedOut());
  }
}
