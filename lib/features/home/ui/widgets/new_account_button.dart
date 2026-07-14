import 'package:finance_tracker_app_001/core/routing/routes.dart';
import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/features/home/logic/home_cubit.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class NewAccountButton extends StatelessWidget {
  const NewAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () => context.push(AppRoutes.addAccount).then((_) {
        if (context.mounted) context.read<HomeCubit>().refresh();
      }),
      icon: const Icon(Icons.add_circle_rounded, size: 18),
      label: Text(l10n.newAccount),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: AppColors.primarySurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
