import 'package:finance_tracker_app_001/features/settings/ui/widgets/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/dependency_injection/service_locator.dart';
import '../logic/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(
        biometricService: sl(),
        exportService: sl(),
        firebaseService: sl(),
        accountsRepo: sl(),
        transactionsRepo: sl(),
      )..loadSettings(),
      child: const SettingsView(),
    );
  }
}
