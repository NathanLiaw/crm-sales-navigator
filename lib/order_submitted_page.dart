import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/order_details_page.dart';
import 'dart:developer' as developer;

class OrderSubmittedPage extends StatelessWidget {
  const OrderSubmittedPage({super.key});

  Future<int> fetchSalesOrderId() async {
    int salesOrderId = 0;

    try {
      MySqlConnection conn = await connectToDatabase();
      final result = await readFirst(conn, 'cart', '', 'id DESC');

      if (result.isNotEmpty) {
        // Extract the 'id' field from the first row of the result
        salesOrderId = result['id'] as int;
      } else {
        developer.log('No sales order ID found in the cart table: $salesOrderId', level: 1);
      }

      await conn.close();
    } catch (e) {
      developer.log('Error retrieving sales order ID: $e', error: e);
    }

    return salesOrderId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
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
                              builder: (context) => HomePage(),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(const Color(0xff004c87)),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          minimumSize: MaterialStateProperty.all<Size>(
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
                              builder: (context) => OrderDetailsPage(cartID: salesOrderId),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(const Color(0xffffffff)),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              side: const BorderSide(
                                color: Color(0xff004c87),
                                width: 1.0,
                              ),
                            ),
                          ),
                          minimumSize: MaterialStateProperty.all<Size>(
                            const Size(120.0, 40.0),
                          ),
                          maximumSize: MaterialStateProperty.all<Size>(
                            const Size(150.0, 40.0),
                          ),
                        ),
                        child: const Text(
                          'View Order',
                          style: TextStyle(
                            color: Color(0xff004c87),
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