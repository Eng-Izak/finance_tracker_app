import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
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
}
