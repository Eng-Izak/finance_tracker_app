import 'package:finance_tracker_app_001/core/routing/routes.dart';
import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/core/theming/app_text_styles.dart';
import 'package:finance_tracker_app_001/features/auth/logic/auth_cubit.dart';
import 'package:finance_tracker_app_001/features/auth/logic/auth_state.dart';
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

  Future<void> _handleSignOut(
      BuildContext context, AppLocalizations l10n) async {
    Navigator.pop(context); // إغلاق الـ Drawer أولاً
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
