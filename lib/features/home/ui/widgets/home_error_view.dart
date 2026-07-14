import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/core/theming/app_text_styles.dart';
import 'package:finance_tracker_app_001/features/home/logic/home_cubit.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeErrorView extends StatelessWidget {
  final String message;
  const HomeErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppColors.debtor),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<HomeCubit>().refresh(),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
