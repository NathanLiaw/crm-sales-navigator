import 'package:flutter/material.dart';
import 'db_connection.dart';
import 'package:intl/intl.dart';

class TopCustomersGraph extends StatefulWidget {
  @override
  _TopCustomersGraphState createState() => _TopCustomersGraphState();
}

class _TopCustomersGraphState extends State<TopCustomersGraph> {
  late Future<List<Customer>> topCustomers;

  @override
  void initState() {
    super.initState();
    topCustomers = fetchTopCustomers();
  }

  Future<List<Customer>> fetchTopCustomers() async {
    var db = await connectToDatabase();
    var results = await db.query(
        'SELECT c.company_name, ROUND(SUM(ci.total), 0) AS total_cart_value '
        'FROM customer c '
        'JOIN cart_item ci ON c.ID = ci.customer_id '
        'GROUP BY c.ID, c.company_name, c.Username '
        'ORDER BY total_cart_value DESC '
        'LIMIT 5;');

    double sumOfTopCustomers = 0;
    for (var row in results) {
      sumOfTopCustomers += (row['total_cart_value'] as num).toDouble();
    }

    List<Customer> customers = [];
    for (var row in results) {
      final totalValue = (row['total_cart_value'] as num).toDouble();
      final percentageOfTotal = (totalValue / sumOfTopCustomers) * 100;
      customers.add(Customer(
          row['company_name'].toString(), totalValue, percentageOfTotal));
    }
    await db.close();
    return customers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Top Customers',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 16),
        FutureBuilder<List<Customer>>(
          future: topCustomers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Container(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...snapshot.data!.map((customer) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomerBar(customer: customer),
                        )),
                  ],
                ),
              );
            } else {
              return Text('No data');
            }
          },
        ),
      ],
    );
  }
}

class Customer {
  final String name;
  final double totalValue;
  final double percentageOfTotal;

  Customer(this.name, this.totalValue, this.percentageOfTotal);

  String get totalSalesDisplay => 'RM ${NumberFormat("#,##0", "en_US").format(totalValue)}'; // Updated formatting
}

class CustomerBar extends StatelessWidget {
  final Customer customer;

  const CustomerBar({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                customer.name,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Increased font size to 18
                ),
              ),
              Text(
                customer.totalSalesDisplay,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16, // Increased font size to 18
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: customer.percentageOfTotal / 100,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
