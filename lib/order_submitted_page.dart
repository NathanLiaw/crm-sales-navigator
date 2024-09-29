import 'package:flutter/material.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/order_details_page.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sales_navigator/utility_function.dart';

class OrderSubmittedPage extends StatefulWidget {
  const OrderSubmittedPage({super.key});

  @override
  _OrderSubmittedPageState createState() => _OrderSubmittedPageState();
}

class _OrderSubmittedPageState extends State<OrderSubmittedPage> {
  late int salesmanId = 3;

  @override
  void initState() {
    super.initState();
  }

  void _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    setState(() {
      salesmanId = id;
    });
  }

  Future<int> fetchSalesOrderId() async {
    int salesOrderId = 0;

    try {
      final response = await http.post(
        Uri.parse('https://haluansama.com/crm-sales/api/cart/get_sales_order_id.php?salesman_id=$salesmanId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          salesOrderId = responseData['sales_order_id'] as int;
        } else {
          // Handle error
          developer.log('Error: ${responseData['message']}');
        }
      } else {
        developer.log('Failed to fetch sales order ID. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error retrieving sales order ID: $e');
    }

    return salesOrderId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Order Submitted',
          style: TextStyle(color: Color(0xffF8F9FA)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CartPage(),
              ),
            );
          },
        ),
      ),
      body: FutureBuilder<int>(
        future: fetchSalesOrderId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final salesOrderId = snapshot.data ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 90.0),
                    Text(
                      'Thank you for your order.',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ORDER ID',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'SO${salesOrderId.toString().padLeft(7, '0')}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0, right: 16.0),
                        child: Text(
                          'Our administrator will respond to your order within two working days.',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 42.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              const Color(0xff0175FF)),
                          shape:
                          WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          minimumSize: WidgetStateProperty.all<Size>(
                            const Size(130.0, 40.0),
                          ),
                        ),
                        child: const Text(
                          'Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsPage(cartID: salesOrderId, fromOrderConfirmation: true, fromSalesOrder: false,),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              const Color(0xffffffff)),
                          shape:
                          WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              side: const BorderSide(
                                color: Color(0xff0175FF),
                                width: 1.0,
                              ),
                            ),
                          ),
                          minimumSize: WidgetStateProperty.all<Size>(
                            const Size(120.0, 40.0),
                          ),
                          maximumSize: WidgetStateProperty.all<Size>(
                            const Size(150.0, 40.0),
                          ),
                        ),
                        child: const Text(
                          'View Order',
                          style: TextStyle(
                            color: Color(0xff0175FF),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
