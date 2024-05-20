import 'package:flutter/material.dart';
import 'package:sales_navigator/home_page.dart';

class ClosedLeadItem extends StatelessWidget {
  final LeadItem leadItem;
  final String formattedCreatedDate;
  final String expirationDate;
  final String total;
  final String quantity;

  const ClosedLeadItem({
    Key? key,
    required this.leadItem,
    required this.formattedCreatedDate,
    required this.expirationDate,
    required this.total,
    required this.quantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedSalesOrderId = leadItem.salesOrderId != null
        ? 'SO' + leadItem.salesOrderId!.padLeft(7, '0')
        : '';
    double formattedTotal = double.parse(total);
    return Card(
      color: Color.fromARGB(255, 193, 255, 203),
      elevation: 2,
      margin: EdgeInsets.only(left: 8, right: 8, top: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leadItem.customerName.length > 15
                      ? leadItem.customerName.substring(0, 15) + '...'
                      : leadItem.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Color(0xff0069BA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
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
                Spacer(),
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
                const Icon(
                  Icons.phone,
                  color: Color(0xff0069BA),
                ),
                const SizedBox(width: 8),
                Text(
                  leadItem.contactNumber,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.email,
                  color: Color(0xff0069BA),
                ),
                const SizedBox(width: 8),
                Text(
                  leadItem.emailAddress,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formattedSalesOrderId,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(
              height: 8,
            ),
            Text('Created date: $formattedCreatedDate'),
            Text('Expiry date: $expirationDate'),
            const SizedBox(height: 8),
            Text(
              'Quantity: $quantity items      Total: ${formattedTotal.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created on: ${leadItem.createdDate}',
                  style: TextStyle(
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
