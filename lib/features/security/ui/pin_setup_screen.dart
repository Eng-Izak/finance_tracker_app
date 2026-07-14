import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import '../../../core/dependency_injection/service_locator.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/theming/app_text_styles.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../logic/security_cubit.dart';
import '../logic/security_state.dart';
import 'widgets/pin_input_display.dart';
import 'widgets/pin_numpad.dart';

class PinSetupScreen extends StatelessWidget {
  const PinSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => SecurityCubit(biometricService: sl())
        ..startPinSetup(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
        body: BlocConsumer<SecurityCubit, SecurityState>(
          listener: (context, state) {
            if (state is SecurityPinSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.pinSetupSuccess),
                  backgroundColor: AppColors.creditor,
                ),
              );
              context.go(AppRoutes.settings);
            }
          },
          builder: (context, state) {
            final cubit = context.read<SecurityCubit>();
            final isConfirmStep = state is SecurityPinSetupConfirm;

            final entered = state is SecurityPinEntry
                ? state.entered
                : state is SecurityPinSetupConfirm
                    ? state.confirmPin
                    : '';
            final hasError =
                state is SecurityPinSetupConfirm && state.hasError;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ─── Icon ─────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        isConfirmStep
                            ? Icons.lock_outline_rounded
                            : Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 24),

                    AnimatedSwitcher(
                      duration: AppConstants.animFast,
                      child: Column(
                        key: ValueKey(isConfirmStep),
                        children: [
                          Text(
                            isConfirmStep
                                ? l10n.confirmPin
                                : l10n.setupPin,
                            style: AppTextStyles.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isConfirmStep
                                ? (hasError
                                    ? l10n.pinsMustMatch
                                    : l10n.confirmPinSubtitle)
                                : l10n.createPinSubtitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: hasError
                                  ? AppColors.debtor
                                  : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    PinInputDisplay(
                      entered: entered,
                      pinLength: AppConstants.pinLength,
                      hasError: hasError,
                    ),

                    const Spacer(),

                    PinNumpad(
                      onDigit: (digit) {
                        cubit.addDigit(digit);

                        // Auto-submit when PIN is complete
                        final currentState = cubit.state;
                        if (currentState is SecurityPinEntry &&
                            (currentState.entered + digit).length ==
                                AppConstants.pinLength) {
                          Future.delayed(
                              const Duration(milliseconds: 150), () {
                            cubit.confirmFirstPin(
                                currentState.entered + digit);
                          });
                        } else if (currentState is SecurityPinSetupConfirm &&
                            (currentState.confirmPin + digit).length ==
                                AppConstants.pinLength) {
                          Future.delayed(
                              const Duration(milliseconds: 150), () {
                            cubit.savePin();
                          });
                        }
                      },
                      onDelete: cubit.removeDigit,
                      onSubmit: () {
                        if (isConfirmStep) {
                          cubit.savePin();
                        } else {
                          final s = cubit.state;
                          if (s is SecurityPinEntry) {
                            cubit.confirmFirstPin(s.entered);
                          }
                        }
                      },
                      showBiometric: false,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
