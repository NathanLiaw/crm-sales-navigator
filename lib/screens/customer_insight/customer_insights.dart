import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/model/customer.dart' as Customer;
import 'dart:developer' as developer;
import 'package:sales_navigator/screens/product/item_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sales_navigator/screens/profile/recent_order_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CustomerInsightsPage extends StatefulWidget {
  final String customerName;

  const CustomerInsightsPage({super.key, required this.customerName});

  @override
  _CustomerInsightsPageState createState() => _CustomerInsightsPageState();
}

class _CustomerInsightsPageState extends State<CustomerInsightsPage> {
  late Future<Customer.Customer?> customerFuture;
  late Future<List<Map<String, dynamic>>> salesDataFuture = Future.value([]);
  late Future<List<Map<String, dynamic>>> productsFuture = Future.value([]);
  late Future<List<Map<String, dynamic>>> recommendationsFuture =
      Future.value([]);
  late int customerId = 0;
  late String customerUsername = '';
  double latestSpending = 0.00;
  List<Map<String, dynamic>> productRecommendations = [];
  late Completer<bool> _isLoadedCompleter;
  late Future<bool> isLoaded;
  String recency = 'Low';
  String nextVisit = '0';
  String totalSpendGroup = 'Low';
  String clusterLabel = 'Low';
  List<dynamic> customerData = [];
  Map<String, dynamic>? relevantCustomer;
  bool _customerFound = true;
  late Future<Map<String, dynamic>> orderStatsFuture = Future.value({});
  bool isOrderListExpanded = false;

  @override
  void initState() {
    super.initState();
    _isLoadedCompleter = Completer<bool>();
    isLoaded = _isLoadedCompleter.future;
    customerFuture = fetchCustomer();
  }

  Future<Map<String, dynamic>> fetchOrderStatistics(int customerId) async {
    try {
      final String url =
          '${dotenv.env['API_URL']}/customer_insights/get_order_statistics.php?customer_id=$customerId';
      developer.log('Fetching order statistics from: $url');

      final response = await http.get(Uri.parse(url));

      developer.log('Response status code: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to load order statistics: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching order statistics: $e');
      rethrow;
    }
  }

  Future<Customer.Customer?> fetchCustomer() async {
    try {
      String apiUrl =
          '${dotenv.env['API_URL']}/customer_insights/get_customer_data.php';
      final response = await http
          .get(Uri.parse('$apiUrl?company_name=${widget.customerName}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];

          setState(() {
            customerId = data['id'];
            _customerFound = true;
            orderStatsFuture = fetchOrderStatistics(customerId);
          });

          // Initialize all data fetching futures
          salesDataFuture = fetchSalesDataByCustomer(customerId);
          productsFuture = fetchProductsByCustomer(customerId);
          recommendationsFuture = fetchRecommendations(customerId);
          getRecency();
          getTotalSpendGroup();
          fetchPredictedVisitDay();
          fetchCustomerSegmentation();

          return Customer.Customer(
            id: data['id'] as int? ?? 0,
            companyName: data['company_name'] as String? ?? '',
            addressLine1: data['address_line_1'] as String? ?? '',
            addressLine2: data['address_line_2'] as String? ?? '',
            contactNumber: data['contact_number'] as String? ?? '',
            email: data['email'] as String? ?? '',
            customerRate: data['customer_rate'] != null
                ? data['customer_rate'].toString()
                : '',
            discountRate: data['discount_rate'] as int? ?? 0,
          );
        } else {
          setState(() {
            _customerFound = false;
          });
          return null;
        }
      } else {
        setState(() {
          _customerFound = false;
        });
        return null;
      }
    } catch (e) {
      developer.log('Error fetching customer: $e', error: e);
      setState(() {
        _customerFound = false;
      });
      return null;
    } finally {
      _isLoadedCompleter.complete(true);
    }
  }

