import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:kissanfresh/model/order_model.dart';

class PdfReceiptService {
  static Future<void> generateAndDownloadReceipt(OrderModel order) async {
    final pdf = pw.Document();
    final bool isCod =
        order.orderType.toUpperCase() == 'COD' ||
        order.orderType.toUpperCase() == 'CASH ON DELIVERY';
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Kissan Fresh',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Order Receipt',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: isCod ? PdfColors.green50 : PdfColors.indigo50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      isCod ? 'CASH ON DELIVERY' : 'ONLINE PAYMENT',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: isCod ? PdfColors.green800 : PdfColors.indigo800,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Order Info
              _pdfInfoRow('Order Number', order.orderNumber),
              _pdfInfoRow('Order Date', dateFormat.format(order.orderDate)),
              _pdfInfoRow('Status', order.statusText),
              if (order.paymentId != null && order.paymentId!.isNotEmpty)
                _pdfInfoRow('Payment ID', order.paymentId!),
              _pdfInfoRow(
                'Payment Method',
                isCod ? 'Cash on Delivery' : 'Online Payment',
              ),
              _pdfInfoRow('Delivery Address', order.deliveryAddress),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Items header
              pw.Text(
                'Items',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                    children: [
                      _pdfTableCell('Item', isHeader: true),
                      _pdfTableCell('Qty', isHeader: true),
                      _pdfTableCell('Price', isHeader: true),
                      _pdfTableCell('Total', isHeader: true),
                    ],
                  ),
                  // Item rows
                  ...order.items.map(
                    (item) => pw.TableRow(
                      children: [
                        _pdfTableCell(item.title),
                        _pdfTableCell('${item.quantity}'),
                        _pdfTableCell('Rs.${item.price.toStringAsFixed(0)}'),
                        _pdfTableCell(
                          'Rs.${(item.price * item.quantity).toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _pdfTotalRow(
                      'Subtotal',
                      'Rs.${order.subtotal.toStringAsFixed(0)}',
                    ),
                    if (order.deliveryFee > 0)
                      _pdfTotalRow(
                        'Delivery Fee',
                        'Rs.${order.deliveryFee.toStringAsFixed(0)}',
                      ),
                    if (order.deliveryFee == 0)
                      _pdfTotalRow('Delivery Fee', 'FREE', isGreen: true),
                    if (order.discount > 0)
                      _pdfTotalRow(
                        'Discount',
                        '-Rs.${order.discount.toStringAsFixed(0)}',
                        isGreen: true,
                      ),
                    if (order.couponDiscount > 0)
                      _pdfTotalRow(
                        'Coupon Discount',
                        '-Rs.${order.couponDiscount.toStringAsFixed(0)}',
                        isGreen: true,
                      ),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Amount',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Rs.${order.totalAmount.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with Kissan Fresh!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Show print/share dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'KissanFresh_${order.orderNumber}',
    );
  }

  static pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _pdfTotalRow(String label, String value,
      {bool isGreen = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: isGreen ? PdfColors.green : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
