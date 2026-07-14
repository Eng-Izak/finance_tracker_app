import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../shared/models/account_model.dart';
import '../shared/models/transaction_model.dart';
import '../shared/enums/account_type.dart';
import '../shared/enums/transaction_type.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _currencyFormat = NumberFormat('#,##0.00');

  // ─── Export to CSV ───────────────────────────────────────────
  Future<String?> exportToCsv({
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
  }) async {
    try {
      // Build CSV rows
      final List<List<dynamic>> rows = [];

      // Header
      rows.add([
        'Account Name',
        'Account Type',
        'Currency',
        'Date',
        'Transaction Type',
        'Amount',
        'Notes',
      ]);

      for (final account in accounts) {
        final accountTxs =
            transactions.where((t) => t.accountId == account.id).toList();

        if (accountTxs.isEmpty) {
          rows.add([
            account.name,
            account.type == AccountType.creditor ? 'Creditor (له)' : 'Debtor (عليه)',
            account.currency,
            '',
            '',
            _currencyFormat.format(account.balance),
            account.notes ?? '',
          ]);
        }

        for (final tx in accountTxs) {
          rows.add([
            account.name,
            account.type == AccountType.creditor ? 'Creditor' : 'Debtor',
            tx.currency,
            _dateFormat.format(tx.date),
            tx.type == TransactionType.income ? 'Income' : 'Expense',
            _currencyFormat.format(tx.amount),
            tx.notes ?? '',
          ]);
        }
      }

      final csv = const ListToCsvConverter().convert(rows);
      final path = await _saveTempFile('finance_export.csv', csv);

      if (!kIsWeb && path != null) {
        await Share.shareXFiles([XFile(path)], text: 'Finance Tracker Export');
      }

      return path;
    } catch (e) {
      return null;
    }
  }

  // ─── Export to PDF ───────────────────────────────────────────
  Future<String?> exportToPdf({
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
    double creditorTotal = 0,
    double debtorTotal = 0,
    double balance = 0,
    String currency = 'LOCAL',
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text(
                'Finance Tracker - Report',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
                'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 16),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Financial Summary',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Receivable (له):'),
                        pw.Text(_currencyFormat.format(creditorTotal)),
                      ]),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Payable (عليه):'),
                        pw.Text(_currencyFormat.format(debtorTotal)),
                      ]),
                  pw.Divider(),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Net Balance:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text(_currencyFormat.format(balance),
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                      ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Accounts Table
            pw.Header(level: 1, text: 'Accounts'),
            pw.TableHelper.fromTextArray(
              headers: [
                'Name',
                'Type',
                'Currency',
                'Balance',
                'Transactions'
              ],
              data: accounts
                  .map((a) => [
                        a.name,
                        a.type == AccountType.creditor ? 'Creditor' : 'Debtor',
                        a.currency,
                        _currencyFormat.format(a.balance),
                        a.transactionCount.toString(),
                      ])
                  .toList(),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue100),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 20),

            // Transactions
            pw.Header(level: 1, text: 'Transactions'),
            pw.TableHelper.fromTextArray(
              headers: ['Account', 'Date', 'Type', 'Amount', 'Notes'],
              data: transactions
                  .map((t) {
                    final account = accounts.firstWhere(
                      (a) => a.id == t.accountId,
                      orElse: () => accounts.first,
                    );
                    return [
                      account.name,
                      _dateFormat.format(t.date),
                      t.type == TransactionType.income ? 'Income' : 'Expense',
                      _currencyFormat.format(t.amount),
                      t.notes ?? '',
                    ];
                  })
                  .toList(),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
            ),
          ],
        ),
      );

      final path = await _savePdfToTemp(pdf, 'finance_report.pdf');

      if (!kIsWeb && path != null) {
        await Share.shareXFiles([XFile(path)],
            text: 'Finance Tracker PDF Report');
      }

      return path;
    } catch (e) {
      return null;
    }
  }

  String _toArabicNumbers(String input, bool isAr) {
    if (!isAr) return input;
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    String result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  pw.Widget _buildRtlTable({
    required List<String> headers,
    required List<List<String>> data,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    Map<int, pw.Alignment>? alignments,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: headers.map((h) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  h,
                  style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 10),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
            );
          }).toList(),
        ),
        // Data Rows
        ...data.map((row) {
          return pw.TableRow(
            children: List.generate(row.length, (colIdx) {
              final cellText = row[colIdx];
              final alignment = alignments?[colIdx] ?? pw.Alignment.center;
              return pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Container(
                  alignment: alignment,
                  child: pw.Text(
                    cellText,
                    style: pw.TextStyle(font: fontRegular, fontSize: 9),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  pw.Widget _buildDetailedTransactionsSection({
    required List<TransactionModel> txs,
    required List<AccountModel> accounts,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required bool isArabic,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 24),
        pw.Text('العمليات التفصيلية للحساب:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
        pw.SizedBox(height: 8),
        _buildRtlTable(
          headers: ['التاريخ', 'الحساب', 'النوع', 'الملاحظات', 'المبلغ'],
          data: txs.map((t) {
            final acc = accounts.firstWhere((a) => a.id == t.accountId, orElse: () => accounts.first);
            return [
              _toArabicNumbers(_dateFormat.format(t.date), isArabic),
              acc.name,
              t.type == TransactionType.income ? 'دخل (له)' : 'مصروف (عليه)',
              t.notes ?? '-',
              _toArabicNumbers(_currencyFormat.format(t.amount), isArabic),
            ];
          }).toList(),
          fontRegular: fontRegular,
          fontBold: fontBold,
          alignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.centerLeft,
            4: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  void _addCsvDetailedTransactions(
    List<List<dynamic>> rows,
    List<TransactionModel> txs,
    List<AccountModel> accounts,
  ) {
    rows.add([]);
    rows.add(['العمليات التفصيلية للحساب']);
    rows.add(['التاريخ', 'الحساب', 'النوع', 'المبلغ', 'الملاحظات']);
    for (final tx in txs) {
      final acc = accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => accounts.first);
      rows.add([
        _dateFormat.format(tx.date),
        acc.name,
        tx.type == TransactionType.income ? 'دخل (له)' : 'مصروف (عليه)',
        _currencyFormat.format(tx.amount),
        tx.notes ?? '-',
      ]);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────
  Future<String?> _saveTempFile(String filename, String content) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _savePdfToTemp(pw.Document pdf, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (_) {
      return null;
    }
  }

  // ─── Print PDF ───────────────────────────────────────────────
  Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ─── Custom Reports (PDF & CSV) ──────────────────────────────
  Future<String?> generateCustomPdfReport({
    required int reportType,
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryFilter,
    bool isShare = false,
    bool isArabic = true,
  }) async {
    try {
      final pdf = pw.Document();
      
      pw.Font fontRegular;
      pw.Font fontBold;
      try {
        fontRegular = await PdfGoogleFonts.cairoRegular();
        fontBold = await PdfGoogleFonts.cairoBold();
      } catch (e) {
        debugPrint('Failed to load Google Fonts (offline or network error): $e');
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      // 1. Filter transactions
      var txs = List<TransactionModel>.from(transactions);
      if (startDate != null) {
        txs = txs.where((t) => t.date.isAfter(startDate.subtract(const Duration(seconds: 1)))).toList();
      }
      if (endDate != null) {
        txs = txs.where((t) => t.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
      }

      if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
        final filterLower = categoryFilter.toLowerCase();
        if (filterLower == 'income') {
          txs = txs.where((t) => t.type == TransactionType.income).toList();
        } else if (filterLower == 'expense') {
          txs = txs.where((t) => t.type == TransactionType.expense).toList();
        } else if (filterLower == 'creditor') {
          final credAccountIds = accounts.where((a) => a.type == AccountType.creditor).map((a) => a.id).toSet();
          txs = txs.where((t) => credAccountIds.contains(t.accountId)).toList();
        } else if (filterLower == 'debtor') {
          final debtAccountIds = accounts.where((a) => a.type == AccountType.debtor).map((a) => a.id).toSet();
          txs = txs.where((t) => debtAccountIds.contains(t.accountId)).toList();
        } else {
          txs = txs.where((t) => t.notes?.toLowerCase().contains(filterLower) ?? false).toList();
        }
      }

      // 2. Generate Page based on reportType
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
          ),
          build: (context) {
            String title = '';
            List<pw.Widget> children = [];

            // Add Header
            switch (reportType) {
              case 1:
                title = 'تقرير إجمالي المبالغ - عام';
                break;
              case 2:
                title = 'كشف حساب تفصيلي';
                break;
              case 3:
                title = 'تقرير إجمالي المبالغ شهرياً';
                break;
              case 4:
                title = 'تقرير إجمالي التصنيفات والعملات';
                break;
              case 5:
                title = 'التقرير الشهري المفصل للتصنيف';
                break;
              default:
                title = 'التقرير المالي';
            }

            children.add(
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          title,
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          _toArabicNumbers('تاريخ التوليد: ${_dateFormat.format(DateTime.now())}', isArabic),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    if (startDate != null || endDate != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _toArabicNumbers('الفترة: ${startDate != null ? _dateFormat.format(startDate) : ""} إلى ${endDate != null ? _dateFormat.format(endDate) : ""}', isArabic),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                    pw.Divider(thickness: 2, color: PdfColors.blue300),
                    pw.SizedBox(height: 16),
                  ],
                ),
              ),
            );

            // Report Body
            if (reportType == 1) {
              // General total amounts report
              double totalCreditor = 0;
              double totalDebtor = 0;
              for (final acc in accounts) {
                if (acc.type == AccountType.creditor) {
                  totalCreditor += acc.balance;
                } else {
                  totalDebtor += acc.balance;
                }
              }
              final net = totalCreditor - totalDebtor;

              children.add(
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Summary box
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            pw.Column(children: [
                              pw.Text('إجمالي له (دائن)'),
                              pw.Text(_toArabicNumbers(_currencyFormat.format(totalCreditor), isArabic), style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
                            ]),
                            pw.Column(children: [
                              pw.Text('إجمالي عليه (مدين)'),
                              pw.Text(_toArabicNumbers(_currencyFormat.format(totalDebtor), isArabic), style: pw.TextStyle(color: PdfColors.orange800, fontWeight: pw.FontWeight.bold)),
                            ]),
                            pw.Column(children: [
                              pw.Text('صافي الرصيد'),
                              pw.Text(
                                _toArabicNumbers(_currencyFormat.format(net), isArabic),
                                style: pw.TextStyle(
                                  color: net >= 0 ? PdfColors.green800 : PdfColors.orange800,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 20),

                      // Accounts Table
                      pw.Text('ملخص أرصدة الحسابات:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      _buildRtlTable(
                        headers: ['اسم الحساب', 'الرصيد', 'النوع', 'آخر تحديث'],
                        data: accounts.map((a) {
                          return [
                            a.name,
                            _toArabicNumbers(_currencyFormat.format(a.balance), isArabic),
                            a.type == AccountType.creditor ? 'دائن (له)' : 'مدين (عليه)',
                            _toArabicNumbers(_dateFormat.format(a.updatedAt), isArabic),
                          ];
                        }).toList(),
                        fontRegular: fontRegular,
                        fontBold: fontBold,
                        alignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerRight,
                          2: pw.Alignment.center,
                          3: pw.Alignment.center,
                        },
                      ),
                    ],
                  ),
                ),
              );
            } else if (reportType == 2) {
              // Detailed account statement
              double runningBalance = 0;
              // If single account, running balance can start with its openingBalance
              final singleAcc = accounts.length == 1 ? accounts.first : null;
              if (singleAcc != null) {
                runningBalance = singleAcc.openingBalance;
              }

              // Sort transactions chronologically to calculate running balance correctly
              txs.sort((a, b) => a.date.compareTo(b.date));

              final List<List<String>> tableData = [];
              for (final tx in txs) {
                final acc = accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => accounts.first);
                
                double debit = 0;
                double credit = 0;
                if (tx.type == TransactionType.income) {
                  credit = tx.amount;
                  runningBalance += tx.amount;
                } else {
                  debit = tx.amount;
                  runningBalance -= tx.amount;
                }

                tableData.add([
                  _toArabicNumbers(_dateFormat.format(tx.date), isArabic),
                  '${acc.name}${tx.notes != null ? " - ${tx.notes}" : ""}',
                  debit > 0 ? _toArabicNumbers(_currencyFormat.format(debit), isArabic) : '-',
                  credit > 0 ? _toArabicNumbers(_currencyFormat.format(credit), isArabic) : '-',
                  _toArabicNumbers(_currencyFormat.format(runningBalance), isArabic),
                ]);
              }

              children.add(
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (singleAcc != null) ...[
                        pw.Text('تفاصيل الحساب:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text('اسم الحساب: ${singleAcc.name} | الجوال: ${singleAcc.phone ?? "-"}'),
                        pw.Text('الرصيد الافتتاحي: ${_toArabicNumbers(_currencyFormat.format(singleAcc.openingBalance), isArabic)} | الرصيد الحالي: ${_toArabicNumbers(_currencyFormat.format(singleAcc.balance), isArabic)}'),
                        pw.SizedBox(height: 12),
                      ],
                      _buildRtlTable(
                        headers: ['التاريخ', 'التفاصيل / الحساب', 'عليه (خصم)', 'له (إيداع)', 'الرصيد التراكمي'],
                        data: tableData,
                        fontRegular: fontRegular,
                        fontBold: fontBold,
                        alignments: {
                          0: pw.Alignment.center,
                          1: pw.Alignment.centerLeft,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                          4: pw.Alignment.centerRight,
                        },
                      ),
                    ],
                  ),
                ),
              );
            } else if (reportType == 3) {
              // Monthly total amounts report
              final Map<String, ({double income, double expense})> monthlyData = {};
              for (final tx in txs) {
                final monthStr = DateFormat('yyyy-MM').format(tx.date);
                final current = monthlyData[monthStr] ?? (income: 0.0, expense: 0.0);
                if (tx.type == TransactionType.income) {
                  monthlyData[monthStr] = (income: current.income + tx.amount, expense: current.expense);
                } else {
                  monthlyData[monthStr] = (income: current.income, expense: current.expense + tx.amount);
                }
              }

              final sortedMonths = monthlyData.keys.toList()..sort((a, b) => b.compareTo(a));

              children.add(
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildRtlTable(
                        headers: ['الشهر', 'إجمالي المقبوضات (له)', 'إجمالي المدفوعات (عليه)', 'صافي التغير'],
                        data: sortedMonths.map((m) {
                          final val = monthlyData[m]!;
                          return [
                            _toArabicNumbers(m, isArabic),
                            _toArabicNumbers(_currencyFormat.format(val.income), isArabic),
                            _toArabicNumbers(_currencyFormat.format(val.expense), isArabic),
                            _toArabicNumbers(_currencyFormat.format(val.income - val.expense), isArabic),
                          ];
                        }).toList(),
                        fontRegular: fontRegular,
                        fontBold: fontBold,
                        alignments: {
                          0: pw.Alignment.center,
                          1: pw.Alignment.centerRight,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                        },
                      ),
                      if (txs.isNotEmpty)
                        _buildDetailedTransactionsSection(
                          txs: txs,
                          accounts: accounts,
                          fontRegular: fontRegular,
                          fontBold: fontBold,
                          isArabic: isArabic,
                        ),
                    ],
                  ),
                ),
              );
            } else if (reportType == 4) {
              // Group by note/keyword/type and currency
              final Map<String, ({double income, double expense, String currency})> groupedData = {};
              for (final tx in txs) {
                final category = tx.notes?.trim() ?? (tx.type == TransactionType.income ? 'دخل غير مصنف' : 'مصروف غير مصنف');
                final key = '$category|${tx.currency}';
                final current = groupedData[key] ?? (income: 0.0, expense: 0.0, currency: tx.currency);
                if (tx.type == TransactionType.income) {
                  groupedData[key] = (income: current.income + tx.amount, expense: current.expense, currency: tx.currency);
                } else {
                  groupedData[key] = (income: current.income, expense: current.expense + tx.amount, currency: tx.currency);
                }
              }

              children.add(
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildRtlTable(
                        headers: ['التصنيف / البيان', 'العملة', 'إجمالي له (دخل)', 'إجمالي عليه (مصروف)', 'صافي الفارق'],
                        data: groupedData.entries.map((e) {
                          final category = e.key.split('|')[0];
                          final val = e.value;
                          return [
                            category,
                            val.currency == 'LOCAL' ? 'محلي' : val.currency,
                            _toArabicNumbers(_currencyFormat.format(val.income), isArabic),
                            _toArabicNumbers(_currencyFormat.format(val.expense), isArabic),
                            _toArabicNumbers(_currencyFormat.format(val.income - val.expense), isArabic),
                          ];
                        }).toList(),
                        fontRegular: fontRegular,
                        fontBold: fontBold,
                        alignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.center,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                          4: pw.Alignment.centerRight,
                        },
                      ),
                      if (txs.isNotEmpty)
                        _buildDetailedTransactionsSection(
                          txs: txs,
                          accounts: accounts,
                          fontRegular: fontRegular,
                          fontBold: fontBold,
                          isArabic: isArabic,
                        ),
                    ],
                  ),
                ),
              );
            } else if (reportType == 5) {
              // Monthly detailed amounts for current category
              final Map<String, ({double total, int count, String currency})> monthlyCategory = {};
              for (final tx in txs) {
                final monthStr = DateFormat('yyyy-MM').format(tx.date);
                final key = '$monthStr|${tx.currency}';
                final current = monthlyCategory[key] ?? (total: 0.0, count: 0, currency: tx.currency);
                monthlyCategory[key] = (
                  total: current.total + tx.amount,
                  count: current.count + 1,
                  currency: tx.currency
                );
              }

              final sortedKeys = monthlyCategory.keys.toList()..sort((a, b) => b.compareTo(a));

              children.add(
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildRtlTable(
                        headers: ['الشهر', 'التصنيف / الفلتر', 'العملة', 'عدد العمليات', 'إجمالي المبلغ'],
                        data: sortedKeys.map((k) {
                          final month = k.split('|')[0];
                          final val = monthlyCategory[k]!;
                          return [
                            _toArabicNumbers(month, isArabic),
                            categoryFilter ?? 'الكل',
                            val.currency == 'LOCAL' ? 'محلي' : val.currency,
                            _toArabicNumbers(val.count.toString(), isArabic),
                            _toArabicNumbers(_currencyFormat.format(val.total), isArabic),
                          ];
                        }).toList(),
                        fontRegular: fontRegular,
                        fontBold: fontBold,
                        alignments: {
                          0: pw.Alignment.center,
                          1: pw.Alignment.centerLeft,
                          2: pw.Alignment.center,
                          3: pw.Alignment.center,
                          4: pw.Alignment.centerRight,
                        },
                      ),
                      if (txs.isNotEmpty)
                        _buildDetailedTransactionsSection(
                          txs: txs,
                          accounts: accounts,
                          fontRegular: fontRegular,
                          fontBold: fontBold,
                          isArabic: isArabic,
                        ),
                    ],
                  ),
                ),
              );
            }

            return children;
          },
        ),
      );

      final path = await _savePdfToTemp(pdf, 'financial_report_$reportType.pdf');
      
      if (path != null) {
        try {
          if (isShare) {
            await Share.shareXFiles([XFile(path)], text: 'تقرير مالي - Finance Tracker');
          } else {
            await OpenFilex.open(path);
          }
        } catch (e) {
          debugPrint('Failed to open or share PDF report file: $e');
        }
      }

      return path;
    } catch (e) {
      debugPrint('Error generating PDF report: $e');
      return null;
    }
  }

  Future<String?> generateCustomCsvReport({
    required int reportType,
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryFilter,
    bool isShare = false,
  }) async {
    try {
      final List<List<dynamic>> rows = [];

      // 1. Filter transactions
      var txs = List<TransactionModel>.from(transactions);
      if (startDate != null) {
        txs = txs.where((t) => t.date.isAfter(startDate.subtract(const Duration(seconds: 1)))).toList();
      }
      if (endDate != null) {
        txs = txs.where((t) => t.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
      }

      if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
        final filterLower = categoryFilter.toLowerCase();
        if (filterLower == 'income') {
          txs = txs.where((t) => t.type == TransactionType.income).toList();
        } else if (filterLower == 'expense') {
          txs = txs.where((t) => t.type == TransactionType.expense).toList();
        } else if (filterLower == 'creditor') {
          final credAccountIds = accounts.where((a) => a.type == AccountType.creditor).map((a) => a.id).toSet();
          txs = txs.where((t) => credAccountIds.contains(t.accountId)).toList();
        } else if (filterLower == 'debtor') {
          final debtAccountIds = accounts.where((a) => a.type == AccountType.debtor).map((a) => a.id).toSet();
          txs = txs.where((t) => debtAccountIds.contains(t.accountId)).toList();
        } else {
          txs = txs.where((t) => t.notes?.toLowerCase().contains(filterLower) ?? false).toList();
        }
      }

      // 2. Generate CSV structure based on reportType
      if (reportType == 1) {
        // Summary
        rows.add(['تقرير إجمالي المبالغ - عام']);
        rows.add(['تاريخ التوليد', _dateFormat.format(DateTime.now())]);
        rows.add([]);
        rows.add(['اسم الحساب', 'الرصيد', 'نوع الحساب', 'آخر تحديث']);
        for (final a in accounts) {
          rows.add([
            a.name,
            _currencyFormat.format(a.balance),
            a.type == AccountType.creditor ? 'دائن (له)' : 'مدين (عليه)',
            _dateFormat.format(a.updatedAt),
          ]);
        }
      } else if (reportType == 2) {
        rows.add(['كشف حساب تفصيلي']);
        rows.add(['تاريخ التوليد', _dateFormat.format(DateTime.now())]);
        rows.add([]);
        rows.add(['التاريخ', 'التفاصيل / الحساب', 'عليه (مدفوعات)', 'له (مقبوضات)', 'الرصيد التراكمي']);
        
        double runningBalance = 0;
        final singleAcc = accounts.length == 1 ? accounts.first : null;
        if (singleAcc != null) {
          runningBalance = singleAcc.openingBalance;
        }

        txs.sort((a, b) => a.date.compareTo(b.date));
        for (final tx in txs) {
          final acc = accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => accounts.first);
          double debit = 0;
          double credit = 0;
          if (tx.type == TransactionType.income) {
            credit = tx.amount;
            runningBalance += tx.amount;
          } else {
            debit = tx.amount;
            runningBalance -= tx.amount;
          }

          rows.add([
            _dateFormat.format(tx.date),
            '${acc.name}${tx.notes != null ? " - ${tx.notes}" : ""}',
            debit > 0 ? _currencyFormat.format(debit) : '-',
            credit > 0 ? _currencyFormat.format(credit) : '-',
            _currencyFormat.format(runningBalance),
          ]);
        }
      } else if (reportType == 3) {
        rows.add(['تقرير إجمالي المبالغ شهرياً']);
        rows.add(['تاريخ التوليد', _dateFormat.format(DateTime.now())]);
        rows.add([]);
        rows.add(['الشهر', 'إجمالي المقبوضات (له)', 'إجمالي المدفوعات (عليه)', 'صافي التغير']);
        
        final Map<String, ({double income, double expense})> monthlyData = {};
        for (final tx in txs) {
          final monthStr = DateFormat('yyyy-MM').format(tx.date);
          final current = monthlyData[monthStr] ?? (income: 0.0, expense: 0.0);
          if (tx.type == TransactionType.income) {
            monthlyData[monthStr] = (income: current.income + tx.amount, expense: current.expense);
          } else {
            monthlyData[monthStr] = (income: current.income, expense: current.expense + tx.amount);
          }
        }

        final sortedMonths = monthlyData.keys.toList()..sort((a, b) => b.compareTo(a));
        for (final m in sortedMonths) {
          final val = monthlyData[m]!;
          rows.add([
            m,
            _currencyFormat.format(val.income),
            _currencyFormat.format(val.expense),
            _currencyFormat.format(val.income - val.expense),
          ]);
        }
        if (txs.isNotEmpty) {
          _addCsvDetailedTransactions(rows, txs, accounts);
        }
      } else if (reportType == 4) {
        rows.add(['تقرير إجمالي التصنيفات والعملات']);
        rows.add(['تاريخ التوليد', _dateFormat.format(DateTime.now())]);
        rows.add([]);
        rows.add(['التصنيف / البيان', 'العملة', 'إجمالي له (دخل)', 'إجمالي عليه (مصروف)', 'صافي الفارق']);

        final Map<String, ({double income, double expense, String currency})> groupedData = {};
        for (final tx in txs) {
          final category = tx.notes?.trim() ?? (tx.type == TransactionType.income ? 'دخل غير مصنف' : 'مصروف غير مصنف');
          final key = '$category|${tx.currency}';
          final current = groupedData[key] ?? (income: 0.0, expense: 0.0, currency: tx.currency);
          if (tx.type == TransactionType.income) {
            groupedData[key] = (income: current.income + tx.amount, expense: current.expense, currency: tx.currency);
          } else {
            groupedData[key] = (income: current.income, expense: current.expense + tx.amount, currency: tx.currency);
          }
        }

        for (final e in groupedData.entries) {
          final category = e.key.split('|')[0];
          final val = e.value;
          rows.add([
            category,
            val.currency,
            _currencyFormat.format(val.income),
            _currencyFormat.format(val.expense),
            _currencyFormat.format(val.income - val.expense),
          ]);
        }
        if (txs.isNotEmpty) {
          _addCsvDetailedTransactions(rows, txs, accounts);
        }
      } else if (reportType == 5) {
        rows.add(['التقرير الشهري المفصل للتصنيف']);
        rows.add(['تاريخ التوليد', _dateFormat.format(DateTime.now())]);
        rows.add(['تصنيف البحث', categoryFilter ?? 'الكل']);
        rows.add([]);
        rows.add(['الشهر', 'العملة', 'عدد العمليات', 'إجمالي المبلغ']);

        final Map<String, ({double total, int count, String currency})> monthlyCategory = {};
        for (final tx in txs) {
          final monthStr = DateFormat('yyyy-MM').format(tx.date);
          final key = '$monthStr|${tx.currency}';
          final current = monthlyCategory[key] ?? (total: 0.0, count: 0, currency: tx.currency);
          monthlyCategory[key] = (
            total: current.total + tx.amount,
            count: current.count + 1,
            currency: tx.currency
          );
        }

        final sortedKeys = monthlyCategory.keys.toList()..sort((a, b) => b.compareTo(a));
        for (final k in sortedKeys) {
          final month = k.split('|')[0];
          final val = monthlyCategory[k]!;
          rows.add([
            month,
            val.currency,
            val.count.toString(),
            _currencyFormat.format(val.total),
          ]);
        }
        if (txs.isNotEmpty) {
          _addCsvDetailedTransactions(rows, txs, accounts);
        }
      }

      final csvString = const ListToCsvConverter().convert(rows);
      final filename = 'financial_report_$reportType.csv';
      final path = await _saveTempFile(filename, csvString);
 
      if (path != null) {
        try {
          if (isShare) {
            await Share.shareXFiles([XFile(path)], text: 'تقرير مالي CSV');
          } else {
            await OpenFilex.open(path);
          }
        } catch (e) {
          debugPrint('Failed to open or share CSV report file: $e');
        }
      }
 
      return path;
    } catch (e) {
      debugPrint('Error generating CSV report: $e');
      return null;
    }
  }
}
