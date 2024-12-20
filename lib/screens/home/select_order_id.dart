import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/screens/sales_order/order_details_page.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SelectOrderIDPage extends StatefulWidget {
  final String customerName;

  const SelectOrderIDPage({super.key, required this.customerName});

  @override
  _SelectOrderIDPageState createState() => _SelectOrderIDPageState();
}

class _SelectOrderIDPageState extends State<SelectOrderIDPage> {
  late Future<List<Map<String, dynamic>>> salesOrdersFuture;

  @override
  void initState() {
    super.initState();
    salesOrdersFuture = fetchSalesOrders();
  }

  Future<List<Map<String, dynamic>>> fetchSalesOrders() async {
    String apiUrl =
        '${dotenv.env['API_URL']}/utility_function/get_sales_orders.php';

    try {
      final response = await http.get(Uri.parse(
          '$apiUrl?customer_name=${Uri.encodeComponent(widget.customerName)}'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        } else {
          developer
              .log('Error fetching sales orders: ${jsonResponse['message']}');
          return [];
        }
      } else {
        developer.log('Failed to fetch sales orders: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      developer.log('Error fetching sales orders: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        title: const Text(
          'Sales Order ID',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: salesOrdersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final salesOrders = snapshot.data ?? [];
            return buildOrderList(salesOrders);
          }
        },
      ),
    );
  }

  Widget buildOrderList(List<Map<String, dynamic>> salesOrders) {
    if (salesOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late,
              size: 80.0,
              color: Color(0xff0175FF),
            ),
            SizedBox(height: 20.0),
            Text(
              'No pending sales order for this customer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.w600,
                color: Color(0xff191731),
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              'Please check again later or contact support for assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                color: Color(0xff6b7280),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Sales Order ID',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Color(0xff191731),
            ),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: ListView.separated(
              itemCount: salesOrders.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final order = salesOrders[index];
                final cartID = order['id'];
                final formattedOrderID =
                    'SO${cartID.toString().padLeft(7, '0')}';
                final customer = order['customer_company_name'];
                final createdDate = order['created'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsPage(
                          cartID: cartID,
                          fromOrderConfirmation: false,
                          fromSalesOrder: false,
                        ),
                      ),
                    ).then((selectedOrderID) {
                      if (selectedOrderID != null) {
                        Navigator.pop(context, selectedOrderID);
                      }
                    });
                  },
                  child: Card(
                    elevation: 5.0,
                    color: const Color(0xffcde5f2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customer,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              const Text(
                                'View Details',
                                style: TextStyle(
                                  color: Colors.purple,
                                  decoration: TextDecoration.underline,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            formattedOrderID,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff191731),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Created: ${_formatDate(createdDate)}',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Color(0xff191731),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, cartID);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0069BA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text(
                              'Select',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) {
      return '';
    }
    DateTime parsedDate = DateTime.parse(dateString);
    DateFormat formatter = DateFormat('dd MMM yyyy hh:mm a');
    return formatter.format(parsedDate);
  }
}
