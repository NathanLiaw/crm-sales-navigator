import 'package:flutter/material.dart';
import 'package:sales_navigator/order_status_graph.dart';
import 'package:sales_navigator/sales_report_graph.dart';
import 'package:sales_navigator/sales_report_page.dart';
import 'package:sales_navigator/top_selling_product_graph.dart';
import 'package:sales_navigator/top_selling_product_report_page.dart';
import 'top_customer_graph.dart'; // Import your graph widgets here
import 'top_customer_report_page.dart';

class DataAnalyticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Analytics',
          style: TextStyle(color: Colors.white), // Set text color to white
        ),
        backgroundColor: Color(0xFF004C87), // Set app bar color to #004C87
        leading: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: IconThemeData(
                color: Colors.white), // Set back button color to white
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(
                  context); // Navigate back when the back button is pressed
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TopCustomerReport()), // Ensure you have this page
                  );
                },
                child: Container(
                  height: 425,
                  child: TopCustomersGraph(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SalesReportPage()), // Ensure you have this page
                  );
                },
                child: Container(
                  height: 425,
                  child: SalesReport(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TopSellingProductReport()),
                  );
                },
                child: Container(
                  height: 425,
                  child: TopSellingProductsPage(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //       builder: (context) =>
                  //           Order Status()),
                  // );
                },
                child: Container(
                  height: 425,
                  child: OrderStatusWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: DataAnalyticsPage(),
  ));
}
