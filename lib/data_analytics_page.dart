import 'package:flutter/material.dart';
import 'package:sales_navigator/order_status_graph.dart';
import 'package:sales_navigator/sales_report_graph.dart';
import 'package:sales_navigator/sales_report_page.dart';
import 'package:sales_navigator/top_selling_product_graph.dart';
import 'package:sales_navigator/top_selling_product_report_page.dart';
import 'customer_graph.dart';
import 'customer_report_page.dart';
import 'sales_order.dart';
class DataAnalyticsPage extends StatelessWidget {
  const DataAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Analytics',
          style: TextStyle(color: Colors.white), 
        ),
        backgroundColor: const Color(0xFF004C87),
        leading: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(
                color: Colors.white),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(
                  context);
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
                            const SalesReportPage()), 
                  );
                },
                child: const SizedBox(
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
                        builder: (context) =>
                            const CustomerReport()),
                  );
                },
                child: Container(
                  child: CustomersGraph(),
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
                        builder: (context) => const ProductReport()),
                  );
                },
                child: const SizedBox(
                  height: 425,
                  child: TopSellingProductsPage(),
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
                        builder: (context) =>const SalesOrderPage()),
                  );
                },
                child: const SizedBox(
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
  runApp(const MaterialApp(
    home: DataAnalyticsPage(),
  ));
}
