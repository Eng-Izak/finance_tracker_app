import 'package:finance_tracker_app_001/core/services/local_db_backup_service.dart';
import 'package:finance_tracker_app_001/core/routing/routes.dart';
import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/core/theming/app_text_styles.dart';
import 'package:finance_tracker_app_001/features/auth/logic/auth_cubit.dart';
import 'package:finance_tracker_app_001/features/auth/logic/auth_state.dart';
import 'package:finance_tracker_app_001/features/home/logic/home_cubit.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthCubit>().state;

    String name = 'Local User';
    String email = 'local@example.com';
    String? photoUrl;

    if (authState is AuthAuthenticated) {
      name = authState.displayName;
      email = authState.email;
      photoUrl = authState.photoUrl;
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.summaryGradient,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              backgroundColor: Colors.white24,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            accountName: Text(
              name,
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
            ),
            accountEmail: Text(
              email,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: Text(l10n.home),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: Text(l10n.statistics),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.statistics);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(l10n.currencies),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.currencies);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: Text(l10n.settings),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.settings);
            },
          ),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.save_alt_rounded, color: AppColors.primary),
            title: Text(l10n.saveDatabase),
            onTap: () => _handleSaveDatabase(context, l10n),
          ),
          ListTile(
            leading:
                const Icon(Icons.restore_rounded, color: AppColors.primary),
            title: Text(l10n.restoreDatabase),
            onTap: () => _handleRestoreDatabase(context, l10n),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.debtor),
            title: Text(
              l10n.logout,
              style: const TextStyle(color: AppColors.debtor),
            ),
            onTap: () => _handleSignOut(context, l10n),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleSaveDatabase(
      BuildContext context, AppLocalizations l10n) async {
    Navigator.pop(context); // Close drawer first
    try {
      final success = await LocalDbBackupService.saveDatabase();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveDatabaseSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.debtor,
          ),
        );
      }
    }
  }

  Future<void> _handleRestoreDatabase(
      BuildContext context, AppLocalizations l10n) async {
    Navigator.pop(context); // Close drawer first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreDatabase),
        content: Text(l10n.restoreDatabaseConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debtor),
            child: Text(l10n.restoreDatabase),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        final success = await LocalDbBackupService.restoreDatabase();
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.restoreDatabaseSuccess),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the home screen data after restore
          if (context.mounted) {
            context.read<HomeCubit>().refresh();
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: AppColors.debtor,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSignOut(
      BuildContext context, AppLocalizations l10n) async {
    Navigator.pop(context); // Close drawer first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debtor),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthCubit>().signOut();
    }
  }
}
