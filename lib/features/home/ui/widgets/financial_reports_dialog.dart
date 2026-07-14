import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/dependency_injection/service_locator.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/shared/repos/accounts_repo.dart';
import '../../../../core/shared/repos/transactions_repo.dart';
import '../../../../core/shared/models/account_model.dart';
import '../../../../core/shared/models/transaction_model.dart';
import '../../../../core/shared/enums/account_type.dart';
import '../../../../core/shared/enums/transaction_type.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

class FinancialReportsDialog extends StatefulWidget {
  final String? preselectedAccountId;
  final String? preselectedSearchQuery;

  const FinancialReportsDialog({
    super.key,
    this.preselectedAccountId,
    this.preselectedSearchQuery,
  });

  static void show(BuildContext context, {String? preselectedAccountId, String? preselectedSearchQuery}) {
    showDialog(
      context: context,
      builder: (ctx) => FinancialReportsDialog(
        preselectedAccountId: preselectedAccountId,
        preselectedSearchQuery: preselectedSearchQuery,
      ),
    );
  }

  @override
  State<FinancialReportsDialog> createState() => _FinancialReportsDialogState();
}

class _FinancialReportsDialogState extends State<FinancialReportsDialog> {
  int _reportType = 1; // Default: Total Amounts
  bool _filterByDate = false;
  bool _enableSorting = false;
  
  DateTime? _startDate;
  DateTime? _endDate;
  
  String? _selectedAccountId;
  String _selectedCategory = 'all'; // all, income, expense, creditor, debtor, custom
  final _customCategoryController = TextEditingController();
  String _sortBy = 'newest'; // newest, oldest, highest, lowest

