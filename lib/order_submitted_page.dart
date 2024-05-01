import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/order_details_page.dart';

class OrderSubmittedPage extends StatelessWidget {
  const OrderSubmittedPage({Key? key}) : super(key: key);

  Future<int> fetchSalesOrderId() async {
    int salesOrderId = 0;

    try {
      MySqlConnection conn = await connectToDatabase();
      final result = await readFirst(conn, 'cart', '', 'id DESC'); // Order by id in descending order

      if (result.isNotEmpty) {
        // Extract the 'id' field from the first row of the result
        salesOrderId = result['id'] as int;
      } else {
        // Handle case where no rows are found
        print('No sales order ID found in the cart table.');
      }

      await conn.close(); // Close the database connection
    } catch (e) {
      print("Error retrieving sales order ID: $e");
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
      ),
      body: FutureBuilder<int>(
        future: fetchSalesOrderId(), // Provide the future function here
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Display a loading indicator while waiting for the future to complete
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Handle error if the future encounters an error
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Extract the sales order ID from the completed future
            final salesOrderId = snapshot.data ?? 0; // Default to 0 if data is null

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
                            const Size(130.0, 40.0), // Set the width and height of the button
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
                                color: Color(0xff004c87), // Specify the color of the border here
                                width: 1.0, // Specify the width of the border here
                              ),
                            ),
                          ),
                          minimumSize: MaterialStateProperty.all<Size>(
                            const Size(120.0, 40.0), // Set the width and height of the button
                          ),
                          maximumSize: MaterialStateProperty.all<Size>(
                            const Size(150.0, 40.0), // Set the width and height of the button
                          ),
                        ),
                        child: const Text(
                          'View Order',
                          style: TextStyle(
                            color: const Color(0xff004c87),
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
