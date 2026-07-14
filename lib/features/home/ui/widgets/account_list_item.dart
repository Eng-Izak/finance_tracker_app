import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import '../../../../core/shared/enums/account_type.dart';
import '../../../../core/shared/models/account_model.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

/// A single account row in the home screen list,
/// matching the Figma design layout.
class AccountListItem extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const AccountListItem({
    super.key,
    required this.account,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCreditor = account.type == AccountType.creditor;
    final formatter = NumberFormat('#,##0.##');

    final typeColor =
        isCreditor ? AppColors.creditor : AppColors.debtor;
    final typeBgColor =
        isCreditor ? AppColors.creditorSurface : AppColors.debtorSurface;
    final arrowIcon = isCreditor
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        color: AppColors.debtorSurface,
        child: const Icon(Icons.delete_rounded, color: AppColors.debtor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ─── Avatar ────────────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    account.name.isNotEmpty
                        ? account.name.characters.first.toUpperCase()
                        : '?',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ─── Name + Operations ─────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${account.transactionCount} ${l10n.operations}',
                      style: AppTextStyles.labelMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ─── Amount + Arrow ────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(account.balance.abs()),
                    style: AppTextStyles.amountSmall.copyWith(
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: typeBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(arrowIcon, color: typeColor, size: 14),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // ─── Edit Button ──────────────────────────────
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.iconPrimary,
                  size: 20,
                ),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
