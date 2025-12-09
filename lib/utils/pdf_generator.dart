import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cart_item.dart';

class PdfGenerator {
  static Future<void> generateAndPrintReceipt(List<CartItem> items, double total) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('POS RECEIPT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20))),
              pw.SizedBox(height: 20),
              pw.Text('Date: ${DateTime.now().toString()}'),
              pw.Divider(),
              pw.ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${item.product.name} x${item.quantity}'),
                      pw.Text('\$${item.subtotal.toStringAsFixed(2)}'),
                    ],
                  );
                },
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for your purchase!')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
