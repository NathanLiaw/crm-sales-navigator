import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'dart:developer' as developer;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme.light(
          primary: Colors.lightBlue,
          onPrimary: Colors.white,
          surface: Colors.lightBlue,
        ),
        iconTheme: const IconThemeData(color: Colors.lightBlue),
      ),
      home: const ProductReport(),
    );
  }
}

class ProductReport extends StatefulWidget {
  const ProductReport({super.key});

  @override
  _ProductReportState createState() => _ProductReportState();
}

class _ProductReportState extends State<ProductReport> {
  late Future<List<Product>> products;
  DateTimeRange? _selectedDateRange;
  int selectedButtonIndex = -1;
  bool isSortedAscending = false;
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    products = Future.value([]);
    _loadPreferences().then((_) {
      setState(() {
        selectedButtonIndex = 3;
      });
      products = fetchProducts(null);
    });
  }

  Future<void> _loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? '';
    });
  }

  Future<List<Product>> fetchProducts(DateTimeRange? dateRange) async {
    var db = await connectToDatabase();
    String dateRangeQuery = '';
    if (dateRange != null) {
      String startDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(
        dateRange.start.year,
        dateRange.start.month,
        dateRange.start.day,
        0,
        0,
        0,
      ));
      String endDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(
        dateRange.end.year,
        dateRange.end.month,
        dateRange.end.day,
        23,
        59,
        59,
      ));
      dateRangeQuery = "AND ci.created BETWEEN '$startDate' AND '$endDate'";
    }
    String sortOrder = isSortedAscending ? 'ASC' : 'DESC';
    String usernameCondition = loggedInUsername.isNotEmpty
        ? "AND salesman.username = '${loggedInUsername.replaceAll("'", "''")}'"
        : "";
    try {
      var results = await db.query('''
      SELECT 
          b.id AS BrandID, 
          b.brand AS BrandName, 
          p.id AS ProductID, 
          p.product_name AS ProductName, 
          ci.uom AS UnitOfMeasure,
          SUM(ci.qty) AS TotalQuantitySold, 
          SUM(ci.total) AS TotalSalesValue, 
          MAX(DATE_FORMAT(ci.created, '%Y-%m-%d')) AS SaleDate
      FROM cart_item ci 
      JOIN product p ON ci.product_id = p.id 
      JOIN brand b ON p.brand = b.id 
      JOIN cart ON ci.session = cart.session OR ci.cart_id = cart.id
      JOIN salesman ON cart.buyer_id = salesman.id
      WHERE cart.status != 'void' $usernameCondition $dateRangeQuery
      GROUP BY p.id, ci.uom  -- Group by product and UOM to ensure correct aggregation
      ORDER BY TotalSalesValue $sortOrder;
    ''');

      if (results.isEmpty) {
        developer.log('No data found', level: 1);
      }

      int serialNumber = 1;
      return results.map((row) {
        return Product(
          id: row['ProductID'],
          brandId: row['BrandID'],
          productName: row['ProductName'],
          brandName: row['BrandName'],
          unitOfMeasure: row['UnitOfMeasure'],
          totalSales: row['TotalSalesValue'].toDouble(),
          totalQuantitySold: row['TotalQuantitySold'].toInt(),
          lastSold: DateTime.parse(row['SaleDate']),
          serialNumber: serialNumber++,
        );
      }).toList();
    } catch (e, stackTrace) {
      developer.log('Error fetching data: $e',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  void queryAllData() {
    setState(() {
      _selectedDateRange = null;
      selectedButtonIndex = 3;
      products = fetchProducts(null);
    });
  }

  void toggleSortOrder() {
    setState(() {
      isSortedAscending = !isSortedAscending;
      products = fetchProducts(_selectedDateRange);
    });
  }

  void setDateRange(int days, int selectedIndex) {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(days: days));
    setState(() {
      _selectedDateRange = DateTimeRange(start: start, end: now);
      isSortedAscending = false;
      products = fetchProducts(_selectedDateRange);
      selectedButtonIndex = selectedIndex;
    });
  }

  Widget _buildFilterButtonAndDateRangeSelection(String formattedDate) {
    final bool isCustomRangeSelected = selectedButtonIndex == -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 5.0),
              child: TextButton.icon(
                onPressed: () async {
                  final DateTimeRange? picked = await showRangePickerDialog(
                    context: context,
                    minDate: DateTime(2019),
                    maxDate: DateTime.now(),
                    selectedRange: _selectedDateRange,
                  );
                  if (picked != null && picked != _selectedDateRange) {
                    DateTime adjustedStartDate = DateTime(
                      picked.start.year,
                      picked.start.month,
                      picked.start.day,
                      0,
                      0,
                      0,
                    );

                    DateTime adjustedEndDate = DateTime(
                      picked.end.year,
                      picked.end.month,
                      picked.end.day,
                      23,
                      59,
                      59,
                    );

                    setState(() {
                      _selectedDateRange = DateTimeRange(
                          start: adjustedStartDate, end: adjustedEndDate);
                      selectedButtonIndex = 3;
                      products = fetchProducts(_selectedDateRange);
                    });
                  }
                },
                icon: Icon(
                  Icons.calendar_today,
                  color: isCustomRangeSelected ? Colors.white : Colors.black,
                ),
                label: Text(
                  formattedDate,
                  style: TextStyle(
                    color: isCustomRangeSelected ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (isCustomRangeSelected) {
                        return const Color(0xFF047CBD);
                      }
                      return const Color(0xFFD9D9D9);
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (isCustomRangeSelected) {
                        return Colors.white;
                      }
                      return Colors.black;
                    },
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: toggleSortOrder,
              icon: Icon(
                isSortedAscending ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.black,
              ),
              label: const Text(
                'Sort',
                style: TextStyle(color: Colors.black),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD9D9D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              _buildTimeFilterButton(
                  'All', () => queryAllData(), selectedButtonIndex == 3),
              const SizedBox(width: 10),
              _buildTimeFilterButton('Last 7d', () => setDateRange(7, 0),
                  selectedButtonIndex == 0),
              const SizedBox(width: 10),
              _buildTimeFilterButton('Last 30d', () => setDateRange(30, 1),
                  selectedButtonIndex == 1),
              const SizedBox(width: 10),
              _buildTimeFilterButton('Last 90d', () => setDateRange(90, 2),
                  selectedButtonIndex == 2),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTimeFilterButton(
      String text, VoidCallback onPressed, bool isSelected) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return isSelected
                ? const Color(0xFF047CBD)
                : const Color(0xFFD9D9D9);
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return isSelected ? Colors.white : Colors.black;
          },
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = _selectedDateRange != null
        ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} '
            '- ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
        : DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF004C87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title:
            const Text('Product Report', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: _buildFilterButtonAndDateRangeSelection(formattedDate),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available'));
                } else {
                  return ListView(
                    children: snapshot.data!.map((product) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(111, 188, 249, 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ExpansionTile(
                              backgroundColor: Colors.transparent,
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${product.serialNumber}. ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      product.productName,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '     UOM: ',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            product.unitOfMeasure,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '     Total Sales: ${product.totalSalesDisplay}',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 0, 100, 0),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '     Total Quantity Sold: ${product.totalQuantitySold}',
                                      style: const TextStyle(
                                        color: Color(0xFF004072),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1F5FE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '      Product ID: ${product.id}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 17),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '      Brand Name: ${product.brandName}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 17),
                                            ),
                                            Text(
                                              '      Last Sold: ${DateFormat('dd-MM-yyyy').format(product.lastSold)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 17),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(color: Colors.transparent),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final int id;
  final int brandId;
  final String productName;
  final String brandName;
  final String unitOfMeasure;
  final double totalSales;
  final int totalQuantitySold;
  final DateTime lastSold;
  final int serialNumber;

  Product({
    required this.id,
    required this.brandId,
    required this.productName,
    required this.brandName,
    required this.unitOfMeasure,
    required this.totalSales,
    required this.totalQuantitySold,
    required this.lastSold,
    required this.serialNumber,
  });

  String get totalSalesDisplay =>
      NumberFormat.currency(symbol: 'RM', decimalDigits: 3, locale: 'en_US')
          .format(totalSales);
}
