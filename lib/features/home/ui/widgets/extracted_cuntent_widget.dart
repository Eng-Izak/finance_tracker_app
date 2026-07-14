import 'package:finance_tracker_app_001/core/routing/routes.dart';
import 'package:finance_tracker_app_001/features/home/logic/home_cubit.dart';
import 'package:finance_tracker_app_001/features/home/logic/home_state.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/account_list_item.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/home_empty_view.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/new_account_button.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/new_transaction_button.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/summary_card.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/core/theming/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeContent extends StatelessWidget {
  final HomeLoaded state;
  const HomeContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SummaryCard(
              creditorTotal: state.creditorTotal,
              debtorTotal: state.debtorTotal,
              netBalance: state.netBalance,
              currency: state.currency,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.accounts,
                    style: AppTextStyles.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                NewTransactionButton(accounts: state.accounts),
                const SizedBox(width: 8),
                const NewAccountButton(),
              ],
            ),
          ),
        ),
        if (state.accounts.isEmpty)
          SliverFillRemaining(child: HomeEmptyView())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final account = state.accounts[index];
                return AccountListItem(
                  account: account,
                  onTap: () => context
                      .push(AppRoutes.accountDetails(account.id))
                      .then((_) {
                    if (context.mounted) context.read<HomeCubit>().refresh();
                  }),
                  onDelete: () => _showDeleteConfirm(context, l10n, account.id),
                  onEdit: () => context
                      .push(AppRoutes.addAccount, extra: account)
                      .then((_) {
                    if (context.mounted) context.read<HomeCubit>().refresh();
                  }),
                );
              },
              childCount: state.accounts.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Future<void> _showDeleteConfirm(
      BuildContext context, AppLocalizations l10n, String accountId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text(l10n.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debtor),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<HomeCubit>().deleteAccount(accountId);
    }
  }
}
