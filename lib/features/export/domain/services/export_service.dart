import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// Service untuk export data ke CSV atau PDF.
class ExportService {
  ExportService._();

  // ─── CSV ────────────────────────────────────────────────────────────────────

  static Future<File> exportToCsv(
    List<TransactionEntity> transactions, {
    String filename = 'spendly_export',
  }) async {
    final rows = <List<dynamic>>[
      // Header
      ['Tanggal', 'Tipe', 'Kategori', 'Nominal', 'Catatan'],
      // Data
      ...transactions.map((tx) => [
            _formatDate(tx.date),
            tx.isExpense ? 'Pengeluaran' : 'Pemasukan',
            tx.category,
            tx.amount.toStringAsFixed(0),
            tx.note ?? '',
          ],),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.csv');
    await file.writeAsString(csv);
    return file;
  }

  // ─── PDF ────────────────────────────────────────────────────────────────────

  static Future<File> exportToPdf(
    List<TransactionEntity> transactions, {
    String monthLabel = '',
    String filename = 'spendly_report',
  }) async {
    final pdf = pw.Document();

    final totalIncome = transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);
    final savings = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Title
          pw.Text(
            'Spendly — Laporan Keuangan',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (monthLabel.isNotEmpty)
            pw.Text(monthLabel,
                style: const pw.TextStyle(
                    fontSize: 12, color: PdfColors.grey600,),),
          pw.SizedBox(height: 16),
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStat('Pemasukan',
                    CurrencyFormatter.format(totalIncome),
                    PdfColors.green700,),
                _pdfStat('Pengeluaran',
                    CurrencyFormatter.format(totalExpense),
                    PdfColors.red700,),
                _pdfStat('Tabungan',
                    CurrencyFormatter.format(savings),
                    savings >= 0
                        ? PdfColors.blue700
                        : PdfColors.orange700,),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          // Table header
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300, width: 0.5,),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2.5),
              4: const pw.FlexColumnWidth(3),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  'Tanggal',
                  'Tipe',
                  'Kategori',
                  'Nominal',
                  'Catatan',
                ]
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,),),
                        ),)
                    .toList(),
              ),
              // Data rows
              ...transactions.map((tx) => pw.TableRow(
                    children: [
                      _pdfCell(_formatDate(tx.date)),
                      _pdfCell(tx.isExpense
                          ? 'Pengeluaran'
                          : 'Pemasukan',),
                      _pdfCell(tx.category),
                      _pdfCell(
                          CurrencyFormatter.formatCompact(tx.amount),),
                      _pdfCell(tx.note ?? '-'),
                    ],
                  ),),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Dibuat oleh Spendly • ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey500,),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ─── Share ───────────────────────────────────────────────────────────────────

  static Future<void> shareFile(File file, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject ?? 'Spendly Export',
      ),
    );
  }

  // ─── Print PDF ────────────────────────────────────────────────────────────────

  static Future<void> printPdf(File file) async {
    await Printing.layoutPdf(
        onLayout: (_) async => await file.readAsBytes(),);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static pw.Widget _pdfStat(
      String label, String value, PdfColor color,) {
    return pw.Column(
      children: [
        pw.Text(label,
            style:
                const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color,),),
      ],
    );
  }

  static pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }
}