import 'package:finance_tracker_app_001/core/routing/routes.dart';
import 'package:finance_tracker_app_001/features/home/logic/home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeFloatingActionButton extends StatelessWidget {
  const HomeFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(AppRoutes.addAccount).then((_) {
        if (context.mounted) context.read<HomeCubit>().refresh();
      }),
      child: const Icon(Icons.add_rounded, size: 32),
    );
  }
}
