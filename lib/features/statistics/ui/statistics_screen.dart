import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import '../../../core/dependency_injection/service_locator.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/theming/app_text_styles.dart';
import '../logic/statistics_cubit.dart';
import '../logic/statistics_state.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StatisticsCubit(
        transactionsRepo: sl(),
      )..loadStatistics(),
      child: const _StatisticsView(),
    );
  }
}

class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = NumberFormat('#,##0.##');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statistics),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          if (state is StatisticsLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is StatisticsLoaded) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Summary Cards ───────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: l10n.totalIncome,
                        amount: formatter.format(state.totalIncome),
                        color: AppColors.creditor,
                        bgColor: AppColors.creditorSurface,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: l10n.totalExpense,
                        amount: formatter.format(state.totalExpense),
                        color: AppColors.debtor,
                        bgColor: AppColors.debtorSurface,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _StatCard(
                  label: l10n.netBalance,
                  amount: formatter.format(state.netBalance),
                  color: AppColors.primary,
                  bgColor: AppColors.primarySurface,
                  icon: Icons.account_balance_rounded,
                  isFullWidth: true,
                ),

                const SizedBox(height: 24),

                // ─── Pie Chart ─────────────────────────────
                Text(l10n.incomeVsExpense,
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),

                _buildPieChart(state),

                const SizedBox(height: 24),

                // ─── Bar Chart ────────────────────────────
                Text(l10n.monthly, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),

                _buildBarChart(context, state),

                const SizedBox(height: 32),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPieChart(StatisticsLoaded state) {
    final total = state.totalIncome + state.totalExpense;
    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(
            child: Text('No data', style: AppTextStyles.bodyMedium)),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: state.totalIncome,
                    color: AppColors.creditor,
                    title:
                        '${(state.totalIncome / total * 100).toStringAsFixed(1)}%',
                    titleStyle: AppTextStyles.labelSmall
                        .copyWith(color: Colors.white),
                    radius: 55,
                  ),
                  PieChartSectionData(
                    value: state.totalExpense,
                    color: AppColors.debtor,
                    title:
                        '${(state.totalExpense / total * 100).toStringAsFixed(1)}%',
                    titleStyle: AppTextStyles.labelSmall
                        .copyWith(color: Colors.white),
                    radius: 55,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Legend(color: AppColors.creditor, label: 'Income'),
                const SizedBox(height: 12),
                _Legend(color: AppColors.debtor, label: 'Expense'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, StatisticsLoaded state) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final bars = state.monthlyData.entries.map((e) {
      return BarChartGroupData(
        x: e.key - 1,
        barRods: [
          BarChartRodData(
            toY: e.value.income,
            color: AppColors.creditor,
            width: 6,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: e.value.expense,
            color: AppColors.debtor,
            width: 6,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: bars,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= 12) {
                    return const SizedBox.shrink();
                  }
                  return Text(months[idx],
                      style: AppTextStyles.labelSmall);
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final bool isFullWidth;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.bgColor,
    required this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.labelMedium,
                    overflow: TextOverflow.ellipsis),
                Text(amount,
                    style: AppTextStyles.amountSmall
                        .copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
