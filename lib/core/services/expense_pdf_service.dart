// Expense PDF Report Service
//
// Generates professional PDF expense reports that can be shared or printed.
// Features:
// - Trip summary with dates and destination
// - Category breakdown with percentages
// - Detailed expense list
// - Payer summary (who paid what)

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../shared/models/expense_model.dart';
import '../../shared/models/trip_model.dart';

/// Service for generating expense report PDFs
class ExpensePdfService {
  /// Category icons mapping (emoji for PDF)
  static const Map<String, String> _categoryIcons = {
    'food': '🍔',
    'transport': '🚗',
    'stay': '🏨',
    'activities': '🎟️',
    'shopping': '🛍️',
    'other': '📦',
  };


  /// Generate expense report PDF
  static Future<Uint8List> generateExpenseReport({
    required TripModel trip,
    required List<ExpenseModel> expenses,
    double? budget,
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final currency = expenses.isNotEmpty ? expenses.first.currency : 'INR';
    final currencySymbol = _getCurrencySymbol(currency);

    // Group by category
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      final category = expense.category?.toLowerCase() ?? 'other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
    }

    // Group by payer
    final payerTotals = <String, double>{};
    for (final expense in expenses) {
      final payer = expense.payerName ?? 'Unknown';
      payerTotals[payer] = (payerTotals[payer] ?? 0) + expense.amount;
    }

    // Sort expenses by date
    final sortedExpenses = List<ExpenseModel>.from(expenses)
      ..sort((a, b) => (b.transactionDate ?? b.createdAt ?? DateTime.now())
          .compareTo(a.transactionDate ?? a.createdAt ?? DateTime.now()));

    // Date formatter
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(trip, dateFormat),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary Section
          _buildSummarySection(
            totalSpent: totalSpent,
            budget: budget,
            currencySymbol: currencySymbol,
            expenseCount: expenses.length,
            trip: trip,
            dateFormat: dateFormat,
          ),
          pw.SizedBox(height: 20),

          // Category Breakdown
          if (categoryTotals.isNotEmpty) ...[
            _buildSectionTitle('Category Breakdown'),
            pw.SizedBox(height: 10),
            _buildCategoryBreakdown(categoryTotals, totalSpent, currencySymbol),
            pw.SizedBox(height: 20),
          ],

          // Payer Summary
          if (payerTotals.isNotEmpty && payerTotals.length > 1) ...[
            _buildSectionTitle('Who Paid What'),
            pw.SizedBox(height: 10),
            _buildPayerSummary(payerTotals, currencySymbol),
            pw.SizedBox(height: 20),
          ],

          // Detailed Expenses
          _buildSectionTitle('Detailed Expenses'),
          pw.SizedBox(height: 10),
          _buildExpenseTable(sortedExpenses, currencySymbol, dateFormat),
        ],
      ),
    );

    return pdf.save();
  }

  /// Build PDF header
  static pw.Widget _buildHeader(TripModel trip, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Expense Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                trip.name,
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.blueGrey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (trip.destination != null)
                pw.Text(
                  trip.destination!,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.blueGrey600,
                  ),
                ),
              pw.SizedBox(height: 2),
              pw.Text(
                _formatTripDates(trip, dateFormat),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build PDF footer
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by TravelCompanion',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey500,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build summary section
  static pw.Widget _buildSummarySection({
    required double totalSpent,
    double? budget,
    required String currencySymbol,
    required int expenseCount,
    required TripModel trip,
    required DateFormat dateFormat,
  }) {
    final remaining = budget != null ? budget - totalSpent : null;
    final isOverBudget = remaining != null && remaining < 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Spent',
            '$currencySymbol${_formatAmount(totalSpent)}',
            PdfColors.blue800,
          ),
          if (budget != null) ...[
            _buildSummaryItem(
              'Budget',
              '$currencySymbol${_formatAmount(budget)}',
              PdfColors.blueGrey700,
            ),
            _buildSummaryItem(
              isOverBudget ? 'Over Budget' : 'Remaining',
              '$currencySymbol${_formatAmount(remaining!.abs())}',
              isOverBudget ? PdfColors.red700 : PdfColors.green700,
            ),
          ],
          _buildSummaryItem(
            'Expenses',
            '$expenseCount',
            PdfColors.blueGrey700,
          ),
        ],
      ),
    );
  }

  /// Build summary item widget
  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  /// Build section title
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ),
    );
  }

  /// Build category breakdown
  static pw.Widget _buildCategoryBreakdown(
    Map<String, double> categoryTotals,
    double totalSpent,
    String currencySymbol,
  ) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
            _buildTableCell('%', isHeader: true, align: pw.TextAlign.center),
          ],
        ),
        // Data rows
        ...sortedCategories.map((entry) {
          final percentage = totalSpent > 0 ? (entry.value / totalSpent * 100) : 0;
          final icon = _categoryIcons[entry.key] ?? '📦';
          return pw.TableRow(
            children: [
              _buildTableCell('$icon ${_capitalize(entry.key)}'),
              _buildTableCell(
                '$currencySymbol${_formatAmount(entry.value)}',
                align: pw.TextAlign.right,
              ),
              _buildTableCell(
                '${percentage.toStringAsFixed(1)}%',
                align: pw.TextAlign.center,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build payer summary
  static pw.Widget _buildPayerSummary(
    Map<String, double> payerTotals,
    String currencySymbol,
  ) {
    final sortedPayers = payerTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Paid By', isHeader: true),
            _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Data rows
        ...sortedPayers.map((entry) => pw.TableRow(
          children: [
            _buildTableCell(entry.key),
            _buildTableCell(
              '$currencySymbol${_formatAmount(entry.value)}',
              align: pw.TextAlign.right,
            ),
          ],
        )),
      ],
    );
  }

  /// Build expense table
  static pw.Widget _buildExpenseTable(
    List<ExpenseModel> expenses,
    String currencySymbol,
    DateFormat dateFormat,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Data rows
        ...expenses.map((expense) {
          final date = expense.transactionDate ?? expense.createdAt;
          final category = expense.category?.toLowerCase() ?? 'other';
          final icon = _categoryIcons[category] ?? '📦';
          return pw.TableRow(
            children: [
              _buildTableCell(
                date != null ? dateFormat.format(date) : '-',
                fontSize: 9,
              ),
              _buildTableCell(expense.title, fontSize: 9),
              _buildTableCell('$icon ${_capitalize(category)}', fontSize: 9),
              _buildTableCell(
                '$currencySymbol${_formatAmount(expense.amount)}',
                align: pw.TextAlign.right,
                fontSize: 9,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blueGrey800 : PdfColors.black,
        ),
      ),
    );
  }

  /// Format trip dates
  static String _formatTripDates(TripModel trip, DateFormat dateFormat) {
    if (trip.startDate != null && trip.endDate != null) {
      return '${dateFormat.format(trip.startDate!)} - ${dateFormat.format(trip.endDate!)}';
    } else if (trip.startDate != null) {
      return 'From ${dateFormat.format(trip.startDate!)}';
    }
    return '';
  }

  /// Format amount with commas
  static String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      final formatter = NumberFormat('#,##,###.##', 'en_IN');
      return formatter.format(amount);
    }
    return amount.toStringAsFixed(2);
  }

  /// Get currency symbol
  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'SGD':
        return 'S\$';
      case 'MYR':
        return 'RM';
      case 'THB':
        return '฿';
      default:
        return currency;
    }
  }

  /// Capitalize first letter
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Share or print the PDF
  static Future<void> sharePdf({
    required TripModel trip,
    required List<ExpenseModel> expenses,
    double? budget,
  }) async {
    final pdfBytes = await generateExpenseReport(
      trip: trip,
      expenses: expenses,
      budget: budget,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${trip.name.replaceAll(' ', '_')}_expenses.pdf',
    );
  }

  /// Preview and print the PDF
  static Future<void> printPdf({
    required TripModel trip,
    required List<ExpenseModel> expenses,
    double? budget,
  }) async {
    final pdfBytes = await generateExpenseReport(
      trip: trip,
      expenses: expenses,
      budget: budget,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: '${trip.name} - Expense Report',
    );
  }
}
