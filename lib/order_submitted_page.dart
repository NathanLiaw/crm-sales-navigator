import 'package:flutter/material.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/order_details_page.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sales_navigator/utility_function.dart';

class OrderSubmittedPage extends StatefulWidget {
  final int salesOrderId;

  const OrderSubmittedPage({Key? key, required this.salesOrderId})
      : super(key: key);

  @override
  _OrderSubmittedPageState createState() => _OrderSubmittedPageState();
}

class _OrderSubmittedPageState extends State<OrderSubmittedPage> {
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
      body: Column(
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
                  'SO${widget.salesOrderId.toString().padLeft(7, '0')}',
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
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color(0xff0175FF)),
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
                        builder: (context) => OrderDetailsPage(
                          cartID: widget.salesOrderId,
                          fromOrderConfirmation: true,
                          fromSalesOrder: false,
                        ),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color(0xffffffff)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: const BorderSide(
                          color: Color(0xff0175FF),
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
      ),
    );
  }
}
