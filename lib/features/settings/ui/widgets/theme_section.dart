import 'package:finance_tracker_app_001/app/finance_app.dart';
import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/features/settings/logic/settings_cubit.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeSection extends StatelessWidget {
  final String currentTheme;

  const ThemeSection({super.key, required this.currentTheme});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RadioGroup<String>(
      groupValue: currentTheme,
      onChanged: (v) {
        if (v != null) {
          final themeMode = switch (v) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
          FinanceApp.setTheme(context, themeMode);
          context.read<SettingsCubit>().changeTheme(v);
        }
      },
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text(l10n.lightTheme),
            value: 'light',
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1, indent: 56),
          RadioListTile<String>(
            title: Text(l10n.darkTheme),
            value: 'dark',
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1, indent: 56),
          RadioListTile<String>(
            title: Text(l10n.systemTheme),
            value: 'system',
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
