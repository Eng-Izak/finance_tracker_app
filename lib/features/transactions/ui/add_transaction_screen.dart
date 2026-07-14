import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import '../../../core/dependency_injection/service_locator.dart';
import '../../../core/shared/enums/transaction_type.dart';
import '../../../core/shared/models/transaction_model.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/theming/app_text_styles.dart';
import '../logic/transactions_cubit.dart';
import '../logic/transactions_state.dart';

class AddTransactionScreen extends StatefulWidget {
  final String accountId;
  final TransactionModel? transaction;

  const AddTransactionScreen({
    super.key,
    required this.accountId,
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  TransactionType _type = TransactionType.income;
  DateTime _date = DateTime.now();
  DateTime? _reminderAt;
  final String _currency = 'LOCAL';
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountCtrl.text = widget.transaction!.amount.toString();
      _notesCtrl.text = widget.transaction!.notes ?? '';
      _type = widget.transaction!.type;
      _date = widget.transaction!.date;
      _reminderAt = widget.transaction!.reminderAt;
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

    return BlocProvider(
      create: (_) => sl<TransactionsCubit>(),
      child: BlocConsumer<TransactionsCubit, TransactionsState>(
        listener: (context, state) {
          if (state is TransactionSaved) context.pop();
          if (state is TransactionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.debtor),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is TransactionsLoading;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => context.pop(),
              ),
              title: Text(widget.transaction != null ? l10n.editTransaction : l10n.addTransaction),
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ─── Type Toggle ────────────────────────────
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

                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          // Amount
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.calculate_outlined,
                                    color: AppColors.iconSecondary, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      labelText: l10n.amount,
                                      border: InputBorder.none,
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16),
                                    ),
                                    validator: (v) {
                                      final n = double.tryParse(
                                          v?.replaceAll(',', '') ?? '');
                                      if (n == null || n <= 0) {
                                        return 'Enter valid amount';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, indent: 52, endIndent: 16),

                          // Date
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
                                  const Icon(Icons.calendar_today_outlined,
                                      color: AppColors.iconSecondary,
                                      size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Text(_dateFormat.format(_date),
                                          style: AppTextStyles.bodyMedium),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.iconSecondary),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 52, endIndent: 16),

                          // Notes
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.notes_rounded,
                                    color: AppColors.iconSecondary, size: 22),
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

                          // Reminder
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
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: _reminderAt != null
                                              ? AppColors.primary
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_reminderAt != null)
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 18, color: AppColors.debtor),
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

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _save(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _type == TransactionType.income
                                  ? AppColors.creditor
                                  : AppColors.debtor,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(l10n.save,
                                style: AppTextStyles.buttonLarge),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
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
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;

    if (widget.transaction != null) {
      context.read<TransactionsCubit>().updateTransaction(
            tx: widget.transaction!,
            amount: amount,
            type: _type,
            date: _date,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            reminderAt: _reminderAt,
          );
    } else {
      context.read<TransactionsCubit>().addTransaction(
            accountId: widget.accountId,
            amount: amount,
            currency: _currency,
            type: _type,
            date: _date,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            reminderAt: _reminderAt,
          );
    }
  }
}
