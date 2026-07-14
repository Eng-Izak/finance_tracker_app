import 'package:get_it/get_it.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import '../services/biometric_service.dart';
import '../network/exchange_rate_service.dart';
import '../shared/repos/accounts_repo.dart';
import '../shared/repos/transactions_repo.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/home/logic/home_cubit.dart';
import '../../features/accounts/logic/accounts_cubit.dart';
import '../../features/transactions/logic/transactions_cubit.dart';
import '../../features/statistics/logic/statistics_cubit.dart';
import '../../features/settings/logic/settings_cubit.dart';
import '../../features/currencies/logic/currencies_cubit.dart';
import '../../features/security/logic/security_cubit.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ─── Services ─────────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<ExportService>(() => ExportService());
  sl.registerLazySingleton<BiometricService>(() => BiometricService());
  sl.registerLazySingleton<ExchangeRateService>(() => ExchangeRateService());

  // ─── Repositories ─────────────────────────────────────────────
  sl.registerLazySingleton<AccountsRepo>(
    () => AccountsRepo(firebaseService: sl()),
  );
  sl.registerLazySingleton<TransactionsRepo>(
    () => TransactionsRepo(
      firebaseService: sl(),
      accountsRepo: sl(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(),
  );

  // ─── Cubits (factory – new instance per registration) ─────────
  sl.registerFactory<HomeCubit>(
    () => HomeCubit(accountsRepo: sl(), transactionsRepo: sl()),
  );
  sl.registerFactory<AccountsCubit>(
    () => AccountsCubit(
      accountsRepo: sl(),
      transactionsRepo: sl(),
    ),
  );
  sl.registerFactory<TransactionsCubit>(
    () => TransactionsCubit(
      transactionsRepo: sl(),
      notificationService: sl(),
    ),
  );
  sl.registerFactory<StatisticsCubit>(
    () => StatisticsCubit(
      transactionsRepo: sl(),
    ),
  );
  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      biometricService: sl(),
      exportService: sl(),
      firebaseService: sl(),
      accountsRepo: sl(),
      transactionsRepo: sl(),
    ),
  );
  sl.registerFactory<CurrenciesCubit>(
    () => CurrenciesCubit(exchangeRateService: sl()),
  );
  sl.registerFactory<SecurityCubit>(
    () => SecurityCubit(biometricService: sl()),
  );
}
