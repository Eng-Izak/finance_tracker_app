import 'package:finance_tracker_app_001/core/routing/routes.dart';
import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/core/theming/app_text_styles.dart';
import 'package:finance_tracker_app_001/core/utils/constants/app_constants.dart';
import 'package:finance_tracker_app_001/features/auth/logic/auth_cubit.dart';
import 'package:finance_tracker_app_001/features/auth/logic/auth_state.dart';
import 'package:finance_tracker_app_001/features/settings/logic/settings_cubit.dart';
import 'package:finance_tracker_app_001/features/settings/logic/settings_state.dart';
import 'package:finance_tracker_app_001/features/settings/ui/widgets/language_section.dart';
import 'package:finance_tracker_app_001/features/settings/ui/widgets/profile_card.dart';
import 'package:finance_tracker_app_001/features/settings/ui/widgets/settings_section.dart';
import 'package:finance_tracker_app_001/features/settings/ui/widgets/theme_section.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state is SettingsLoggedOut) {
          context.go(AppRoutes.login);
        }
        if (state is SettingsUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.creditor,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settings),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is! SettingsLoaded) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }

            return BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ─── Profile ──────────────────────────────
                    if (authState is AuthAuthenticated) ...[
                      ProfileCard(auth: authState),
                      const SizedBox(height: 16),
                    ],

                    // ─── Language ─────────────────────────────
                    SettingsSection(
                      title: l10n.language,
                      children: [
                        LanguageSection(currentLang: state.language),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ─── Theme ────────────────────────────────
                    SettingsSection(
                      title: l10n.theme,
                      children: [
                        ThemeSection(currentTheme: state.theme),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ─── Security ────────────────────────────
                    SettingsSection(
                      title: l10n.security,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.pin_outlined),
                          title: Text(l10n.pinCode),
                          subtitle:
                              Text(state.isPinEnabled ? 'Enabled' : 'Disabled'),
                          trailing: TextButton(
                            onPressed: () => state.isPinEnabled
                                ? context.read<SettingsCubit>().disablePin()
                                : context.push(AppRoutes.pinSetup),
                            child: Text(
                                state.isPinEnabled ? l10n.delete : 'Setup'),
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile(
                          secondary: const Icon(Icons.fingerprint_rounded),
                          title: Text(l10n.biometric),
                          value: state.isBiometricEnabled,
                          onChanged: (v) =>
                              context.read<SettingsCubit>().toggleBiometric(v),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ─── Cloud Backup ─────────────────────────
                    SettingsSection(
                      title: l10n.cloudBackup,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.cloud_sync_rounded),
                          title: Text(l10n.syncNow),
                          subtitle: state.lastSync != null
                              ? Text(
                                  '${l10n.lastSync}: ${state.lastSync!.substring(0, 10)}')
                              : null,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              context.read<SettingsCubit>().syncToCloud(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ─── Export ──────────────────────────────
                    SettingsSection(
                      title: l10n.exportData,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.picture_as_pdf_rounded),
                          title: Text(l10n.exportPdf),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              context.read<SettingsCubit>().exportToPdf(),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.table_chart_rounded),
                          title: Text(l10n.exportCsv),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              context.read<SettingsCubit>().exportToCsv(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ─── Currencies ───────────────────────────
                    SettingsSection(
                      title: l10n.currencies,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.currency_exchange_rounded),
                          title: Text(l10n.currencies),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(AppRoutes.currencies),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ─── Logout ──────────────────────────────
                    SettingsSection(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout_rounded,
                              color: AppColors.debtor),
                          title: Text(l10n.logout,
                              style: TextStyle(color: AppColors.debtor)),
                          onTap: () => _confirmLogout(context, l10n),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: Text(
                        '${l10n.appVersion} ${AppConstants.appVersion}',
                        style: AppTextStyles.labelSmall,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debtor),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final authCubit = context.read<AuthCubit>();
      context.read<SettingsCubit>().logout(() => authCubit.signOut());
    }
  }
}
