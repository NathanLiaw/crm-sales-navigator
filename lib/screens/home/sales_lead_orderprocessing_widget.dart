import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/screens/customer_insight//customer_Insights.dart';
import 'package:sales_navigator/screens/home/home_page.dart';
import 'package:sales_navigator/screens/sales_order/order_details_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrderProcessingLeadItem extends StatelessWidget {
  final LeadItem leadItem;
  final String status;
  final Function(LeadItem) onMoveToClosed;
  final Function(LeadItem) onRemoveLead;

  const OrderProcessingLeadItem({
    super.key,
    required this.leadItem,
    required this.status,
    required this.onMoveToClosed,
    required this.onRemoveLead,
  });

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
    );
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email.trim(),
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  String _formatCurrency(String amount) {
    if (amount == 'Unknown') {
      return amount;
    }
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(double.parse(amount));
  }

  Future<void> _removeOrder(BuildContext context) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onRemoveLead(leadItem);
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_URL']}/sales_lead/void_sales_order.php?id=${leadItem.id}&salesman_id=${leadItem.salesmanId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          developer.log('Order deleted successfully');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sales lead deleted successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          developer.log('Failed to delete order: ${responseData['message']}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to delete order: ${responseData['message']}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        developer
            .log('HTTP request failed with status: ${response.statusCode}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete order. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
          ],
        ),
        margin: const EdgeInsets.only(left: 8, right: 8, top: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      leadItem.customerName,
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(letterSpacing: -0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 25, 23, 49),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: orderStatus == 'Pending'
                          ? const Color.fromARGB(255, 255, 195, 31)
                          : orderStatus == 'Void'
                              ? Colors.red
                              : Colors.green,
                      borderRadius: BorderRadius.circular(20),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: leadItem.contactNumber.isNotEmpty
                        ? () => _launchPhone('tel:${leadItem.contactNumber}')
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xff0175FF),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
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
                  GestureDetector(
                    onTap: leadItem.emailAddress.isNotEmpty
                        ? () => _launchEmail('mailto:${leadItem.emailAddress}')
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email,
                          color: Color(0xff0175FF),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
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
              const SizedBox(height: 8),
              Text('Created date: $formattedCreatedDate'),
              Text('Expiry date: $expirationDate'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    leadItem.quantity != null
                        ? 'Quantity: ${leadItem.quantity} items      Total: RM$formattedTotal'
                        : 'Quantity: Unknown      Total: RM$formattedTotal',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Visibility(
                    visible: orderStatus == 'Void',
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 32,
                      ),
                      onPressed: () => _removeOrder(context),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Visibility(
                    visible: orderStatus == 'Confirm',
                    child: ElevatedButton(
                      onPressed: () => onMoveToClosed(leadItem),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0175FF),
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
