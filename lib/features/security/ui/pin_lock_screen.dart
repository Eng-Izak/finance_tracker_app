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

class PinLockScreen extends StatelessWidget {
  const PinLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => SecurityCubit(biometricService: sl())
        ..startPinEntry(),
      child: Scaffold(
        body: BlocConsumer<SecurityCubit, SecurityState>(
          listener: (context, state) {
            if (state is SecurityUnlocked) {
              context.go(AppRoutes.home);
            }
          },
          builder: (context, state) {
            final cubit = context.read<SecurityCubit>();
            final entered = state is SecurityPinEntry ? state.entered : '';
            final hasError = state is SecurityPinEntry && state.hasError;
            final attempts = state is SecurityPinEntry ? state.attempts : 0;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // ─── Icon ────────────────────────────────
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
                      child: const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 40),
                    ),

                    const SizedBox(height: 24),

                    Text(l10n.enterPin,
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      attempts > 0
                          ? '${l10n.wrongPin} ($attempts)'
                          : l10n.useBiometric,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: hasError
                            ? AppColors.debtor
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // ─── PIN dots ────────────────────────────
                    PinInputDisplay(
                      entered: entered,
                      pinLength: AppConstants.pinLength,
                      hasError: hasError,
                    ),

                    const Spacer(flex: 2),

                    // ─── Numpad ──────────────────────────────
                    PinNumpad(
                      onDigit: cubit.addDigit,
                      onDelete: cubit.removeDigit,
                      onSubmit: () async {
                        await cubit.verifyPin();
                      },
                      showBiometric: cubit.isBiometricEnabled,
                      onBiometric: () async {
                        await cubit.authenticateWithBiometric(
                            l10n.biometricPrompt);
                      },
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
