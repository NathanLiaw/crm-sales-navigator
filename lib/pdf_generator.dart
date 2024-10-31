import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'order_details_page.dart';
import 'package:open_file/open_file.dart';

class PdfInvoiceGenerator {
  Future<Uint8List> generateInvoicePdf({
    required String companyName,
    required String address,
    required String salesmanName,
    required String salesOrderId,
    required String createdDate,
    required String status,
    required List<OrderItem> orderItems,
    required double gst,
    required double sst,
  }) async {
    final pdf = pw.Document();

    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue900,
    );

    final headerStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue900,
    );

    final contentStyle = pw.TextStyle(
      fontSize: 14,
      color: PdfColors.black,
    );

    final smallStyle = pw.TextStyle(
      fontSize: 12,
      color: PdfColors.grey700,
    );

    double subtotal =
        orderItems.fold(0, (sum, item) => sum + double.parse(item.total));
    double gstAmount = subtotal * (gst / 100);
    double sstAmount = subtotal * (sst / 100);
    double total = subtotal + gstAmount + sstAmount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SALES ORDER', style: titleStyle),
                        pw.SizedBox(height: 10),
                        pw.Text(companyName, style: headerStyle),
                        pw.SizedBox(height: 5),
                        pw.ConstrainedBox(
                          constraints: const pw.BoxConstraints(maxWidth: 250),
                          child: pw.Text(address,
                              style: contentStyle,
                              maxLines: 3,
                              overflow: pw.TextOverflow.clip),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Order ID: $salesOrderId', style: headerStyle),
                        pw.SizedBox(height: 5),
                        pw.Text('Date: $createdDate', style: contentStyle),
                        pw.SizedBox(height: 5),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: status.toLowerCase() == 'confirm'
                                ? PdfColors.green200
                                : status.toLowerCase() == 'void'
                                    ? PdfColors.red200
                                    : PdfColors.orange200,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(5)),
                          ),
                          child: pw.Text(
                            status.toUpperCase(),
                            style: pw.TextStyle(
                              color: status.toLowerCase() == 'confirm'
                                  ? PdfColors.green900
                                  : status.toLowerCase() == 'void'
                                      ? PdfColors.red900
                                      : PdfColors.orange900,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('Salesman: ', style: headerStyle),
                      pw.Text(salesmanName, style: contentStyle),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
            );
          }
          return pw.Container();
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  border:
                      pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
                ),
                padding: const pw.EdgeInsets.only(top: 10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('This is not a tax invoice', style: smallStyle),
                    pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: smallStyle),
                  ],
                ),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Order Items', style: headerStyle),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.blue900),
                  headerHeight: 30,
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  headerAlignment: pw.Alignment.centerLeft,
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: contentStyle,
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  headers: [
                    'Product Name',
                    'UOM',
                    'Qty',
                    'Unit Price',
                    'Total'
                  ],
                  data: orderItems.map((item) {
                    return [
                      item.productName,
                      item.uom,
                      item.qty,
                      'RM ${item.unitPrice}',
                      'RM ${item.total}',
                    ];
                  }).toList(),
                ),
              ],
            ),
            // 使用 pw.SizedBox.shrink() 作为分隔
            pw.SizedBox.shrink(),
            // 将Summary和Company Details放在同一个Container中以保持它们在同一页
            pw.Container(
              child: pw.Column(
                children: [
                  // Summary Section
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    margin: const pw.EdgeInsets.symmetric(vertical: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _buildSummaryRow('Subtotal:',
                            subtotal.toStringAsFixed(2), contentStyle),
                        pw.SizedBox(height: 5),
                        _buildSummaryRow('GST (${gst.toStringAsFixed(2)}%):',
                            gstAmount.toStringAsFixed(2), contentStyle),
                        pw.SizedBox(height: 5),
                        _buildSummaryRow('SST (${sst.toStringAsFixed(2)}%):',
                            sstAmount.toStringAsFixed(2), contentStyle),
                        pw.SizedBox(height: 5),
                        pw.Divider(color: PdfColors.grey400),
                        _buildSummaryRow(
                            'Total:', total.toStringAsFixed(2), headerStyle),
                      ],
                    ),
                  ),
                  // 添加固定间距
                  pw.SizedBox(height: 40),
                  // Company Details
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Quest Marketing Kuching', style: headerStyle),
                        pw.Text('No. 137, A, Jalan Green,', style: smallStyle),
                        pw.Text('93150 Kuching, Sarawak, Malaysia.',
                            style: smallStyle),
                        pw.SizedBox(height: 5),
                        _buildContactRow('TEL: ',
                            '+6082-231 390, +60 16-878 6891', smallStyle),
                        _buildContactRow('FAX: ', '+6082-231 390', smallStyle),
                        _buildContactRow('EMAIL: ',
                            'questmarketingkch@gmail.com', smallStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Row _buildSummaryRow(String label, String value, pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(label, style: style),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 120,
          child: pw.Text(
            'RM $value',
            style: style,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  pw.Row _buildContactRow(String label, String value, pw.TextStyle style) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: style.copyWith(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(value, style: style),
      ],
    );
  }
}
