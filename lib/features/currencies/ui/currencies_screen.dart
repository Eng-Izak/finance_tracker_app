import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import '../../../core/dependency_injection/service_locator.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/theming/app_text_styles.dart';
import '../logic/currencies_cubit.dart';
import '../logic/currencies_state.dart';

class CurrenciesScreen extends StatelessWidget {
  const CurrenciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CurrenciesCubit(exchangeRateService: sl())
        ..loadCurrencies(),
      child: const _CurrenciesView(),
    );
  }
}

class _CurrenciesView extends StatelessWidget {
  const _CurrenciesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = NumberFormat('#,##0.####');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.currencies),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<CurrenciesCubit, CurrenciesState>(
        builder: (context, state) {
          if (state is CurrenciesLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is CurrenciesLoaded) {
            final currencies = state.currencies;
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<CurrenciesCubit>().refreshRates(),
              child: Column(
                children: [
                  // ─── Refresh status bar ─────────────────────
                  if (state.isRefreshing)
                    const LinearProgressIndicator(
                        color: AppColors.primary),

                  // ─── Info banner ─────────────────────────────
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rates from frankfurter.app • Base: USD',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Currency List ──────────────────────────
                  Expanded(
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: currencies.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = currencies[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              // Symbol
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  c.symbol,
                                  style:
                                      AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(c.code,
                                        style:
                                            AppTextStyles.titleMedium),
                                    Text(c.nameAr,
                                        style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                              // Rate
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatter.format(c.rateToBase),
                                    style: AppTextStyles.amountSmall
                                        .copyWith(
                                            color: AppColors.primary),
                                  ),
                                  Text(
                                    'per USD',
                                    style: AppTextStyles.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
