import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/customer.dart' as Customer;
import 'package:sales_navigator/customer_graph.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sales_navigator/sales_report_graph.dart';
import 'dart:developer' as developer;

class CustomerInsightPage extends StatefulWidget {
  final String customerName;

  const CustomerInsightPage({super.key, required this.customerName});

  @override
  _CustomerInsightPageState createState() => _CustomerInsightPageState();
}

class _CustomerInsightPageState extends State<CustomerInsightPage> {
  late Future<Customer.Customer> customerFuture;
  late Future<List<Map<String, dynamic>>> salesDataFuture;

  @override
  void initState() {
    super.initState();
    customerFuture = fetchCustomer();
    salesDataFuture = fetchSalesDataByCustomer();
  }

  Future<Customer.Customer> fetchCustomer() async {
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readFirst(
        conn,
        'customer',
        'company_name = "${widget.customerName}" AND status = 1',
        '',
      );
      await conn.close();

      if (results.isNotEmpty) {
        var row = results;
        return Customer.Customer(
          id: row['id'] as int?,
          area: row['area'] as int,
          userGroup: row['user_group'] as String? ?? '',
          companyName: row['company_name'] as String? ?? '',
          customerRate: row['customer_rate'] as int,
          username: row['username'] as String? ?? '',
          addressLine1: row['address_line_1'] as String? ?? '',
          addressLine2: row['address_line_2'] as String? ?? '',
          contactNumber: row['contact_number'] as String? ?? '',
          email: row['email'] as String? ?? '',
        );
      } else {
        throw Exception('Customer not found with company name: ${widget.customerName}');
      }
    } catch (e) {
      developer.log('Error fetching customer: $e', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSalesDataByCustomer() async {
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readData(
        conn,
        'cart',
        'created >= DATE_SUB(NOW(), INTERVAL 12 MONTH) AND customer_id = 6 GROUP BY YEAR(created), MONTH(created)',
        'sales_year DESC, sales_month DESC;',
        'YEAR(created) AS sales_year, MONTH(created) AS sales_month, SUM(final_total) AS total_sales',
      );
      await conn.close();
      return results;
    } catch (e) {
      developer.log('Error fetching sales data: $e', error: e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Customer Insight',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff004c87),
      ),
      backgroundColor: const Color(0xfff3f3f3),
      body: FutureBuilder(
        future: Future.wait([customerFuture, salesDataFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            Customer.Customer customer = snapshot.data![0] as Customer.Customer;

            if (customer.id == null) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Details',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No customer data found',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Details',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.companyName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${customer.addressLine1}${customer.addressLine2.isNotEmpty ? '\n${customer.addressLine2}' : ''}',
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Color(0xff191731),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                customer.contactNumber,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                customer.email,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Past Sales',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10.0),
                  const SizedBox(
                    height: 400.0,
                    child: SalesReport(),
                  ),
                  const SizedBox(
                    height: 180.0,
                    child: CustomersGraph(),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Recent Purchases',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    height: 150.0,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('Product ${index + 1}'),
                                Text('Amount: \$${(index + 1) * 50}'),
                              ],
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
        },
      ),
    );
  }
}

class SalesLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;

  const SalesLineChart({super.key, required this.salesData});

  @override
  Widget build(BuildContext context) {
    List<double> monthlySales = List.filled(12, 0);

    for (var data in salesData) {
      int month = data['sales_month'];
      double totalSales = data['total_sales'];

      monthlySales[month - 1] = totalSales; // Month index is zero-based in List
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: SideTitles(
            showTitles: true,
            margin: 10,
            getTitles: (value) {
              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              return months[value.toInt()]; // Use value to access month directly
            },
          ),
          leftTitles: SideTitles(
            showTitles: true,
            getTitles: (value) {
              // Custom formatting to display y-axis values by hundreds
              return '${(value ~/ 100).toInt()}00'; // Rounds to nearest hundred
            },
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey)),
        lineBarsData: [
          LineChartBarData(
            spots: monthlySales.asMap().entries.map((entry) {
              final index = entry.key;
              final sales = entry.value;
              return FlSpot(index.toDouble(), sales);
            }).toList(),
            isCurved: true,
            colors: [Colors.blue],
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}


