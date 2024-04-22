import 'package:flutter/material.dart';
import 'db_connection.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomersGraph extends StatefulWidget {
  const CustomersGraph({Key? key}) : super(key: key);

  @override
  _CustomersGraphState createState() => _CustomersGraphState();
}

class _CustomersGraphState extends State<CustomersGraph> {
  late Future<List<Customer>> customers;
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails().then((_) {
      customers = fetchCustomers();
    });
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? '';
    });
  }

  Future<List<Customer>> fetchCustomers() async {
    var db = await connectToDatabase();
    var results = await db.query(
        '''SELECT 
    c.company_name,
    ROUND(SUM(cart_item.total), 0) AS total_cart_value
FROM 
    cart
JOIN 
    cart_item ON cart.session = cart_item.session
JOIN 
    salesman ON cart.buyer_id = salesman.id
JOIN 
    (SELECT 
        c.ID AS customer_id, 
        c.company_name
    FROM 
        customer c
    JOIN 
        cart_item ci ON c.ID = ci.customer_id
    GROUP BY 
        c.ID, c.company_name
    ) AS c ON cart.customer_id = c.customer_id
WHERE 
    cart_item.status != 'void' AND
    salesman.username = '$loggedInUsername'  -- Filter by logged-in username
GROUP BY 
    c.company_name
ORDER BY 
    total_cart_value DESC
    LIMIT 5;

''');

    double sumOfCustomers = 0;
    for (var row in results) {
      sumOfCustomers += (row['total_cart_value'] as num).toDouble();
    }

    List<Customer> customers = [];
    for (var row in results) {
      final totalValue = (row['total_cart_value'] as num).toDouble();
      final percentageOfTotal = (totalValue / sumOfCustomers) * 100;
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Top Customers',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Customer>>(
          future: customers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
              return const Text('No data');
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

  String get totalSalesDisplay => 'RM ${NumberFormat("#,##0", "en_US").format(totalValue)}';
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
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                customer.totalSalesDisplay,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
