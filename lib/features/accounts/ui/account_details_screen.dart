import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import '../../../core/dependency_injection/service_locator.dart';
import '../../../core/shared/enums/account_type.dart';
import '../../../core/shared/enums/transaction_type.dart';
import '../../../core/shared/models/account_model.dart';
import '../../../core/shared/models/transaction_model.dart';
import '../../../core/shared/repos/accounts_repo.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/theming/app_text_styles.dart';
import '../../transactions/logic/transactions_cubit.dart';
import '../../transactions/logic/transactions_state.dart';
import '../logic/accounts_cubit.dart';
import '../logic/accounts_state.dart';

class AccountDetailsScreen extends StatelessWidget {
  final String accountId;
  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TransactionsCubit(
            transactionsRepo: sl(),
            notificationService: sl(),
          )..loadTransactions(accountId),
        ),
        BlocProvider(
          create: (_) => sl<AccountsCubit>(),
        ),
      ],
      child: _AccountDetailsView(accountId: accountId),
    );
  }
}

class _AccountDetailsView extends StatefulWidget {
  final String accountId;
  const _AccountDetailsView({required this.accountId});

  @override
  State<_AccountDetailsView> createState() => _AccountDetailsViewState();
}

class _AccountDetailsViewState extends State<_AccountDetailsView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final account = sl<AccountsRepo>().getAccountById(widget.accountId);

    if (account == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Account not found')),
      );
    }

    final isCreditor = account.type == AccountType.creditor;
    final formatter = NumberFormat('#,##0.##');
    final dateFormat = DateFormat('yyyy-MM-dd');

    return BlocListener<AccountsCubit, AccountsState>(
      listener: (context, state) {
        if (state is AccountDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deleteConfirm),
              backgroundColor: AppColors.creditor,
            ),
          );
          context.pop();
        } else if (state is AccountsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.debtor,
            ),
          );
        } else if (state is AccountSaved) {
          setState(() {});
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(account.name, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => _showOptions(context, l10n, account),
            ),
          ],
        ),
        body: Column(
          children: [
            // ─── Balance Header ─────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isCreditor
                    ? AppColors.creditorGradient
                    : AppColors.debtorGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCreditor ? l10n.creditor : l10n.debtor,
                    style: AppTextStyles.onDarkBody,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatter.format(account.balance.abs()),
                    style: AppTextStyles.onDarkAmountLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.currency == 'LOCAL'
                        ? l10n.localCurrency
                        : account.currency,
                    style: AppTextStyles.onDarkBody,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${account.transactionCount} ${l10n.operations}',
                    style: AppTextStyles.onDarkBody,
                  ),
                ],
              ),
            ),

            // ─── Transaction List ───────────────────────────────
            Expanded(
              child: BlocBuilder<TransactionsCubit, TransactionsState>(
                builder: (context, state) {
                  if (state is TransactionsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (state is TransactionsLoaded) {
                    if (state.transactions.isEmpty) {
                      return _buildEmpty(l10n);
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          context.read<TransactionsCubit>().loadTransactions(widget.accountId),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.transactions.length,
                        itemBuilder: (ctx, i) {
                          final tx = state.transactions[i];
                          return _TransactionItem(
                            tx: tx,
                            formatter: formatter,
                            dateFormat: dateFormat,
                            onDelete: () {
                              context.read<TransactionsCubit>().deleteTransaction(tx);
                            },
                            onTap: () {
                              context
                                  .push(AppRoutes.addTransaction(widget.accountId), extra: tx)
                                  .then((_) {
                                if (context.mounted) {
                                  context.read<TransactionsCubit>().loadTransactions(widget.accountId);
                                  setState(() {});
                                }
                              });
                            },
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context
              .push(AppRoutes.addTransaction(widget.accountId))
              .then((_) {
            if (context.mounted) {
              context.read<TransactionsCubit>().loadTransactions(widget.accountId);
              setState(() {});
            }
          }),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.iconSecondary),
          const SizedBox(height: 16),
          Text(l10n.noTransactions, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            l10n.noTransactionsSubtitle,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showOptions(
      BuildContext context, AppLocalizations l10n, AccountModel account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.phone_outlined,
                  color: AppColors.primary),
              title: Text(account.phone ?? 'No phone'),
            ),
            if (account.notes != null) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notes_rounded,
                    color: AppColors.iconPrimary),
                title: Text(account.notes!),
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: Text(l10n.editAccount),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.addAccount, extra: account).then((_) {
                  if (context.mounted) setState(() {});
                });
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.debtor),
              title: Text(l10n.deleteAccount),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAccount(context, l10n, account);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(
      BuildContext context, AppLocalizations l10n, AccountModel account) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text(l10n.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AccountsCubit>().deleteAccount(account.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debtor),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel tx;
  final NumberFormat formatter;
  final DateFormat dateFormat;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _TransactionItem({
    required this.tx,
    required this.formatter,
    required this.dateFormat,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final color = isIncome ? AppColors.creditor : AppColors.debtor;
    final icon = isIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 16),
        color: AppColors.debtorSurface,
        child: const Icon(Icons.delete_rounded, color: AppColors.debtor),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.creditorSurface
                        : AppColors.debtorSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.notes ?? (isIncome ? 'Income' : 'Expense'),
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateFormat.format(tx.date),
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'} ${formatter.format(tx.amount)}',
                  style: AppTextStyles.amountSmall.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
