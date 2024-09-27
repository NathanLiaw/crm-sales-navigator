import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/customer.dart' as Customer;
import 'package:sales_navigator/db_connection.dart';
import 'dart:developer' as developer;
import 'package:sales_navigator/item_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sales_navigator/recent_order_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerInsightsPage extends StatefulWidget {
  final String customerName;

  const CustomerInsightsPage({super.key, required this.customerName});

  @override
  _CustomerInsightsPageState createState() => _CustomerInsightsPageState();
}

class _CustomerInsightsPageState extends State<CustomerInsightsPage> {
  late Future<Customer.Customer> customerFuture;
  late Future<List<Map<String, dynamic>>> salesDataFuture = Future.value([]);
  late Future<List<Map<String, dynamic>>> productsFuture = Future.value([]);
  late int customerId = 0;
  late String customerUsername = '';

  @override
  void initState() {
    super.initState();
    customerFuture = fetchCustomer().then((customer) {
      setState(() {
        customerId = customer.id;
        salesDataFuture = fetchSalesDataByCustomer(customerId);
        productsFuture = fetchProductsByCustomer(customerId);
      });
      return customer;
    });
  }

  Future<Customer.Customer> fetchCustomer() async {
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readFirst(
        conn,
        'customer',
        "company_name = '${widget.customerName}' AND status = 1",
        '',
      );
      await conn.close();

      if (results.isNotEmpty) {
        var row = results;
        setState(() {
          customerId = row['id'];
        });
        return Customer.Customer(
          id: row['id'] as int? ?? 0,
          companyName: row['company_name'] as String? ?? '',
          addressLine1: row['address_line_1'] as String? ?? '',
          addressLine2: row['address_line_2'] as String? ?? '',
          contactNumber: row['contact_number'] as String? ?? '',
          email: row['email'] as String? ?? '',
          customerRate: row['customer_rate'] != null
              ? row['customer_rate'].toString() // Convert int to String if necessary
              : '',
          discountRate: row['discount_rate'] as int? ?? 0,
        );
      } else {
        throw Exception('Customer not found with company name: ${widget.customerName}');
      }
    } catch (e) {
      developer.log('Error fetching customer: $e', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSalesDataByCustomer(int customerId) async {
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readData(
        conn,
        'cart',
        'created >= DATE_SUB(NOW(), INTERVAL 12 MONTH) AND customer_id = $customerId GROUP BY YEAR(created), MONTH(created)',
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
      SELECT p.id, p.product_name, p.photo1, ci.uom, COUNT(*) as number_of_items
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
        'product_id': row['id'],
        'product_name': row['product_name'],
        'photo1': row['photo1'],
        'uom': row['uom'],
      }).toList();
    } catch (e) {
      developer.log('Error fetching products: $e');
      return [];
    }
  }

