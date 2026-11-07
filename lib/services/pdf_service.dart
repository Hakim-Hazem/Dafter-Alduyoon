import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/debt.dart';

class PdfService {
  static Future<void> exportDebts(List<Debt> debts, String currency) async {
    final doc = pw.Document();
    final fmt = NumberFormat('#,##0.00');
    final total = debts.fold<double>(0, (s, d) => s + d.amount);
    final paid = debts.fold<double>(0, (s, d) => s + d.paid);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Text('Debt Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
        pw.SizedBox(height: 18),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          _metric('Total', '${fmt.format(total)} $currency'),
          _metric('Paid', '${fmt.format(paid)} $currency'),
          _metric('Remaining', '${fmt.format(total-paid)} $currency'),
        ]),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Person / Entity', 'Amount', 'Paid', 'Remaining', 'Status'],
          data: debts.map((d) => [d.person, fmt.format(d.amount), fmt.format(d.paid), fmt.format(d.remaining), d.status]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellPadding: const pw.EdgeInsets.all(7),
        ),
        pw.SizedBox(height: 14),
        pw.Text('Note: This report was generated locally by Dayni.'),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'dayni-debt-report.pdf');
  }

  static pw.Widget _metric(String label, String value) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)), pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))],
  );
}
