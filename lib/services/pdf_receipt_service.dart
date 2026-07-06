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
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header & Branding
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Kissan Fresh',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Tax Invoice / Bill of Supply',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'FSSAI Lic. No. 12345678901234',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: isCod ? PdfColors.green50 : PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(
                        color: isCod ? PdfColors.green200 : PdfColors.teal200,
                      ),
                    ),
                    child: pw.Text(
                      isCod ? 'CASH ON DELIVERY' : 'ONLINE PAYMENT',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: isCod ? PdfColors.green800 : PdfColors.teal800,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 12),

              // Order & Delivery Info in a grid-like layout
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Col
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfInfoBlock('Order ID', order.orderNumber),
                        _pdfInfoBlock('Order Date', dateFormat.format(order.orderDate)),
                        if (order.paymentId != null && order.paymentId!.isNotEmpty)
                          _pdfInfoBlock('Transaction ID', order.paymentId!),
                      ],
                    ),
                  ),
                  // Right Col
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfInfoBlock('Delivery Address', order.deliveryAddress),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 16),

              // Items table
              pw.Text(
                'Order Summary',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(1), // SN
                  1: const pw.FlexColumnWidth(5), // Item
                  2: const pw.FlexColumnWidth(1.5), // Qty
                  3: const pw.FlexColumnWidth(2), // Price
                  4: const pw.FlexColumnWidth(2), // Total
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
                    ),
                    children: [
                      _pdfTableCell('SN', isHeader: true),
                      _pdfTableCell('Item Name', isHeader: true),
                      _pdfTableCell('Qty', isHeader: true, alignRight: true),
                      _pdfTableCell('Price', isHeader: true, alignRight: true),
                      _pdfTableCell('Total', isHeader: true, alignRight: true),
                    ],
                  ),
                  // Item rows
                  ...List.generate(order.items.length, (index) {
                    final item = order.items[index];
                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
                      ),
                      children: [
                        _pdfTableCell('${index + 1}'),
                        _pdfTableCell(item.title),
                        _pdfTableCell('${item.quantity}', alignRight: true),
                        _pdfTableCell('Rs.${item.price.toStringAsFixed(2)}', alignRight: true),
                        _pdfTableCell('Rs.${(item.price * item.quantity).toStringAsFixed(2)}', alignRight: true),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals alignment
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 3, child: pw.SizedBox()),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColors.grey200),
                      ),
                      child: pw.Column(
                        children: [
                          _pdfTotalRow('Item Total', 'Rs.${order.subtotal.toStringAsFixed(2)}'),
                          _pdfTotalRow('Handling Fee', 'Rs.0.00'), // Standard in BlinkIt
                          if (order.deliveryFee > 0)
                            _pdfTotalRow('Delivery Partner Fee', 'Rs.${order.deliveryFee.toStringAsFixed(2)}'),
                          if (order.deliveryFee == 0)
                            _pdfTotalRow('Delivery Partner Fee', 'FREE', isGreen: true),
                          if (order.discount > 0)
                            _pdfTotalRow('Item Discount', '-Rs.${order.discount.toStringAsFixed(2)}', isGreen: true),
                          if (order.couponDiscount > 0)
                            _pdfTotalRow('Coupon Savings', '-Rs.${order.couponDiscount.toStringAsFixed(2)}', isGreen: true),
                          
                          pw.SizedBox(height: 8),
                          pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                          pw.SizedBox(height: 8),
                          
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Grand Total',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                'Rs.${order.totalAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.teal800,
                                ),
                              ),
                            ],
                          ),
                          if (order.discount > 0 || order.couponDiscount > 0) ...[
                            pw.SizedBox(height: 6),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.green50,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                'Your total savings: Rs.${(order.discount + order.couponDiscount).toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              
              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Terms & Conditions',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '1. Goods once sold cannot be returned unless defective.\n'
                        '2. For any queries, reach out to our support team.',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Need Help?',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'support@kissanfresh.com',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.teal700),
                      ),
                      pw.Text(
                        '+91 98765 43210',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.teal700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with Kissan Fresh!',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'KissanFresh_Invoice_${order.orderNumber}',
    );
  }

  static pw.Widget _pdfInfoBlock(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfTableCell(String text, {bool isHeader = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _pdfTotalRow(String label, String value, {bool isGreen = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label, 
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: isGreen ? PdfColors.green700 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
