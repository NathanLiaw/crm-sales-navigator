import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class CustomerSalesPrediction extends StatelessWidget {
  const CustomerSalesPrediction({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Sales Prediction',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme.light(
          primary: Colors.lightBlue,
          onPrimary: Colors.white,
          surface: Colors.lightBlue,
        ),
        iconTheme: const IconThemeData(color: Colors.lightBlue),
      ),
      home: const CustomerSalesPredictionPage(),
    );
  }
}

class CustomerSalesPredictionPage extends StatefulWidget {
  const CustomerSalesPredictionPage({Key? key}) : super(key: key);

  @override
  _CustomerSalesPredictionPageState createState() =>
      _CustomerSalesPredictionPageState();
}

class _CustomerSalesPredictionPageState
    extends State<CustomerSalesPredictionPage> {
  late Future<List<CustomerSalesData>> salesData = Future.value([]);
  DateTimeRange? _selectedDateRange;
  bool isSortedAscending = false;

  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences().then((_) {
      salesData = fetchSalesData(null); // Fetch all sales data initially
    });
  }

  Future<void> _loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? '';
    });
  }

  Future<List<CustomerSalesData>> fetchSalesData(
      DateTimeRange? dateRange) async {
    var db = await connectToDatabase();
    String dateRangeQuery = '';
    if (dateRange != null) {
      String startDate = DateFormat('yyyy/MM/dd').format(dateRange.start);
      String endDate = DateFormat('yyyy/MM/dd').format(dateRange.end);
      dateRangeQuery =
          "AND DATE_FORMAT(ci.created, '%Y/%m/%d') BETWEEN '$startDate' AND '$endDate'";
    }
    String sortOrder = isSortedAscending ? 'ASC' : 'DESC';
    String usernameCondition = loggedInUsername.isNotEmpty
        ? "AND salesman.username = '${loggedInUsername.replaceAll("'", "''")}'"
        : "";
    try {
      var results = await db.query('''
        SELECT 
          p.id AS ProductID, 
          p.product_name AS ProductName,
          SUM(ci.qty) AS TotalQuantitySold, 
          SUM(ci.total) AS TotalSalesValue, 
          MAX(DATE_FORMAT(ci.created, '%Y-%m-%d')) AS SaleDate,
          c.customer_company_name AS CustomerCompanyName,
          ci.uom AS UnitOfMeasure
        FROM cart_item ci 
        JOIN product p ON ci.product_id = p.id 
        LEFT JOIN cart ON ci.session = cart.session OR ci.cart_id = cart.id
        JOIN salesman ON cart.buyer_id = salesman.id
        JOIN cart c ON ci.session = c.session OR ci.id = c.id
        WHERE cart.status != 'void' $usernameCondition $dateRangeQuery
        GROUP BY p.id, p.product_name, c.customer_company_name, ci.uom
        ORDER BY TotalQuantitySold $sortOrder;
      ''');

      if (results.isEmpty) {
        developer.log('No data found', level: 1);
      }

      int serialNumber = 1;
      return results.map((row) {
        return CustomerSalesData(
          productId: row['ProductID'],
          productName: row['ProductName'],
          totalQuantitySold: row['TotalQuantitySold'].toInt(),
          totalSalesValue: row['TotalSalesValue'].toDouble(),
          saleDate: DateTime.parse(row['SaleDate']),
          customerCompanyName: row['CustomerCompanyName'],
          unitOfMeasure: row['UnitOfMeasure'],
          serialNumber: serialNumber++,
        );
      }).toList();
    } catch (e, stackTrace) {
      developer.log('Error fetching data: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  void toggleSortOrder() {
    setState(() {
      isSortedAscending = !isSortedAscending;
      salesData = fetchSalesData(_selectedDateRange);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF004C87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Customer Sales Prediction',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<CustomerSalesData>>(
              future: salesData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available'));
                } else if (snapshot.hasData) {
                  return ListView(
                    children: snapshot.data!.map((salesData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ListTile(
                          tileColor: Colors.grey[200],
                          title: Text(
                            salesData.customerCompanyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Quantity Sold: ${salesData.totalQuantitySold}',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 0, 100, 0),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Unit of Measure: ${salesData.unitOfMeasure}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  return const Center(child: Text('No data available'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerSalesData {
  final int productId;
  final String productName;
  final int totalQuantitySold;
  final double totalSalesValue;
  final DateTime saleDate;
  final String customerCompanyName;
  final String unitOfMeasure;
  final int serialNumber;

  CustomerSalesData({
    required this.productId,
    required this.productName,
    required this.totalQuantitySold,
    required this.totalSalesValue,
    required this.saleDate,
    required this.customerCompanyName,
    required this.unitOfMeasure,
    required this.serialNumber,
  });
}
