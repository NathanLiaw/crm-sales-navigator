import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/customer_Insights.dart';
// ignore: unused_import
import 'package:sales_navigator/customer_insight.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/order_details_page.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderProcessingLeadItem extends StatelessWidget {
  final LeadItem leadItem;
  final String status;
  final Function(LeadItem) onMoveToClosed;

  const OrderProcessingLeadItem({
    super.key,
    required this.leadItem,
    required this.status,
    required this.onMoveToClosed,
  });

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String _formatCurrency(String amount) {
    if (amount == 'Unknown') {
      return amount;
    }
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(double.parse(amount));
  }

  @override
  Widget build(BuildContext context) {
    String formattedSalesOrderId = leadItem.salesOrderId != null
        ? 'SO${leadItem.salesOrderId!.padLeft(7, '0')}'
        : '';

    List<String> statusInfo = status.split('|');
    String orderStatus = statusInfo[0];
    String createdDate = statusInfo[1];
    String expirationDate = statusInfo[2];
    String total = statusInfo[3];
    String formattedCreatedDate = _formatDate(createdDate);
    String formattedTotal = _formatCurrency(total);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerInsightsPage(
              customerName: leadItem.customerName,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Color.fromARGB(75, 117, 117, 117),
                spreadRadius: 0.1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ]),
        /* color: orderStatus == 'Pending'
            ? const Color.fromARGB(255, 255, 237, 188)
            : const Color.fromARGB(255, 205, 229, 242), */
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
                  //   leadItem.customerName.length > 24
                  //       ? '${leadItem.customerName.substring(0, 24)}...'
                  //       : leadItem.customerName,
                  //   style: const TextStyle(
                  //     fontWeight: FontWeight.bold,
                  //     fontSize: 20,
                  //   ),
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  SizedBox(
                    width: 250,
                    child: Text(
                      leadItem.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: orderStatus == 'Pending'
                          ? const Color.fromARGB(255, 255, 195, 31)
                          : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      orderStatus,
                      style: const TextStyle(
                        color: Colors.white,
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
                  GestureDetector(
                    onTap: leadItem.contactNumber.isNotEmpty
                        ? () => _launchURL('tel:${leadItem.contactNumber}')
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xff0175FF),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: Text(
                            leadItem.contactNumber.isNotEmpty
                                ? leadItem.contactNumber
                                : 'Unavailable',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                          color: Color(0xff0175FF),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 150,
                          child: Text(
                            leadItem.emailAddress.isNotEmpty
                                ? leadItem.emailAddress
                                : 'Unavailable',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xff0175FF)),
              ),
              const SizedBox(
                height: 8,
              ),
              Text('Created date: $formattedCreatedDate'),
              Text('Expiry date: $expirationDate'),
              const SizedBox(height: 8),
              Text(
                leadItem.quantity != null
                    ? 'Quantity: ${leadItem.quantity} items      Total: RM$formattedTotal'
                    : 'Quantity: Unknown      Total: RM$formattedTotal',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Visibility(
                    visible: orderStatus == 'Confirm',
                    child: ElevatedButton(
                      onPressed: () => onMoveToClosed(leadItem),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0069BA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        minimumSize: const Size(50, 35),
                      ),
                      child: const Text('Confirm',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsPage(
                            cartID: int.parse(leadItem.salesOrderId!),
                            fromOrderConfirmation: false,
                            fromSalesOrder: false,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'View Order',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xff0175FF),
                        color: Color(0xff0175FF),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Created on: ${leadItem.createdDate}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
