import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/shared/models/account_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../transactions/ui/widgets/quick_add_transaction_bottom_sheet.dart';
import '../../logic/home_cubit.dart';

class NewTransactionButton extends StatelessWidget {
  final List<AccountModel> accounts;

  const NewTransactionButton({
    super.key,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextButton.icon(
      onPressed: () => _onPressed(context),
      icon: const Icon(Icons.add_chart_rounded, size: 18),
      label: Text(l10n.addTransaction),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.creditor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: AppColors.creditorSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppColors.creditorBorder, width: 1),
      ),
    );
  }

  void _onPressed(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى إضافة حساب أولاً قبل تسجيل أي معاملة.'
                : 'Please add an account first before logging any transaction.',
          ),
          backgroundColor: AppColors.debtor,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddTransactionBottomSheet(accounts: accounts),
    ).then((_) {
      if (context.mounted) {
        context.read<HomeCubit>().refresh();
      }
    });
  }
}
