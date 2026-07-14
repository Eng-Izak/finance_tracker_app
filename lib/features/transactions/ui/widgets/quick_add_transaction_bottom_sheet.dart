import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/dependency_injection/service_locator.dart';
import '../../../../core/shared/enums/transaction_type.dart';
import '../../../../core/shared/models/account_model.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../logic/transactions_cubit.dart';
import '../../logic/transactions_state.dart';

class QuickAddTransactionBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;

  const QuickAddTransactionBottomSheet({
    super.key,
    required this.accounts,
  });

  @override
  State<QuickAddTransactionBottomSheet> createState() =>
      _QuickAddTransactionBottomSheetState();
}

class _QuickAddTransactionBottomSheetState
    extends State<QuickAddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedAccountId;
  TransactionType _type = TransactionType.income;
  DateTime _date = DateTime.now();
  DateTime? _reminderAt;
  final String _currency = 'LOCAL';
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _selectedAccountId = widget.accounts.first.id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocProvider(
      create: (_) => sl<TransactionsCubit>(),
      child: BlocConsumer<TransactionsCubit, TransactionsState>(
        listener: (context, state) {
          if (state is TransactionSaved) {
            Navigator.pop(context);
          }
          if (state is TransactionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.debtor,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is TransactionsLoading;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar for drag-to-dismiss
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bottom Sheet Title
                      Text(
                        l10n.addTransaction,
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 20),

                      // Income/Expense Switcher
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: _typeButton(
                                label: l10n.income,
                                type: TransactionType.income,
                                color: AppColors.creditor,
                              ),
                            ),
                            Expanded(
                              child: _typeButton(
                                label: l10n.expense,
                                type: TransactionType.expense,
                                color: AppColors.debtor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Main Form Card
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            // Account Selector Dropdown
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: AppColors.iconSecondary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedAccountId,
                                      decoration: InputDecoration(
                                        labelText:
                                            isArabic ? 'الحساب' : 'Account',
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8),
                                      ),
                                      onChanged: (val) {
                                        setState(
                                            () => _selectedAccountId = val);
                                      },
                                      validator: (val) => val == null
                                          ? (isArabic
                                              ? 'يرجى اختيار حساب'
                                              : 'Please select an account')
                                          : null,
                                      items: widget.accounts.map((acc) {
                                        return DropdownMenuItem<String>(
                                          value: acc.id,
                                          child: Text(
                                            acc.name,
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, indent: 52, endIndent: 16),

                            // Amount Input
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calculate_outlined,
                                    color: AppColors.iconSecondary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _amountCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                        labelText: l10n.amount,
                                        hintText: '0',
                                        border: InputBorder.none,
                                        filled: false,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 16),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      validator: (v) {
                                        final n = double.tryParse(
                                            v?.replaceAll(',', '') ?? '');
                                        if (n == null || n <= 0) {
                                          return isArabic
                                              ? 'أدخل مبلغاً صالحاً'
                                              : 'Enter valid amount';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, indent: 52, endIndent: 16),

                            // Date Picker
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() => _date = picked);
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      color: AppColors.iconSecondary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        child: Text(
                                          _dateFormat.format(_date),
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.iconSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1, indent: 52, endIndent: 16),

                            // Notes Input
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notes_rounded,
                                    color: AppColors.iconSecondary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _notesCtrl,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        labelText: l10n.notes,
                                        border: InputBorder.none,
                                        filled: false,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, indent: 52, endIndent: 16),

                            // Reminder Option
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now()
                                        .add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() => _reminderAt = picked);
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notifications_outlined,
                                      color: _reminderAt != null
                                          ? AppColors.primary
                                          : AppColors.iconSecondary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        child: Text(
                                          _reminderAt != null
                                              ? _dateFormat.format(_reminderAt!)
                                              : l10n.setReminder,
                                          style:
                                              AppTextStyles.bodyMedium.copyWith(
                                            color: _reminderAt != null
                                                ? AppColors.primary
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_reminderAt != null)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: AppColors.debtor,
                                        ),
                                        onPressed: () =>
                                            setState(() => _reminderAt = null),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _save(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _type == TransactionType.income
                                ? AppColors.creditor
                                : AppColors.debtor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  l10n.save,
                                  style: AppTextStyles.buttonLarge,
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _typeButton({
    required String label,
    required TransactionType type,
    required Color color,
  }) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.titleSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;

    context.read<TransactionsCubit>().addTransaction(
          accountId: _selectedAccountId!,
          amount: amount,
          currency: _currency,
          type: _type,
          date: _date,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          reminderAt: _reminderAt,
        );
  }
}
