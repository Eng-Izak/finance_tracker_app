import 'package:finance_tracker_app_001/features/home/ui/widgets/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/dependency_injection/service_locator.dart';
import '../logic/home_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(
        accountsRepo: sl(),
        transactionsRepo: sl(),
      )..loadAccounts(),
      child: const HomeView(),
    );
  }
}
