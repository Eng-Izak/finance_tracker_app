import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import '../../features/splash/ui/splash_screen.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/security/ui/pin_setup_screen.dart';
import '../../features/security/ui/pin_lock_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/accounts/ui/add_account_screen.dart';
import '../../features/accounts/ui/account_details_screen.dart';
import '../../features/transactions/ui/add_transaction_screen.dart';
import '../../features/statistics/ui/statistics_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/currencies/ui/currencies_screen.dart';
import '../shared/models/account_model.dart';
import '../shared/models/transaction_model.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinSetup,
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinLock,
        builder: (context, state) => const PinLockScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.addAccount,
        builder: (context, state) {
          final account = state.extra as AccountModel?;
          return AddAccountScreen(account: account);
        },
      ),
      GoRoute(
        path: AppRoutes.accountDetailsPattern,
        builder: (context, state) {
          final accountId = state.pathParameters['accountId']!;
          return AccountDetailsScreen(accountId: accountId);
        },
      ),
      GoRoute(
        path: AppRoutes.addTransactionPattern,
        builder: (context, state) {
          final accountId = state.pathParameters['accountId']!;
          final transaction = state.extra as TransactionModel?;
          return AddTransactionScreen(accountId: accountId, transaction: transaction);
        },
      ),
      GoRoute(
        path: AppRoutes.statistics,
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.currencies,
        builder: (context, state) => const CurrenciesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
