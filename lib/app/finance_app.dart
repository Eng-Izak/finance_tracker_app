import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import '../core/routing/app_router.dart';
import '../core/theming/app_theme.dart';
import '../core/services/local_db_service.dart';
import '../core/utils/constants/app_constants.dart';
import '../core/dependency_injection/service_locator.dart';
import '../features/auth/logic/auth_cubit.dart';

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  /// Global key to update locale from anywhere in the app.
  static final GlobalKey<FinanceAppState> appKey =
      GlobalKey<FinanceAppState>();

  static void setLocale(BuildContext context, Locale locale) {
    final state = appKey.currentState;
    state?.setLocale(locale);
  }

  static void setTheme(BuildContext context, ThemeMode mode) {
    final state = appKey.currentState;
    state?.setTheme(mode);
  }

  @override
  State<FinanceApp> createState() => FinanceAppState();
}

class FinanceAppState extends State<FinanceApp> {
  Locale _locale = const Locale('ar'); // Default Arabic
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final savedLang =
        LocalDbService.getSetting<String>(AppConstants.languageKey);
    if (savedLang != null) {
      _locale = Locale(savedLang);
    }

    final savedTheme =
        LocalDbService.getSetting<String>(AppConstants.themeKey);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
    LocalDbService.setSetting(AppConstants.languageKey, locale.languageCode);
  }

  void setTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
    final themeStr = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.system
            ? 'system'
            : 'light';
    LocalDbService.setSetting(AppConstants.themeKey, themeStr);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => AuthCubit(authRepository: sl())..checkAuthStatus(),
      child: MaterialApp.router(
        title: 'Finance Tracker',
        debugShowCheckedModeBanner: false,
        // ─── Theming ─────────────────────────────────────────────
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        // ─── Localization ────────────────────────────────────────
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // ─── Routing ─────────────────────────────────────────────
        routerConfig: AppRouter.router,
      ),
    );
  }
}
