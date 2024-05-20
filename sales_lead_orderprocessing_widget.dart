import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/home_page.dart';

class OrderProcessingLeadItem extends StatelessWidget {
  final LeadItem leadItem;
  final String status;
  final Function(LeadItem) onMoveToClosed;

  const OrderProcessingLeadItem({
    Key? key,
    required this.leadItem,
    required this.status,
    required this.onMoveToClosed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedSalesOrderId = leadItem.salesOrderId != null
        ? 'SO' + leadItem.salesOrderId!.padLeft(7, '0')
        : '';

    List<String> statusInfo = status.split('|');
    String orderStatus = statusInfo[0];
    String createdDate = statusInfo[1];
    String expirationDate = statusInfo[2];
    String total = statusInfo[3];
    String formattedCreatedDate = _formatDate(createdDate);
    return Card(
      color: orderStatus == 'Pending'
          ? Color.fromARGB(255, 255, 237, 188)
          : Color.fromARGB(255, 205, 229, 242),
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
                  leadItem.customerName.length > 24
                      ? leadItem.customerName.substring(0, 24) + '...'
                      : leadItem.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: orderStatus == 'Pending'
                        ? Color.fromARGB(255, 255, 195, 31)
                        : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    orderStatus,
                    style: TextStyle(
                      color: orderStatus == 'Pending'
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
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
            Text('Created date: ${formattedCreatedDate}'),
            Text('Expiry date: $expirationDate'),
            const SizedBox(height: 8),
            Text(
              leadItem.quantity != null
                  ? 'Quantity: ${leadItem.quantity} items      Total: RM$total'
                  : 'Quantity: Unknown      Total: RM$total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Visibility(
                  visible: orderStatus == 'Confirm',
                  child: ElevatedButton(
                    onPressed: () => onMoveToClosed(leadItem),
                    child:
                        Text('Confirm', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff0069BA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      minimumSize: Size(50, 35),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View Order',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xff0069BA),
                      color: Color(0xff0069BA),
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  'Created on: ${leadItem.createdDate}',
                  style: TextStyle(
                    color: Colors.grey,
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

  String _formatDate(String dateString) {
    if (dateString == 'Unknown') {
      return dateString;
    }
    DateTime parsedDate = DateTime.parse(dateString);
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(parsedDate);
  }
}
