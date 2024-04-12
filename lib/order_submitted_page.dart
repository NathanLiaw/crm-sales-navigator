import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OrderSubmittedPage extends StatelessWidget {
  const OrderSubmittedPage({Key? key}) : super(key: key);

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
          const Padding(
            padding: EdgeInsets.only(
              top: 2.0,
              left: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER ID',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  'SO0000136',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: 16.0,
                    right: 16.0,
                  ),
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
                    Navigator.pushReplacementNamed(
                        context, 'edit_item_page');
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>
                      (const Color(0xff004c87)),
                    shape:
                    MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      Size(130.0, 40.0), // Set the width and height of the button
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
                const SizedBox(width: 16.0), // Horizontal gap between buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, 'sales_order_page');
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>
                      (const Color(0xffffffff)),
                    shape:
                    MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: BorderSide(
                          color: Color(0xff004c87), // Specify the color of the border here
                          width: 1.0, // Specify the width of the border here
                        ),
                      ),
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      Size(120.0, 40.0), // Set the width and height of the button
                    ),
                    maximumSize: MaterialStateProperty.all<Size>(
                      Size(150.0, 40.0), // Set the width and height of the button
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
      ),
    );
  }
}