  Future<List<Map<String, dynamic>>> fetchSalesDataByCustomer(
      int customerId) async {
    try {
      String apiUrl =
          '${dotenv.env['API_URL']}/customer_insights/get_customer_salesdata.php?customer_id=$customerId';

      final url = Uri.parse(apiUrl);

      final data = jsonDecode((await http.get(url)).body);

      if (data['status'] == 'success') {
        try {
          var latestSpendingData = data['latest_spending'];

          if (latestSpendingData != null &&
              latestSpendingData.containsKey('final_total')) {
            var finalTotal = await latestSpendingData['final_total'];

            if (finalTotal is String) {
              latestSpending = double.tryParse(finalTotal) ?? 0;
            } else if (finalTotal is int) {
              latestSpending = finalTotal.toDouble();
            } else {
              latestSpending = 0;
            }
          } else {
            developer
                .log('No latest spending data or final total key not found.');
          }
        } catch (e) {
          developer.log('Error fetching sales data: $e');
        }

        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error fetching sales data: $e', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductsByCustomer(
      int customerId) async {
    try {
      final String apiUrl =
          '${dotenv.env['API_URL']}/customer_insights/get_products_by_customer_id.php?customer_id=$customerId';

      final url = Uri.parse(apiUrl);
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error fetching products: $e', error: e);
      return [];
    }
  }

  void navigateToItemScreen(int selectedProductId) async {
    final apiUrl =
        '${dotenv.env['API_URL']}/product/get_product_by_id.php?id=$selectedProductId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' &&
            jsonResponse['product'] != null) {
          Map<String, dynamic> product = jsonResponse['product'];

          int productId = product['id'];
          String productName = product['product_name'];
          List<String> itemAssetName = [
            '${dotenv.env['IMG_URL']}/${product['photo1'] ?? 'null'}',
            '${dotenv.env['IMG_URL']}/${product['photo2'] ?? 'null'}',
            '${dotenv.env['IMG_URL']}/${product['photo3'] ?? 'null'}',
          ];
          Blob description = stringToBlob(product['description']);
          String priceByUom = product['price_by_uom'] ?? '';

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
    Blob blob = Blob.fromString(data);

    return blob;
  }

  Future<List<Map<String, dynamic>>> getProductRecommendations(
      String keyword) async {
    try {
      String apiUrl =
          '${dotenv.env['API_URL']}/customer_insights/get_product_recommendation.php?keyword=${Uri.encodeComponent(keyword)}';

      final url = Uri.parse(apiUrl);

      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error fetching product recommendations: $e');
      return [];
    }
  }

  // Function to fetch keywords based on the last 10 cart items
  Future<List<String>> fetchKeywords(int customerId) async {
    try {
      String sqlUrl =
          '${dotenv.env['API_URL']}/customer_insights/get_keywords.php?customer_id=$customerId';

      final url = Uri.parse(sqlUrl);

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        return List<String>.from(
            data['data'].map((item) => item['sub_category']) ?? '');
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error fetching keywords: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecommendations(
      int customerId) async {
    try {
      List<String> keywords = await fetchKeywords(customerId);
      List<Map<String, dynamic>> recommendations = [];

      for (String keyword in keywords) {
        List<Map<String, dynamic>> keywordRecommendations =
            await getProductRecommendations(keyword);
        recommendations.addAll(keywordRecommendations);
      }

      return recommendations;
    } catch (e) {
      developer.log('Error fetching recommendations: $e', error: e);
      return [];
    }
  }

  Future<void> fetchCustomerSegmentation() async {
    final String apiUrl =
        '${dotenv.env['API_URL']}/customer_segmentation/customer_segmentation_api.php';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final customerData = json.decode(response.body)['data'];

        int currentCustomerId = customerId;

        relevantCustomer = customerData.firstWhere(
          (customer) =>
              customer['customer_id'].toString() ==
              currentCustomerId.toString(),
          orElse: () => null,
        );

        if (relevantCustomer != null) {
          relevantCustomer!['recency_category'] =
              categorizeRecency(relevantCustomer!['days_since_last_purchase']);
          relevantCustomer!['Cluster_Label'] =
              categoriseTotalSpentGroup(relevantCustomer!['Cluster_Label']);
          developer.log('Relevant Customer Data: $relevantCustomer');
        }
      } else {
        throw Exception(
            'Failed to load customer segmentation: ${response.statusCode}');
      }
    } catch (error) {
      developer.log('Error fetching data: $error');
    }
  }

  String categoriseTotalSpentGroup(String totalSpentGroup) {
    if (totalSpentGroup == "Low") {
      totalSpendGroup = 'Low';
      clusterLabel = 'Low';
      return 'Low';
    } else if (totalSpentGroup == "Mid") {
      totalSpendGroup = 'Mid';
      clusterLabel = 'Mid';
      return 'Mid';
    } else {
      totalSpendGroup = 'High';
      clusterLabel = 'High';
      return 'High';
    }
  }

  Color getCustomerValueBgColor(String spendGroup) {
    if (totalSpendGroup == 'High') {
      // High spend group
      return const Color(0xff94FFDF);
    } else if (totalSpendGroup == 'Mid') {
      // Mid spend group
      return const Color(0xffF1F78B);
    } else {
      // Low spend group
      return const Color(0xffFF6666);
    }
  }

  Color getCustomerValueTextColor(String spendGroup) {
    if (spendGroup == 'High') {
      // High spend group
      return const Color(0xff008A64);
    } else if (spendGroup == 'Mid') {
      // Mid spend group
      return const Color(0xff808000);
    } else {
      // Low spend group
      return const Color(0xff840000);
    }
  }

  String categorizeRecency(int recency) {
    if (recency <= 30) {
      this.recency = 'High';
      return 'High';
    } else if (recency <= 90) {
      this.recency = 'Mid';
      return 'Mid';
    } else {
      this.recency = 'Low';
      return 'Low';
    }
  }

  Future<void> getRecency() async {
    final String apiUrl =
        '${dotenv.env['API_URL']}/customer_insights/get_recency.php?customer_id=$customerId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        setState(() {
          recency = jsonResponse.toString();
        });

        developer.log('Recency: $recency');
      } else {
        developer.log(
            'Failed to fetch recency. Status code: ${response.statusCode}');
      }
    } catch (error) {
      developer.log('Error occurred: $error');
    }
  }

  Future<void> getTotalSpendGroup() async {
    final String apiUrl =
        '${dotenv.env['API_URL']}/customer_insights/get_total_spend_group.php?customer_id=$customerId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        setState(() {
          totalSpendGroup = jsonResponse;
        });

        developer.log('Total Spend Group: $totalSpendGroup');
      } else {
        developer.log(
            'Failed to fetch total spend group. Status code: ${response.statusCode}');
      }
    } catch (error) {
      developer.log('Error occurred: $error');
    }
  }

  IconData _getSpendGroupIcon(String totalSpendGroup) {
    if (totalSpendGroup == 'High') {
      // High spend group
      return Icons.north_east;
    } else if (totalSpendGroup == 'Mid') {
      // Mid spend group
      return Icons.east;
    } else {
      // Low spend group
      return Icons.south_east;
    }
  }

  // Function to get the appropriate color based on totalSpendGroup value
  Color _getSpendGroupColor(String totalSpendGroup) {
    if (totalSpendGroup == 'High') {
      // High spend group
      return const Color(0xff29c194);
    } else if (totalSpendGroup == 'Mid') {
      // Mid spend group
      return const Color(0xffFFC300);
    } else {
      // Low spend group
      return const Color(0xffFF5454);
    }
  }

  IconData _getRecencyIcon(String recency) {
    if (recency == 'High') {
      // High spend group
      return Icons.north;
    } else if (recency == 'Mid') {
      // Mid spend group
      return Icons.east;
    } else {
      // Low spend group
      return Icons.south;
    }
  }

  Future<int?> fetchPredictedVisitDay() async {
    try {
      final response = await http.get(Uri.parse(
          '${dotenv.env['API_URL']}/customer_insights/get_next_visit.php?customer_id=$customerId'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          nextVisit = responseData['predicted_visit_day'].toString();
          developer.log(responseData['predicted_visit_day'].toString());
          return responseData['predicted_visit_day'];
        } else {
          developer.log('Error: ${responseData['message']}');
          return null;
        }
      } else {
        developer.log('Failed to load data: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      developer.log('Error occurred: $e');
      return null;
    }
  }

  Widget buildOrderStatistics(Map<String, dynamic> stats) {
    final numberFormat = NumberFormat("#,##0.000", "en_MY");

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.inter(
              textStyle: const TextStyle(letterSpacing: -0.8),
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Void Orders Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Void Orders',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${stats['void_count']}',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xffFF5454),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Completed Orders Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Completed',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${stats['completed_count']}',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff29c194),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pending Orders Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pending Orders',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '${(stats['pending_orders'] as List).length}',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xffFFA500),
                          ),
                        ),
                      ],
                    ),
                    if ((stats['pending_orders'] as List).isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isOrderListExpanded = !isOrderListExpanded;
                          });
                        },
                        child: Text(
                          isOrderListExpanded ? 'Show Less' : 'Show All',
                          style: const TextStyle(color: Color(0xff0175FF)),
                        ),
                      ),
                  ],
                ),
                if (isOrderListExpanded &&
                    (stats['pending_orders'] as List).isNotEmpty)
                  Column(
                    children: [
                      const Divider(height: 20),
                      ...List.generate(
                        (stats['pending_orders'] as List).length,
                        (index) {
                          final order = stats['pending_orders'][index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${order['id']}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                Text(
                                  'RM ${numberFormat.format(double.parse(order['final_total'].toString()))}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
      body: FutureBuilder<Customer.Customer?>(
        future: customerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError ||
              !_customerFound ||
              snapshot.data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 100,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'This customer is not registered.\nPlease contact the admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          } else {
            Customer.Customer customer = snapshot.data!;
            return FutureBuilder<List<dynamic>>(
              future: Future.wait([
                salesDataFuture,
                productsFuture,
                recommendationsFuture,
                isLoaded
              ]),
              builder: (context, salesSnapshot) {
                if (salesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Fetching Customer Details'),
                      ],
                    ),
                  );
                } else if (salesSnapshot.hasError) {
                  return Center(child: Text('Error: ${salesSnapshot.error}'));
                } else {
                  List<Map<String, dynamic>> salesData =
                      salesSnapshot.data![0] as List<Map<String, dynamic>>;
                  List<Map<String, dynamic>> products =
                      salesSnapshot.data![1] as List<Map<String, dynamic>>;
                  List<Map<String, dynamic>> recommendations =
                      salesSnapshot.data![2] as List<Map<String, dynamic>>;

                  String totalSpent = salesData.isNotEmpty
                      ? salesData
                          .map((entry) => entry['total_spent'] ?? '0.00')
                          .map((spent) => double.parse(spent.toString()))
                          .reduce((a, b) => (a + b))
                          .toString()
                      : '0.00';

                  String lastSpending = latestSpending.toString();

                  final formatter = NumberFormat("#,##0.000", "en_MY");
                  String formattedTotalSpent =
                      formatter.format(double.parse(totalSpent));
                  String formattedLastSpending =
                      formatter.format(double.parse(lastSpending));

                  Color spendGroupBgColor =
                      getCustomerValueBgColor(totalSpendGroup);
                  Color spendGroupTextColor =
                      getCustomerValueTextColor(totalSpendGroup);

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          width: MediaQuery.of(context).size.width,
                          decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20)),
                              gradient: LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                  colors: [
                                    Color(0xff0175FF),
                                    Color(0xffA5DBE7)
                                  ])),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      "asset/icons/predictive_analytics.svg",
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      'Insights',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                            letterSpacing: -0.8),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.customerName,
                                        style: GoogleFonts.inter(
                                          textStyle: const TextStyle(
                                              letterSpacing: -0.8),
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
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
                                        color: spendGroupBgColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$clusterLabel Value',
                                        style: TextStyle(
                                          color: spendGroupTextColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
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
                                        textStyle: const TextStyle(
                                            letterSpacing: -0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 16),
                                child: Text(
                                  'RM $formattedTotalSpent',
                                  style: GoogleFonts.inter(
                                    textStyle:
                                        const TextStyle(letterSpacing: -0.8),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          // Customer Details Block
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer Details',
                                  style: GoogleFonts.inter(
                                    textStyle:
                                        const TextStyle(letterSpacing: -0.8),
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
                                  width: MediaQuery.of(context).size.width - 20,
                                  decoration: const BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        blurStyle: BlurStyle.normal,
                                        color:
                                            Color.fromARGB(75, 117, 117, 117),
                                        spreadRadius: 0.1,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Address:',
                                            style: GoogleFonts.inter(
                                              textStyle: const TextStyle(
                                                  letterSpacing: -0.8),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xff0175FF),
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                48,
                                            child: Text(
                                              '${customer.addressLine1}${customer.addressLine2.isNotEmpty ? '\n${customer.addressLine2}' : ''}',
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    letterSpacing: -0.8),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: const Color.fromARGB(
                                                    255, 25, 23, 49),
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
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Contact:',
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        letterSpacing: -0.8),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xff0175FF),
                                                  ),
                                                ),
                                                Text(
                                                  customer.contactNumber,
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        letterSpacing: -0.8),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color.fromARGB(
                                                        255, 25, 23, 49),
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Email address:',
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        letterSpacing: -0.8),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xff0175FF),
                                                  ),
                                                ),
                                                Text(
                                                  customer.email,
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        letterSpacing: -0.8),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color.fromARGB(
                                                        255, 25, 23, 49),
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                        FutureBuilder<Map<String, dynamic>>(
                          future: orderStatsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return const Center(
                                  child:
                                      Text('Error loading order statistics'));
                            } else if (snapshot.hasData) {
                              return buildOrderStatistics(snapshot.data!);
                            } else {
                              return const SizedBox();
                            }
                          },
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          // Statistics Block
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Statistics',
                                  style: GoogleFonts.inter(
                                    textStyle:
                                        const TextStyle(letterSpacing: -0.8),
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
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 10),
                                        height: 122,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                          boxShadow: [
                                            BoxShadow(
                                              blurStyle: BlurStyle.normal,
                                              color: Color.fromARGB(
                                                  75, 117, 117, 117),
                                              spreadRadius: 0.1,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Image.asset(
                                                  "asset/icons/ai_star.png",
                                                  width: 16,
                                                  height: 16,
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '$nextVisit Days',
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    letterSpacing: -0.8),
                                                fontSize: 40,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xff0066FF),
                                              ),
                                            ),
                                            Text(
                                              'Predicted Next Visit',
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    letterSpacing: -0.6),
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
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 10),
                                        height: 122,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                          boxShadow: [
                                            BoxShadow(
                                              blurStyle: BlurStyle.normal,
                                              color: Color.fromARGB(
                                                  75, 117, 117, 117),
                                              spreadRadius: 0.1,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Image.asset(
                                                  "asset/icons/ai_star.png",
                                                  width: 16,
                                                  height: 16,
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  totalSpendGroup,
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        letterSpacing: -0.8),
                                                    fontSize: 40,
                                                    fontWeight: FontWeight.w700,
                                                    color: _getSpendGroupColor(
                                                        totalSpendGroup),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Icon(
                                                  _getSpendGroupIcon(
                                                      totalSpendGroup),
                                                  size: 44,
                                                  color: _getSpendGroupColor(
                                                      totalSpendGroup),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Total Spend Group',
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    letterSpacing: -0.6),
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
                                      child: Container(
                                        height: 246,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                          boxShadow: [
                                            BoxShadow(
                                              blurStyle: BlurStyle.normal,
                                              color: Color.fromARGB(
                                                  75, 117, 117, 117),
                                              spreadRadius: 0.1,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                        style:
                                                            GoogleFonts.inter(
                                                          textStyle:
                                                              const TextStyle(
                                                                  letterSpacing:
                                                                      -0.8),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        'RM $formattedLastSpending',
                                                        style:
                                                            GoogleFonts.inter(
                                                          textStyle:
                                                              const TextStyle(
                                                            letterSpacing: -0.8,
                                                            fontSize: 24,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Color(
                                                                0xff0066FF),
                                                          ),
                                                        ),
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: 156,
                                              child: LineChart(
                                                LineChartData(
                                                    lineTouchData:
                                                        LineTouchData(
                                                      enabled: false,
                                                    ),
                                                    gridData:
                                                        FlGridData(show: false),
                                                    borderData: FlBorderData(
                                                        show: false),
                                                    titlesData: FlTitlesData(
                                                        show: false),
                                                    minX: 0,
                                                    maxX: 10,
                                                    minY: 0,
                                                    maxY: 10,
                                                    lineBarsData: [
                                                      LineChartBarData(
                                                          colors: [
                                                            const Color(
                                                                0xff0066FF)
                                                          ],
                                                          isCurved: true,
                                                          dotData: FlDotData(
                                                            show: false,
                                                          ),
                                                          belowBarData: BarAreaData(
                                                              show: true,
                                                              colors: [
                                                                const Color(
                                                                    0xff001AFF),
                                                                const Color(
                                                                    0xffFFFFFF)
                                                              ],
                                                              gradientFrom:
                                                                  const Offset(
                                                                      0.5, 0),
                                                              gradientTo:
                                                                  const Offset(
                                                                      0.5, 1)),
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
                                      child: Container(
                                        height: 246,
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: ResizeImage(
                                                AssetImage(
                                                    'asset/hgh_recency.png'),
                                                width: 100,
                                                height: 72),
                                            alignment: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                          boxShadow: [
                                            BoxShadow(
                                              blurStyle: BlurStyle.normal,
                                              color: Color.fromARGB(
                                                  75, 117, 117, 117),
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Recency',
                                                        style:
                                                            GoogleFonts.inter(
                                                          textStyle:
                                                              const TextStyle(
                                                                  letterSpacing:
                                                                      -0.8),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      Image.asset(
                                                        "asset/icons/ai_star.png",
                                                        width: 16,
                                                        height: 16,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 4,
                                                  ),
                                                  Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Icon(
                                                      _getRecencyIcon(recency),
                                                      weight: 0.2,
                                                      size: 74,
                                                      color:
                                                          _getSpendGroupColor(
                                                              recency),
                                                    ),
                                                  ),
                                                  Text(
                                                    '$recency Recency',
                                                    maxLines: 2,
                                                    style: GoogleFonts.inter(
                                                      textStyle:
                                                          const TextStyle(
                                                              letterSpacing:
                                                                  -0.8),
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          _getSpendGroupColor(
                                                              recency),
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
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Recent Purchases',
                                        style: GoogleFonts.inter(
                                          textStyle: const TextStyle(
                                              letterSpacing: -0.8),
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: const Color.fromARGB(
                                              255, 0, 0, 0),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        RecentOrder(
                                                            customerId:
                                                                customer.id)),
                                              );
                                            },
                                            child: const Text(
                                              'View more',
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  color: Colors.grey),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            size: 24,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ]),
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
                                            final productId =
                                                product['product_id'] ?? 0;
                                            final localPath =
                                                product['photo1'] ?? '';
                                            final photoUrl =
                                                "${dotenv.env['IMG_URL']}/$localPath";
                                            final productName =
                                                product['product_name'] ?? '';
                                            final productUom =
                                                product['uom'] ?? '';

                                            return GestureDetector(
                                              onTap: () {
                                                navigateToItemScreen(productId);
                                              },
                                              child: Card(
                                                color: Colors.white,
                                                elevation: 1,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width: 120.0,
                                                        height: 120.0,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: photoUrl
                                                                  .isNotEmpty
                                                              ? photoUrl
                                                              : 'asset/no_image.jpg',
                                                          placeholder: (context,
                                                                  url) =>
                                                              const CircularProgressIndicator(),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(Icons
                                                                  .error_outline),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      SizedBox(
                                                        width: 120.0,
                                                        child: Text(
                                                          productName,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: const TextStyle(
                                                              fontSize: 14.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        width: 120.0,
                                                        child: Text(
                                                          productUom,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: const TextStyle(
                                                              fontSize: 12.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color:
                                                                  Colors.grey),
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
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Recommended Products',
                                        style: GoogleFonts.inter(
                                          textStyle: const TextStyle(
                                              letterSpacing: -0.8),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: const Color.fromARGB(
                                              255, 0, 0, 0),
                                        ),
                                      ),
                                    ]),
                                const SizedBox(height: 10.0),
                                SizedBox(
                                  height: 200.0,
                                  child: recommendations.isEmpty
                                      ? const Text('No purchases yet')
                                      : ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: recommendations.length > 50
                                              ? 50
                                              : recommendations.length,
                                          itemBuilder: (context, index) {
                                            var product =
                                                recommendations[index];
                                            final productId =
                                                product['product_id'] ?? 0;
                                            final localPath =
                                                product['photo1'] ?? '';
                                            final photoUrl =
                                                "${dotenv.env['IMG_URL']}/$localPath";
                                            final productName =
                                                product['product_name'] ?? '';

                                            return GestureDetector(
                                              onTap: () {
                                                navigateToItemScreen(productId);
                                              },
                                              child: Card(
                                                color: Colors.white,
                                                elevation: 1,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width: 120.0,
                                                        height: 120.0,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: photoUrl
                                                                  .isNotEmpty
                                                              ? photoUrl
                                                              : 'asset/no_image.jpg',
                                                          placeholder: (context,
                                                                  url) =>
                                                              const CircularProgressIndicator(),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(Icons
                                                                  .error_outline),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      SizedBox(
                                                        width: 120.0,
                                                        child: Text(
                                                          productName,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: const TextStyle(
                                                              fontSize: 14.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                          overflow: TextOverflow
                                                              .ellipsis,
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
            );
          }
        },
      ),
    );
  }
}
