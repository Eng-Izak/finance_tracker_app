import 'package:finance_tracker_app_001/app/finance_app.dart';
import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/features/settings/logic/settings_cubit.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageSection extends StatelessWidget {
  final String currentLang;

  const LanguageSection({super.key, required this.currentLang});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RadioGroup<String>(
      groupValue: currentLang,
      onChanged: (v) {
        if (v != null) {
          FinanceApp.setLocale(context, Locale(v));
          context.read<SettingsCubit>().loadSettings();
        }
      },
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text(l10n.arabic),
            value: 'ar',
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1, indent: 56),
          RadioListTile<String>(
            title: Text(l10n.english),
            value: 'en',
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
