import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cart_item.dart';
import '../models/payment.dart';
import '../models/discount.dart';
import '../models/customer.dart';

class PdfGenerator {
  static const String storeName = 'My POS Store';
  static const String storeAddress = '123 Main Street, City, State 12345';
  static const String storePhone = '(555) 123-4567';
  static const String footerMessage = 'Thank you for your business!';

  /// Legacy method for backward compatibility
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

  /// Enhanced receipt with full transaction details
  static Future<void> generateEnhancedReceipt({
    required String transactionId,
    required List<CartItem> items,
    required List<Payment> payments,
    required double subtotalBeforeDiscount,
    required double discountAmount,
    required double finalAmount,
    Customer? customer,
    double? pointsEarned,
    List<Discount>? discounts,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - Store Information
              _buildHeader(),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),

              // Transaction Information
              _buildTransactionInfo(transactionId, dateFormat),
              pw.SizedBox(height: 8),

              // Customer Information (if available)
              if (customer != null) ...[
                _buildCustomerInfo(customer, pointsEarned),
                pw.SizedBox(height: 8),
              ],

              pw.Divider(),
              pw.SizedBox(height: 8),

              // Items List
              _buildItemsSection(items),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Subtotal and Discounts
              _buildPricingSection(subtotalBeforeDiscount, discountAmount, finalAmount, discounts),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),

              // Payment Methods
              _buildPaymentSection(payments, finalAmount),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 15),

              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            storeName,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            storeAddress,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(
            storePhone,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionInfo(String transactionId, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Receipt #${transactionId.substring(0, 8).toUpperCase()}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          dateFormat.format(DateTime.now()),
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(Customer customer, double? pointsEarned) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer: ${customer.name}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          if (customer.email != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Email: ${customer.email}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
          if (pointsEarned != null && pointsEarned > 0) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Points Earned:',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  '+${pointsEarned.toStringAsFixed(0)} pts',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'New Balance:',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  '${customer.loyaltyPoints.toStringAsFixed(0)} pts',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildItemsSection(List<CartItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ITEMS',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        ...items.map((item) {
          final hasDiscount = item.hasDiscount;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        item.product.name,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    if (hasDiscount)
                      pw.Text(
                        'Saved: \$${item.discountAmount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.red700,
                        ),
                      ),
                  ],
                ),
                if (item.unit != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      'Unit: ${item.unit!.name}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildPricingSection(
    double subtotal,
    double discountAmount,
    double finalAmount,
    List<Discount>? discounts,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              '\$${subtotal.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        if (discountAmount > 0) ...[
          pw.SizedBox(height: 4),
          // Show discount breakdown if available
          if (discounts != null && discounts.isNotEmpty) ...[
            ...discounts.map((discount) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '  ${discount.displayValue}${discount.reason != null ? " (${discount.reason})" : ""}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.red700),
                      ),
                    ),
                    pw.Text(
                      '-\$${discount.calculateAmount(subtotal).toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.red700),
                    ),
                  ],
                ),
              );
            }),
          ] else
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Discount:',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700),
                ),
                pw.Text(
                  '-\$${discountAmount.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700),
                ),
              ],
            ),
          pw.SizedBox(height: 4),
        ],
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.Text(
              '\$${finalAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentSection(List<Payment> payments, double totalAmount) {
    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final change = totalPaid - totalAmount;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PAYMENT',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        ...payments.map((payment) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  payment.methodName,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '\$${payment.amount.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        }),
        if (payments.length > 1) ...[
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Paid:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '\$${totalPaid.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
        if (change > 0) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Change:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '\$${change.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            footerMessage,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'Please keep this receipt for your records',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }
}
