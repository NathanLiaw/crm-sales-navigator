import 'dart:math';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'order_details_page.dart';
import 'package:intl/intl.dart';

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
    required double customerRate,
  }) async {
    final pdf = pw.Document();

    // Date formatting with time
    final DateFormat dateTimeFormat = DateFormat('dd MMM yyyy hh:mm a');
    final formattedDate = dateTimeFormat.format(DateTime.parse(createdDate));

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

    double subtotal = orderItems.fold(
        0,
        (sum, item) =>
            sum + (double.parse(item.unitPrice) * double.parse(item.qty)));
    double gstAmount = subtotal * (gst);
    double sstAmount = subtotal * (sst);
    double customerDiscountAmount = subtotal * (customerRate / 100);
    double total = subtotal - customerDiscountAmount + gstAmount + sstAmount;

    // Convert order items to table data with custom price column
    final List<List<dynamic>> tableData = orderItems.map((item) {
      double discountedTotal =
          double.parse(item.unitPrice) * double.parse(item.qty);
      double originalPrice = double.parse(item.oriUnitPrice);
      double discountedPrice = double.parse(item.unitPrice);

      print('Status: ${item.status}');
      print('Cancel: ${item.cancel}');

      // Create price column showing both original and discounted prices
      final priceColumn = pw.Container(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (originalPrice != discountedPrice) ...[
              pw.Text(
                originalPrice.toStringAsFixed(3),
                style: const pw.TextStyle(
                  decoration: pw.TextDecoration.lineThrough,
                  color: PdfColors.grey600,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                discountedPrice.toStringAsFixed(3),
                style: const pw.TextStyle(
                  fontSize: 14,
                ),
              ),
            ] else
              pw.Text(
                originalPrice.toStringAsFixed(3),
                style: const pw.TextStyle(
                  fontSize: 14,
                ),
              ),
          ],
        ),
      );

      String displayStatus = item.status == 'Void' && item.cancel != null
          ? item.cancel!
          : item.status;

      return [
        item.productName,
        item.uom,
        item.qty,
        displayStatus,
        priceColumn,
        discountedTotal.toStringAsFixed(3)
      ];
    }).toList();

    const int firstPageItems = 10;
    const int subsequentPageItems = 15;

    int remainingItems = tableData.length;
    int totalPages = 1;
    if (remainingItems > firstPageItems) {
      remainingItems -= firstPageItems;
      totalPages +=
          (remainingItems + subsequentPageItems - 1) ~/ subsequentPageItems;
    }

    // Helper function to build table
    pw.Widget buildTable(List<List<dynamic>> data,
        {bool includeHeader = true}) {
      return pw.Table(
        border: pw.TableBorder.all(
          color: PdfColors.grey400,
          width: 0.5,
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(1.5),
          5: const pw.FlexColumnWidth(1.5),
        },
        children: [
          if (includeHeader)
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blue900),
              children: [
                'Product Name',
                'UOM',
                'Qty',
                'Status',
                'Unit Price',
                'Total (RM)'
              ]
                  .map((header) => pw.Container(
                        alignment: header == 'Product Name'
                            ? pw.Alignment.centerLeft
                            : header == 'Unit Price' || header == 'Total (RM)'
                                ? pw.Alignment.centerRight
                                : pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        height: 30,
                        child: pw.Text(
                          header,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ...data.map((row) => pw.TableRow(
                children: List<pw.Widget>.generate(row.length, (idx) {
                  dynamic value = row[idx];

                  if (idx == 0) {
                    return pw.Container(
                      alignment: pw.Alignment.centerLeft,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        value.toString(),
                        style: const pw.TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  if (idx == 3) {
                    return pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        value.toString(),
                        style: const pw.TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return pw.Container(
                    alignment: idx == 0
                        ? pw.Alignment.centerLeft
                        : idx == 4 || idx == 5
                            ? pw.Alignment.centerRight
                            : pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(5),
                    child: value is pw.Widget
                        ? value
                        : pw.Text(
                            value.toString(),
                            style: const pw.TextStyle(
                              fontSize: 14,
                            ),
                          ),
                  );
                }),
              )),
        ],
      );
    }

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      int startIndex;
      int endIndex;

      if (pageNum == 0) {
        startIndex = 0;
        endIndex = tableData.length < firstPageItems
            ? tableData.length
            : firstPageItems;
      } else {
        startIndex = firstPageItems + (pageNum - 1) * subsequentPageItems;
        endIndex = min(startIndex + subsequentPageItems, tableData.length);
      }

      List<List<dynamic>> currentPageData =
          tableData.sublist(startIndex, endIndex);
      final isLastPage = pageNum == totalPages - 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pageNum == 0
              ? const pw.EdgeInsets.all(40)
              : const pw.EdgeInsets.only(
                  top: 20,
                  left: 40,
                  right: 40,
                  bottom: 40,
                ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (pageNum == 0) ...[
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
                            child: pw.Text(
                              address,
                              style: contentStyle,
                              maxLines: 3,
                              overflow: pw.TextOverflow.clip,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Order ID: $salesOrderId',
                              style: headerStyle),
                          pw.SizedBox(height: 5),
                          pw.Text('Date: $formattedDate', style: contentStyle),
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
                  pw.SizedBox(height: 10),
                  pw.Container(
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
                  pw.SizedBox(height: 10),
                  pw.Text('Order Items', style: headerStyle),
                  pw.SizedBox(height: 5),
                ] else ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Order ID: $salesOrderId', style: smallStyle),
                        pw.Text('Continued', style: smallStyle),
                      ],
                    ),
                  ),
                ],
                pageNum == 0
                    ? buildTable(currentPageData, includeHeader: true)
                    : pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 5),
                        child:
                            buildTable(currentPageData, includeHeader: false),
                      ),
                if (isLastPage) ...[
                  pw.SizedBox(height: 20),
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _buildSummaryRow('Subtotal:',
                            subtotal.toStringAsFixed(3), contentStyle),
                        pw.SizedBox(height: 5),
                        // Calculate total sales discount
                        () {
                          double originalTotal = orderItems.fold(
                              0,
                              (sum, item) =>
                                  sum +
                                  (double.parse(item.oriUnitPrice) *
                                      double.parse(item.qty)));
                          double salesDiscount =
                              (originalTotal - subtotal).abs();

                          // Only show sales discount if there is any discount
                          if (salesDiscount > 0) {
                            return pw.Column(
                              children: [
                                _buildSummaryRow(
                                    'Sales Discount:',
                                    '- ${salesDiscount.toStringAsFixed(3)}',
                                    contentStyle),
                                pw.SizedBox(height: 5),
                              ],
                            );
                          }
                          return pw.Container();
                        }(),
                        _buildSummaryRow('GST (${gst * 100}%):',
                            gstAmount.toStringAsFixed(3), contentStyle),
                        pw.SizedBox(height: 5),
                        _buildSummaryRow('SST (${sst * 100}%):',
                            sstAmount.toStringAsFixed(3), contentStyle),
                        pw.SizedBox(height: 5),
                        _buildSummaryRow(
                            'Customer Discount (${customerRate}%):',
                            '- ${customerDiscountAmount.toStringAsFixed(3)}',
                            contentStyle),
                        pw.SizedBox(height: 5),
                        pw.Divider(color: PdfColors.grey400),
                        _buildSummaryRow(
                            'Total:', total.toStringAsFixed(3), headerStyle),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
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
                pw.Expanded(child: pw.Container()),
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
                      pw.Text('Page ${pageNum + 1} of $totalPages',
                          style: smallStyle),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

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
        pw.Text(label, style: style.copyWith(fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: style),
      ],
    );
  }
}
