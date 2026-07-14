import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import '../../../core/dependency_injection/service_locator.dart';
import '../../../core/shared/enums/account_type.dart';
import '../../../core/shared/models/currency_model.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/shared/models/account_model.dart';
import '../../../core/theming/app_text_styles.dart';
import '../logic/accounts_cubit.dart';
import '../logic/accounts_state.dart';

class AddAccountScreen extends StatefulWidget {
  final AccountModel? account;
  const AddAccountScreen({super.key, this.account});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  AccountType _selectedType = AccountType.debtor;
  String _selectedCurrency = 'LOCAL';
  DateTime _selectedDate = DateTime.now();

  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameCtrl.text = widget.account!.name;
      _amountCtrl.text = widget.account!.openingBalance.toString();
      _phoneCtrl.text = widget.account!.phone ?? '';
      _notesCtrl.text = widget.account!.notes ?? '';
      _selectedType = widget.account!.type;
      _selectedCurrency = widget.account!.currency;
      _selectedDate = widget.account!.createdAt;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencies = CurrencyModel.defaults;

    return BlocProvider(
      create: (_) => sl<AccountsCubit>(),
      child: BlocConsumer<AccountsCubit, AccountsState>(
        listener: (context, state) {
          if (state is AccountSaved) {
            context.pop();
          } else if (state is AccountsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.debtor,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AccountsLoading;

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.account != null ? l10n.editAccount : l10n.addAccount),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCard(
                      children: [
                        // ─── Account Name ──────────────────────
                        _buildField(
                          controller: _nameCtrl,
                          label: l10n.accountName,
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                        _divider(),

                        if (widget.account == null) ...[
                          // ─── Amount ───────────────────────────
                          _buildField(
                            controller: _amountCtrl,
                            label: l10n.amount,
                            icon: Icons.calculate_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                          _divider(),
                        ],

                        // ─── Currency ─────────────────────────
                        _buildDropdown<String>(
                          label: l10n.currency,
                          icon: Icons.language_rounded,
                          value: _selectedCurrency,
                          items: currencies
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.code,
                                  child: Text('${c.code}  ${c.symbol}'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCurrency = v!),
                        ),
                        _divider(),

                        if (widget.account == null) ...[
                          // ─── Date ─────────────────────────────
                          _buildDateField(context, l10n),
                          _divider(),
                        ],

                        // ─── Notes ────────────────────────────
                        _buildField(
                          controller: _notesCtrl,
                          label: l10n.details,
                          icon: Icons.notes_rounded,
                          maxLines: 2,
                        ),
                        _divider(),

                        // ─── Phone ───────────────────────────
                        _buildField(
                          controller: _phoneCtrl,
                          label: l10n.phoneNumber,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        _divider(),

                        // ─── Account Type Toggle ──────────────
                        _buildTypeToggle(l10n),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ─── Save Button ──────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _save(context),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.saveAccount,
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

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.iconSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              validator: validator,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.iconSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<T>(
              initialValue: value,
              items: items,
              onChanged: onChanged,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 22, color: AppColors.iconSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.date,
                              style: AppTextStyles.labelMedium),
                          const SizedBox(height: 4),
                          Text(_dateFormat.format(_selectedDate),
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.iconSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.accountType, style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  label: l10n.debtor,
                  isSelected: _selectedType == AccountType.debtor,
                  selectedColor: AppColors.debtor,
                  selectedBg: AppColors.debtorSurface,
                  onTap: () =>
                      setState(() => _selectedType = AccountType.debtor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  label: l10n.creditor,
                  isSelected: _selectedType == AccountType.creditor,
                  selectedColor: AppColors.creditor,
                  selectedBg: AppColors.creditorSurface,
                  onTap: () =>
                      setState(() => _selectedType = AccountType.creditor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 52, endIndent: 16);
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    if (widget.account != null) {
      context.read<AccountsCubit>().updateAccount(
            id: widget.account!.id,
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            type: _selectedType,
            currency: _selectedCurrency,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
    } else {
      final amount =
          double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;

      context.read<AccountsCubit>().createAccount(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            type: _selectedType,
            openingBalance: amount,
            currency: _selectedCurrency,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBg;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? selectedColor : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: isSelected ? selectedColor : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