  late List<AccountModel> _accounts;
  late List<TransactionModel> _transactions;
  bool _isLoadingData = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.preselectedAccountId;
    if (_selectedAccountId != null) {
      _reportType = 2; // Detailed account statement
    } else {
      _reportType = 1; // General total balances
    }
    if (widget.preselectedSearchQuery != null && widget.preselectedSearchQuery!.isNotEmpty) {
      _reportType = 2;
      _selectedCategory = 'custom';
      _customCategoryController.text = widget.preselectedSearchQuery!;
    }
    _loadData();
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  void _loadData() {
    try {
      _accounts = sl<AccountsRepo>().getAllAccounts();
      _transactions = sl<TransactionsRepo>().getAllTransactions();
    } catch (_) {
      _accounts = [];
      _transactions = [];
    }
    setState(() {
      _isLoadingData = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // ─── Filtered Data to Pass ──────────────────────────────────
  List<AccountModel> _getFilteredAccounts() {
    if (_reportType != 1 && _selectedAccountId != null && _selectedAccountId != 'all') {
      return _accounts.where((a) => a.id == _selectedAccountId).toList();
    }
    return _accounts;
  }

  List<TransactionModel> _getFilteredTransactions() {
    var list = List<TransactionModel>.from(_transactions);

    // 1. Filter by Account
    if (_reportType != 1 && _selectedAccountId != null && _selectedAccountId != 'all') {
      list = list.where((t) => t.accountId == _selectedAccountId).toList();
    }

    // 2. Filter by Date range
    if (_filterByDate) {
      if (_startDate != null) {
        list = list.where((t) => t.date.isAfter(_startDate!.subtract(const Duration(seconds: 1)))).toList();
      }
      if (_endDate != null) {
        list = list.where((t) => t.date.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
      }
    }

    // 3. Filter by Category/Type
    if (_reportType == 5 || _reportType == 4) {
      if (_selectedCategory == 'income') {
        list = list.where((t) => t.type == TransactionType.income).toList();
      } else if (_selectedCategory == 'expense') {
        list = list.where((t) => t.type == TransactionType.expense).toList();
      } else if (_selectedCategory == 'creditor') {
        final credIds = _accounts.where((a) => a.type == AccountType.creditor).map((a) => a.id).toSet();
        list = list.where((t) => credIds.contains(t.accountId)).toList();
      } else if (_selectedCategory == 'debtor') {
        final debtIds = _accounts.where((a) => a.type == AccountType.debtor).map((a) => a.id).toSet();
        list = list.where((t) => debtIds.contains(t.accountId)).toList();
      } else if (_selectedCategory == 'custom' && _customCategoryController.text.isNotEmpty) {
        final keyword = _customCategoryController.text.trim().toLowerCase();
        list = list.where((t) => t.notes?.toLowerCase().contains(keyword) ?? false).toList();
      }
    }

    // 4. Sorting
    if (_enableSorting) {
      if (_sortBy == 'newest') {
        list.sort((a, b) => b.date.compareTo(a.date));
      } else if (_sortBy == 'oldest') {
        list.sort((a, b) => a.date.compareTo(b.date));
      } else if (_sortBy == 'highest') {
        list.sort((a, b) => b.amount.compareTo(a.amount));
      } else if (_sortBy == 'lowest') {
        list.sort((a, b) => a.amount.compareTo(b.amount));
      }
    }

    return list;
  }

  Future<void> _handleExport({required String format, bool isShare = false}) async {
    setState(() {
      _isExporting = true;
    });

    final filteredTxs = _getFilteredTransactions();
    final filteredAccs = _getFilteredAccounts();
    final catFilter = _selectedCategory == 'custom' ? _customCategoryController.text : _selectedCategory;

    final isAr = mounted && Localizations.localeOf(context).languageCode == 'ar';

    String? path;
    if (format == 'pdf') {
      path = await sl<ExportService>().generateCustomPdfReport(
        reportType: _reportType,
        accounts: filteredAccs,
        transactions: filteredTxs,
        startDate: _filterByDate ? _startDate : null,
        endDate: _filterByDate ? _endDate : null,
        categoryFilter: catFilter,
        isShare: isShare,
        isArabic: isAr,
      );
    } else {
      path = await sl<ExportService>().generateCustomCsvReport(
        reportType: _reportType,
        accounts: filteredAccs,
        transactions: filteredTxs,
        startDate: _filterByDate ? _startDate : null,
        endDate: _filterByDate ? _endDate : null,
        categoryFilter: catFilter,
        isShare: isShare,
      );
    }

    setState(() {
      _isExporting = false;
    });

    if (mounted) {
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم توليد التقرير وحفظه بنجاح!'
                  : 'Report generated and saved successfully!',
            ),
            backgroundColor: AppColors.creditor,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'حدث خطأ أثناء تصدير التقرير.'
                  : 'Error exporting report.',
            ),
            backgroundColor: AppColors.debtor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String ar, String en) => isAr ? ar : en;

    final dateFormat = DateFormat('yyyy-MM-dd');

    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.analytics_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tr('تخصيص التقارير المالية', 'Financial Reports'),
                      style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.iconSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),

                // ─── Report Type Selector ────────────────────────────
                Text(
                  tr('نوع التقرير المطلـوب:', 'Choose Report Type:'),
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                if (widget.preselectedAccountId != null) ...[
                  _buildReportTypeRadio(2, tr('تقرير كشف الحساب', 'Account Statement')),
                  _buildReportTypeRadio(3, tr('تقرير كشف حساب شهري', 'Monthly Account Statement')),
                ] else ...[
                  _buildReportTypeRadio(1, tr('إجمالي المبالغ', 'Total Balances')),
                  _buildReportTypeRadio(2, tr('تفاصيل جميع المبالغ', 'Details of All Amounts')),
                  _buildReportTypeRadio(3, tr('إجمالي المبالغ شهرياً', 'Monthly Total Amounts')),
                  _buildReportTypeRadio(4, tr('إجمالي التصنيفات والعملات', 'Total Categories & Currencies')),
                  _buildReportTypeRadio(5, tr('تفصيلي المبالغ شهرياً للتصنيف الحالي', 'Monthly Detailed Category')),
                ],

                const SizedBox(height: 16),

                // ─── Dynamic Category Selection ──────────────────────
                if (_reportType == 4 || _reportType == 5) ...[
                  Text(
                    tr('تصنيف الفلترة:', 'Filter Category:'),
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(tr('الكل (بدون فلترة)', 'All'))),
                          DropdownMenuItem(value: 'income', child: Text(tr('مقبوضات / دخل', 'Income'))),
                          DropdownMenuItem(value: 'expense', child: Text(tr('مدفوعات / مصروف', 'Expense'))),
                          DropdownMenuItem(value: 'creditor', child: Text(tr('حسابات دائنة (له)', 'Creditor Accounts'))),
                          DropdownMenuItem(value: 'debtor', child: Text(tr('حسابات مدينة (عليه)', 'Debtor Accounts'))),
                          DropdownMenuItem(value: 'custom', child: Text(tr('نص/كلمة مفتاحية مخصصة...', 'Custom Keyword...'))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val ?? 'all';
                          });
                        },
                      ),
                    ),
                  ),
                  if (_selectedCategory == 'custom') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customCategoryController,
                      decoration: InputDecoration(
                        hintText: tr('اكتب الكلمة المفتاحية (مثال: رواتب، طعام...)', 'Enter keyword (e.g. food, rent)'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],

                // ─── Date Filter Switch ──────────────────────────────
                CheckboxListTile(
                  title: Text(tr('تصفية حسب فترة زمنية معينة', 'Filter by Date Period')),
                  value: _filterByDate,
                  onChanged: (val) => setState(() => _filterByDate = val ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),
                if (_filterByDate) ...[
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.iconPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  _startDate == null ? tr('مِن تاريخ', 'From Date') : dateFormat.format(_startDate!),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.iconPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  _endDate == null ? tr('إلى تاريخ', 'To Date') : dateFormat.format(_endDate!),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // ─── Sorting Switch ──────────────────────────────────
                CheckboxListTile(
                  title: Text(tr('ترتيب البيانات والنتائج', 'Enable Sorting')),
                  value: _enableSorting,
                  onChanged: (val) => setState(() => _enableSorting = val ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),
                if (_enableSorting) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'newest', child: Text(tr('التاريخ (الأحدث أولاً)', 'Date (Newest First)'))),
                          DropdownMenuItem(value: 'oldest', child: Text(tr('التاريخ (الأقدم أولاً)', 'Date (Oldest First)'))),
                          DropdownMenuItem(value: 'highest', child: Text(tr('المبلغ (الأكبر أولاً)', 'Amount (Highest First)'))),
                          DropdownMenuItem(value: 'lowest', child: Text(tr('المبلغ (الأصغر أولاً)', 'Amount (Lowest First)'))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _sortBy = val ?? 'newest';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 16),

                // ─── Export Action Buttons ───────────────────────────
                if (_isExporting) ...[
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // PDF Icon Button
                      _buildExportAction(
                        icon: Icons.picture_as_pdf_rounded,
                        color: Colors.red.shade700,
                        label: tr('تصدير PDF', 'PDF'),
                        onTap: () => _handleExport(format: 'pdf'),
                      ),
                      // Excel Icon Button
                      _buildExportAction(
                        icon: Icons.table_chart_rounded,
                        color: Colors.green.shade700,
                        label: tr('تصدير Excel', 'Excel'),
                        onTap: () => _handleExport(format: 'csv'),
                      ),
                      // WhatsApp Share Button
                      _buildExportAction(
                        icon: Icons.share_rounded,
                        color: const Color(0xFF25D366),
                        label: tr('مشاركة', 'Share'),
                        onTap: () => _handleExport(format: 'pdf', isShare: true),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeRadio(int value, String title) {
    // ignore: deprecated_member_use
    return RadioListTile<int>(
      title: Text(title, style: AppTextStyles.bodyMedium),
      value: value,
      // ignore: deprecated_member_use
      groupValue: _reportType,
      // ignore: deprecated_member_use
      onChanged: (val) {
        setState(() {
          _reportType = val ?? 1;
        });
      },
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildExportAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
