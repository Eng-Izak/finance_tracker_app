import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/core/theming/app_text_styles.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class HomeEmptyView extends StatelessWidget {
  const HomeEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.noAccounts, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            l10n.noAccountsSubtitle,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
