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

    double subtotal =
        orderItems.fold(0, (sum, item) => sum + double.parse(item.total));
    double gstAmount = subtotal * (gst);
    double sstAmount = subtotal * (sst);
    double customerDiscountAmount = subtotal * (customerRate / 100);
    double total = subtotal - customerDiscountAmount + gstAmount + sstAmount;

    // Convert order items to table data for better handling
    final List<List<String>> tableData = orderItems.map((item) {
      return [
        item.productName,
        item.uom,
        item.qty,
        double.parse(item.unitPrice).toStringAsFixed(3),
        double.parse(item.total).toStringAsFixed(3),
      ];
    }).toList();

    // Calculate number of items per page
    const int firstPageItems = 10;
    const int subsequentPageItems = 15;

    // Calculate total pages needed
    int remainingItems = tableData.length;
    int totalPages = 1; // Start with 1 for the first page
    if (remainingItems > firstPageItems) {
      remainingItems -= firstPageItems;
      totalPages +=
          (remainingItems + subsequentPageItems - 1) ~/ subsequentPageItems;
    }

    // Generate pages
    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      // Calculate start and end indices for current page
      int startIndex;
      int endIndex;

      if (pageNum == 0) {
        // First page
        startIndex = 0;
        endIndex = tableData.length < firstPageItems
            ? tableData.length
            : firstPageItems;
      } else {
        // Follow-up page
        startIndex = firstPageItems + (pageNum - 1) * subsequentPageItems;
        endIndex = min(startIndex + subsequentPageItems, tableData.length);
      }

      List<List<String>> currentPageData =
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
                // First page header
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
                    // padding: const pw.EdgeInsets.all(10),
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
                ] else ...[
                  // Continuation header for subsequent pages
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

                // Table header text
                if (pageNum == 0) ...[
                  pw.Text('Order Items', style: headerStyle),
                  pw.SizedBox(height: 5),
                ],

                // Table
                pageNum == 0
                    ? pw.Table.fromTextArray(
                        border: pw.TableBorder.all(
                            color: PdfColors.grey400, width: 0.5),
                        headerDecoration:
                            pw.BoxDecoration(color: PdfColors.blue900),
                        headerHeight: 30,
                        headerStyle: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        headerAlignment: pw.Alignment.centerLeft,
                        cellAlignment: pw.Alignment.centerLeft,
                        cellStyle: contentStyle,
                        cellHeight: 30,
                        columnWidths: {
                          0: const pw.FlexColumnWidth(3),
                          1: const pw.FlexColumnWidth(1),
                          2: const pw.FlexColumnWidth(1),
                          3: const pw.FlexColumnWidth(1.5),
                          4: const pw.FlexColumnWidth(1.5),
                        },
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
                          'Total (RM)'
                        ],
                        data: currentPageData,
                      )
                    : pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Table.fromTextArray(
                          border: pw.TableBorder.all(
                              color: PdfColors.grey400, width: 0.5),
                          headerHeight: 30,
                          cellAlignment: pw.Alignment.centerLeft,
                          cellStyle: contentStyle,
                          cellHeight: 30,
                          columnWidths: {
                            0: const pw.FlexColumnWidth(3),
                            1: const pw.FlexColumnWidth(1),
                            2: const pw.FlexColumnWidth(1),
                            3: const pw.FlexColumnWidth(1.5),
                            4: const pw.FlexColumnWidth(1.5),
                          },
                          cellAlignments: {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.center,
                            2: pw.Alignment.center,
                            3: pw.Alignment.centerRight,
                            4: pw.Alignment.centerRight,
                          },
                          headers: null,
                          data: currentPageData,
                        ),
                      ),

                // Summary and company details for last page
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
                    // padding: const pw.EdgeInsets.all(10),
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

                // Footer
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
