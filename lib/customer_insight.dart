import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/customer.dart' as Customer;
import 'package:sales_navigator/customer_graph.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sales_navigator/item_screen.dart';
import 'package:sales_navigator/recent_order_page.dart';
import 'package:sales_navigator/sales_report_graph.dart';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';

class CustomerInsightPage extends StatefulWidget {
  final String customerName;

  const CustomerInsightPage({super.key, required this.customerName});

  @override
  _CustomerInsightPageState createState() => _CustomerInsightPageState();
}

class _CustomerInsightPageState extends State<CustomerInsightPage> {
  late Future<Customer.Customer> customerFuture;
  late Future<List<Map<String, dynamic>>> salesDataFuture;
  late Future<List<Map<String, dynamic>>> productsFuture;
  late int customerId = 0;

  @override
  void initState() {
    super.initState();
    customerFuture = fetchCustomer();
    salesDataFuture = fetchSalesDataByCustomer();
    productsFuture = fetchProductsByCustomer(customerId);
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
        setState(() {
          customerId = row['id'];
        });
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

  Future<List<Map<String, dynamic>>> fetchProductsByCustomer(int customerId) async {
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await conn.query('''
      SELECT p.product_name, p.photo1, ci.uom, COUNT(*) as number_of_items
      FROM cart_item ci
      JOIN product p ON ci.product_id = p.id
      JOIN (
        SELECT product_id, MIN(uom) AS first_uom
        FROM cart_item
        WHERE customer_id = $customerId
        GROUP BY product_id
      ) AS first_uom_per_product ON ci.product_id = first_uom_per_product.product_id
          AND ci.uom = first_uom_per_product.first_uom
      WHERE ci.customer_id = $customerId AND p.status = 1
      GROUP BY p.product_name, p.photo1, ci.uom
      LIMIT 10
    ''');
      await conn.close();
      return results.map((row) => {
        'product_name': row['product_name'],
        'photo1': row['photo1'],
        'uom': row['uom'],
      }).toList();
    } catch (e) {
      developer.log('Error fetching products: $e');
      return []; // Return empty list on error
    }
  }

  void _navigateToItemScreen(String selectedProductName) async {
    MySqlConnection conn = await connectToDatabase();

    try {
      final productData = await readData(
        conn,
        'product',
        'status = 1 AND product_name = "$selectedProductName"',
        '',
        'id, product_name, photo1, photo2, photo3, description, sub_category, price_by_uom',
      );

      if (productData.isNotEmpty) {
        Map<String, dynamic> product = productData.first;

        int productId = product['id'];
        String productName = product['product_name'];
        List<String> itemAssetName = [
          'https://haluansama.com/crm-sales/${product['photo1'] ?? 'null'}',
          'https://haluansama.com/crm-sales/${product['photo2'] ?? 'null'}',
          'https://haluansama.com/crm-sales/${product['photo3'] ?? 'null'}',
        ];
        Blob description = stringToBlob(product['description']);
        String priceByUom = product['price_by_uom'];

        // Navigate to ItemScreen and pass necessary parameters
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemScreen(
              productId: productId,
              productName: productName,
              itemAssetNames: itemAssetName,
              itemDescription: description,
              priceByUom: priceByUom,
            ),
          ),
        );
      } else {
        developer.log('Product not found for name: $selectedProductName');
      }
    } catch (e) {
      developer.log('Error fetching product details: $e', error: e);
    } finally {
      await conn.close();
    }
  }

  Blob stringToBlob(String data) {
    // Create a Blob instance from the string using Blob.fromString
    Blob blob = Blob.fromString(data);

    return blob;
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
        future: Future.wait([customerFuture, salesDataFuture, productsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            Customer.Customer customer = snapshot.data![0] as Customer.Customer;
            List<Map<String, dynamic>> products = snapshot.data![2] as List<Map<String, dynamic>>;

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
                  const SizedBox(height: 48.0),
                  const Text(
                    'Past Sales',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10.0),
                  const SizedBox(
                    height: 400.0,
                    child: SalesReport(),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    height: 180.0,
                    child: CustomersGraph(),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Purchases',
                        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RecentOrder(customerId: customer.id!,)),
                              );
                            },
                            child: const Text(
                              'View more',
                              style: TextStyle(fontSize: 16.0, color: Colors.grey),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ]
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    height: 250.0,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        var product = products[index];
                        final localPath = product['photo1'] ?? '';
                        final photoUrl = "https://haluansama.com/crm-sales/$localPath";
                        final productName = product['product_name'] ?? '';
                        final productUom = product['uom'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            _navigateToItemScreen(productName);
                          },
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Container for product photo
                                  SizedBox(
                                    width: 120.0, // Adjust according to your needs
                                    height: 120.0, // Adjust according to your needs
                                    child: CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      placeholder: (context, url) => const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Container for product name with fixed width
                                  SizedBox(
                                    width: 120.0, // Adjust according to your needs
                                    child: Text(
                                      productName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Container for product uom with fixed width
                                  SizedBox(
                                    width: 120.0, // Adjust according to your needs
                                    child: Text(
                                      productUom,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.grey),
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
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


