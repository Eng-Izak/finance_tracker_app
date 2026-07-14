import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/dependency_injection/service_locator.dart';
import '../../../core/routing/routes.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/theming/app_text_styles.dart';
import '../logic/auth_cubit.dart';
import '../logic/auth_state.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            final biometricService = sl<BiometricService>();
            if (biometricService.isPinEnabled) {
              context.go(AppRoutes.pinLock);
            } else {
              context.go(AppRoutes.home);
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.debtor,
              ),
            );
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: size.height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // ─── Logo / Illustration ─────────────
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ─── Title ───────────────────────────
                        Text(
                          l10n.welcomeBack,
                          style: AppTextStyles.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.loginSubtitle,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(flex: 3),

                        // ─── Google Sign In Button ────────────
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isLoading
                              ? _buildLoadingButton(l10n)
                              : _buildGoogleButton(context, l10n),
                        ),

                        const SizedBox(height: 12),

                        // ─── Offline Use Button ────────────────
                        if (!isLoading)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () =>
                                  context.read<AuthCubit>().signInOffline(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'استخدام بدون إنترنت (محلي) / Use Offline',
                                style: AppTextStyles.buttonLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // ─── Terms ───────────────────────────
                        Text(
                          'By signing in, you agree to our Terms & Privacy Policy',
                          style: AppTextStyles.labelSmall,
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      key: const ValueKey('google_btn'),
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () =>
            context.read<AuthCubit>().signInWithGoogle(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google icon (using a simple colored G)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.g_mobiledata_rounded,
                  color: Color(0xFF4285F4), size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.signInWithGoogle,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingButton(AppLocalizations l10n) {
    return SizedBox(
      key: const ValueKey('loading_btn'),
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surfaceVariant,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.signingIn,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