  void navigateToItemScreen(int selectedProductId) async {
    final apiUrl =
        'https://haluansama.com/crm-sales/api/product/get_product_by_id.php?id=$selectedProductId';

    try {
      // Make an HTTP GET request to fetch the product details
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Check if the status is success and product data is present
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['product'] != null) {
          Map<String, dynamic> product = jsonResponse['product'];

          // Extract the product details from the JSON response
          int productId = product['id'];
          String productName = product['product_name'];
          List<String> itemAssetName = [
            'https://haluansama.com/crm-sales/${product['photo1'] ?? 'null'}',
            'https://haluansama.com/crm-sales/${product['photo2'] ?? 'null'}',
            'https://haluansama.com/crm-sales/${product['photo3'] ?? 'null'}',
          ];
          Blob description = stringToBlob(product['description']);
          String priceByUom = product['price_by_uom'] ?? '';

          // Navigate to ItemScreen and pass the necessary parameters
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
          developer.log(
              'Product not found or API returned error: ${jsonResponse['message']}');
        }
      } else {
        developer
            .log('Failed to fetch product details: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching product details: $e', error: e);
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
        title: Text(
          'Customer Insights',
          style: GoogleFonts.inter(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff0175FF),
        leading: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
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

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20)),
                      gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [Color(0xff0175FF), Color(0xffA5DBE7)])),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align children to the start
                    children: [
                      Container(
                        // Row 1 Insigts, Powered by AI
                        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              "icons/predictive_analytics.svg",
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Insights',
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(letterSpacing: -0.8),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        // Row 2 Customer Name and value,
                        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              // Wrap with Expanded to prevent overflow
                              child: Text(
                                widget.customerName,
                                style: GoogleFonts.inter(
                                  textStyle: const TextStyle(letterSpacing: -0.8),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xff94FFDF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'High Value',
                                style: TextStyle(
                                  color: Color(0xff008A64),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        // Row 3 Total Spent
                        margin: const EdgeInsets.only(
                          top: 22,
                          left: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_money,
                              size: 26,
                              color: Colors.white,
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Text(
                              'Total spent',
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(letterSpacing: -0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        // Row 3 Total Spent
                        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                        child: Text(
                          'RM 80,000,000',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(letterSpacing: -0.8),
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  // Customer Details Block
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Details',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(letterSpacing: -0.8),
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 14),
                          width: MediaQuery.of(context).size.width -
                              20, // Subtract horizontal margin
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                blurStyle: BlurStyle.normal,
                                color: Color.fromARGB(75, 117, 117, 117),
                                spreadRadius: 0.1,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Address:',
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(letterSpacing: -0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xff0175FF),
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width -
                                        48, // Adjust width
                                    child: Text(
                                      '${customer.addressLine1}${customer.addressLine2.isNotEmpty ? '\n${customer.addressLine2}' : ''}',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(letterSpacing: -0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            const Color.fromARGB(255, 25, 23, 49),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    // Wrap with Expanded
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Contact:',
                                          style: GoogleFonts.inter(
                                            textStyle:
                                                const TextStyle(letterSpacing: -0.8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xff0175FF),
                                          ),
                                        ),
                                        Text(
                                          customer.contactNumber,
                                          style: GoogleFonts.inter(
                                            textStyle:
                                                const TextStyle(letterSpacing: -0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: const Color.fromARGB(
                                                255, 25, 23, 49),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    // Wrap with Expanded
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Email address:',
                                          style: GoogleFonts.inter(
                                            textStyle:
                                                const TextStyle(letterSpacing: -0.8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xff0175FF),
                                          ),
                                        ),
                                        Text(
                                          customer.email,
                                          style: GoogleFonts.inter(
                                            textStyle:
                                                const TextStyle(letterSpacing: -0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: const Color.fromARGB(
                                                255, 25, 23, 49),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ]),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  // Statistics Block
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(letterSpacing: -0.8),
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          children: [
                            Expanded(
                              // Wrap with Expanded
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                height: 122,
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                  color: Color(0xFFECEDF5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Image.asset(
                                          "icons/Ai_star.png",
                                          width: 16,
                                          height: 16,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '6 Days',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(letterSpacing: -0.8),
                                        fontSize: 40,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xff0066FF),
                                      ),
                                    ),
                                    Text(
                                      'Predicted Next Visit',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(letterSpacing: -0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              // Wrap with Expanded
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                height: 122,
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                  color: Color(0xFFECEDF5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Image.asset(
                                          "icons/Ai_star.png",
                                          width: 16,
                                          height: 16,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Low',
                                          style: GoogleFonts.inter(
                                            textStyle:
                                                const TextStyle(letterSpacing: -0.8),
                                            fontSize: 40,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xffFF5454),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 14,
                                        ),
                                        const Icon(
                                          Icons.south_east,
                                          size: 44,
                                          color: Color(0xffFF5454),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Total Spend Group',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(letterSpacing: -0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        Row(
                          children: [
                            Expanded(
                              // Wrap with Expanded
                              child: Container(
                                height: 246,
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  boxShadow: [
                                    BoxShadow(
                                      blurStyle: BlurStyle.normal,
                                      color: Color.fromARGB(75, 117, 117, 117),
                                      spreadRadius: 0.1,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(
                                          top: 8, left: 10, right: 10),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Last Spending',
                                                style: GoogleFonts.inter(
                                                  textStyle: const TextStyle(
                                                      letterSpacing: -0.8),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'RM100,000',
                                            style: GoogleFonts.inter(
                                              textStyle:
                                                  const TextStyle(letterSpacing: -0.8),
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xff0066FF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 156,
                                      child: LineChart(
                                        LineChartData(
                                            gridData: FlGridData(show: false),
                                            borderData: FlBorderData(show: false),
                                            titlesData: FlTitlesData(show: false),
                                            minX: 0,
                                            maxX: 10,
                                            minY: 0,
                                            maxY: 10,
                                            lineBarsData: [
                                              LineChartBarData(
                                                  colors: [const Color(0xff0066FF)],
                                                  isCurved: true,
                                                  dotData: FlDotData(show: false),
                                                  belowBarData: BarAreaData(
                                                      show: true,
                                                      colors: [
                                                        const Color(0xff001AFF),
                                                        const Color(0xffFFFFFF)
                                                      ],
                                                      gradientFrom: const Offset(0.5, 0),
                                                      gradientTo: const Offset(0.5, 1)),
                                                  spots: [
                                                    FlSpot(0, 3),
                                                    FlSpot(3, 4),
                                                    FlSpot(4, 2.5),
                                                    FlSpot(6, 8),
                                                    FlSpot(8, 5),
                                                    FlSpot(10, 6),
                                                  ])
                                            ]),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              // Wrap with Expanded
                              child: Container(
                                height: 246,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: ResizeImage(
                                        AssetImage('asset/hgh_recency.png'),
                                        width: 100,
                                        height: 72),
                                    alignment: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  boxShadow: [
                                    BoxShadow(
                                      blurStyle: BlurStyle.normal,
                                      color: Color.fromARGB(75, 117, 117, 117),
                                      spreadRadius: 0.1,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(
                                          top: 8, left: 10, right: 10),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Recency',
                                                style: GoogleFonts.inter(
                                                  textStyle: const TextStyle(
                                                      letterSpacing: -0.8),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Image.asset(
                                                "icons/Ai_star.png",
                                                width: 16,
                                                height: 16,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            child: const Icon(
                                              Icons.arrow_upward,
                                              weight: 0.2,
                                              size: 74,
                                              color: Color(0xff29C194),
                                            ),
                                          ),
                                          Text(
                                            'High Recency',
                                            maxLines: 2,
                                            style: GoogleFonts.inter(
                                              textStyle: const TextStyle(
                                                  letterSpacing: -0.8),
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xff29C194),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20,),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Purchases',
                                style: GoogleFonts.inter(
                                  textStyle: const TextStyle(letterSpacing: -0.8),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => RecentOrder(customerId: customer.id)),
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
                          child: products.isEmpty
                              ? const Text('No purchases yet')
                              : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              var product = products[index];
                              final productId = product['product_id'] ?? 0;
                              final localPath = product['photo1'] ?? '';
                              final photoUrl = "https://haluansama.com/crm-sales/$localPath";
                              final productName = product['product_name'] ?? '';
                              final productUom = product['uom'] ?? '';

                              return GestureDetector(
                                onTap: () {
                                  navigateToItemScreen(productId);
                                },
                                child: Card(
                                  color: Colors.white,
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Container for product photo
                                        SizedBox(
                                          width: 120.0,
                                          height: 120.0,
                                          child: CachedNetworkImage(
                                            imageUrl: photoUrl.isNotEmpty ? photoUrl : 'asset/no_image.jpg',
                                            placeholder: (context, url) => const CircularProgressIndicator(),
                                            errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Container for product name with fixed width
                                        SizedBox(
                                          width: 120.0,
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
                                          width: 120.0,
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
                        const SizedBox(height: 20,),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recommended Products',
                                style: GoogleFonts.inter(
                                  textStyle: const TextStyle(letterSpacing: -0.8),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => RecentOrder(customerId: customer.id)),
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
                          child: products.isEmpty
                              ? const Text('No purchases yet')
                              : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              var product = products[index];
                              final productId = product['product_id'] ?? 0;
                              final localPath = product['photo1'] ?? '';
                              final photoUrl = "https://haluansama.com/crm-sales/$localPath";
                              final productName = product['product_name'] ?? '';
                              final productUom = product['uom'] ?? '';

                              return GestureDetector(
                                onTap: () {
                                  navigateToItemScreen(productId);
                                },
                                child: Card(
                                  color: Colors.white,
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Container for product photo
                                        SizedBox(
                                          width: 120.0,
                                          height: 120.0,
                                          child: CachedNetworkImage(
                                            imageUrl: photoUrl.isNotEmpty ? photoUrl : 'asset/no_image.jpg',
                                            placeholder: (context, url) => const CircularProgressIndicator(),
                                            errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Container for product name with fixed width
                                        SizedBox(
                                          width: 120.0,
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
                                          width: 120.0,
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
                      ]),
                )
              ],
            ),
          );
        }
      },
      ),
    );
  }
}
