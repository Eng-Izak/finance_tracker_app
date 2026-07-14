import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

/// The summary card at the top of Home screen showing:
/// - Total له (creditor)  → green
/// - Total عليه (debtor)  → orange
/// - Net balance
class SummaryCard extends StatelessWidget {
  final double creditorTotal;
  final double debtorTotal;
  final double netBalance;
  final String currency;

  const SummaryCard({
    super.key,
    required this.creditorTotal,
    required this.debtorTotal,
    required this.netBalance,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = NumberFormat('#,##0.##');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: AppColors.summaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top Row: له | عليه ─────────────────────────
            IntrinsicHeight(
              child: Row(
                children: [
                  // Creditor (له)
                  Expanded(
                    child: _SummaryItem(
                      label: l10n.totalReceivable,
                      amount: formatter.format(creditorTotal),
                      currency: currency,
                      isPositive: true,
                    ),
                  ),
                  // Vertical divider
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  // Debtor (عليه)
                  Expanded(
                    child: _SummaryItem(
                      label: l10n.totalPayable,
                      amount: formatter.format(debtorTotal),
                      currency: currency,
                      isPositive: false,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Divider ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: Colors.white.withValues(alpha: 0.2),
                height: 1,
              ),
            ),

            // ─── Balance Row ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.balance,
                  style: AppTextStyles.onDarkBody,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.format(netBalance.abs()),
                      style: AppTextStyles.onDarkAmountLarge,
                    ),
                    Text(
                      currency == 'LOCAL' ? l10n.localCurrency : currency,
                      style: AppTextStyles.onDarkBody.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final String currency;
  final bool isPositive;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.currency,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isPositive ? const Color(0xFF86EFAC) : const Color(0xFFFBBF24);
    final icon = isPositive
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.onDarkBody.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: AppTextStyles.amountMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
