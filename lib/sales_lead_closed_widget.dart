import 'package:flutter/material.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ClosedLeadItem extends StatelessWidget {
  final LeadItem leadItem;
  final String formattedCreatedDate;
  final String expirationDate;
  final String total;
  final String quantity;

  const ClosedLeadItem({
    super.key,
    required this.leadItem,
    required this.formattedCreatedDate,
    required this.expirationDate,
    required this.total,
    required this.quantity,
  });

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    String formattedSalesOrderId = leadItem.salesOrderId != null
        ? 'SO${leadItem.salesOrderId!.padLeft(7, '0')}'
        : '';
    double formattedTotal = double.parse(total);

    return Card(
      color: const Color.fromARGB(255, 205, 229, 242),
      elevation: 2,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text(
                //   leadItem.customerName.length > 15
                //       ? '${leadItem.customerName.substring(0, 15)}...'
                //       : leadItem.customerName,
                //   style: const TextStyle(
                //     fontWeight: FontWeight.bold,
                //     fontSize: 20,
                //   ),
                //   overflow: TextOverflow.ellipsis,
                // ),
                Container(
                  width: 200,
                  child: Text(
                    leadItem.customerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Closed',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    // Perform an action based on the selected value
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'view details',
                      child: Text('View details'),
                    ),
                  ],
                  child: const Icon(Icons.more_horiz_outlined,
                      color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: leadItem.contactNumber.isNotEmpty
                      ? () => _launchURL('tel:${leadItem.contactNumber}')
                      : null,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        color: Color(0xff0069BA),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        leadItem.contactNumber.isNotEmpty
                            ? leadItem.contactNumber
                            : 'XXX-XXXXXXX',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: leadItem.emailAddress.isNotEmpty
                      ? () => _launchURL('mailto:${leadItem.emailAddress}')
                      : null,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email,
                        color: Color(0xff0069BA),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        leadItem.emailAddress.isNotEmpty
                            ? leadItem.emailAddress
                            : 'XXX@domain.com',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formattedSalesOrderId,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(
              height: 8,
            ),
            Text('Created date: $formattedCreatedDate'),
            Text('Expiry date: $expirationDate'),
            const SizedBox(height: 8),
            Text(
              leadItem.quantity != null
                  ? 'Quantity: $quantity items      Total: RM${_formatCurrency(formattedTotal)}'
                  : 'Quantity: Unknown      Total: RM${_formatCurrency(formattedTotal)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created on: ${leadItem.createdDate}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
