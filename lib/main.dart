import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_bloc_observer.dart';
import 'app/finance_app.dart';
import 'core/dependency_injection/service_locator.dart';
import 'core/services/local_db_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── System UI ──────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ─── Bloc Observer ───────────────────────────────────────────
  Bloc.observer = AppBlocObserver();

  // ─── Local Database ──────────────────────────────────────────
  await LocalDbService.init();

  // ─── Firebase ────────────────────────────────────────────────
  // NOTE: Add google-services.json (Android) and GoogleService-Info.plist (iOS)
  // to the respective platform folders before running.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured yet – local mode only
    debugPrint('Firebase not configured. Running in local-only mode.');
  }

  // ─── Notifications ───────────────────────────────────────────
  await NotificationService().init();

  // ─── Dependency Injection ────────────────────────────────────
  await setupServiceLocator();

  runApp(FinanceApp(key: FinanceApp.appKey));
}
