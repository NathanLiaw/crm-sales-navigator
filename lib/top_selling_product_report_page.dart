import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_connection.dart';

void main() => runApp(const MyApp());

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

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    // Set the time to the end of today.
    DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    // Set the range for just the current day.
    _selectedDateRange = DateTimeRange(start: endOfToday, end: endOfToday);
    isSortedAscending = false;
    products = fetchProducts(_selectedDateRange);
  }

  Future<List<Product>> fetchProducts(DateTimeRange? dateRange) async {
    var db = await connectToDatabase();
    String dateRangeQuery = '';
    if (dateRange != null) {
      String startDate = DateFormat('yyyy/MM/dd').format(dateRange.start);
      String endDate = DateFormat('yyyy/MM/dd').format(dateRange.end);
      dateRangeQuery =
          "AND DATE_FORMAT(ci.created, '%Y/%m/%d') BETWEEN '$startDate' AND '$endDate'";
    }
    String sortOrder = isSortedAscending ? 'ASC' : 'DESC';
    try {
      var results = await db.query('''
        SELECT 
          b.id AS BrandID, 
          b.brand AS BrandName, 
          p.id AS ProductID, 
          p.product_name AS ProductName, 
          SUM(ci.qty) AS TotalQuantitySold, 
          SUM(ci.total) AS TotalSalesValue, 
          MAX(DATE_FORMAT(ci.created, '%Y-%m-%d')) AS created
        FROM cart_item ci 
        JOIN product p ON ci.product_id = p.id 
        JOIN brand b ON p.brand = b.id 
        WHERE 1 $dateRangeQuery 
        GROUP BY b.id, p.id 
        ORDER BY TotalQuantitySold $sortOrder;
      ''');

      if (results.isEmpty) {
        print("No data found");
      }

      int serialNumber = 1;
      return results.map((row) {
        return Product(
          id: row['ProductID'],
          brandId: row['BrandID'],
          productName: row['ProductName'],
          brandName: row['BrandName'],
          totalSales: row['TotalSalesValue'].toDouble(),
          totalQuantitySold: row['TotalQuantitySold'].toInt(),
          lastSold: DateTime.parse(row['created']),
          serialNumber: serialNumber++,
        );
      }).toList();
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
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
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: _selectedDateRange,
                    firstDate: DateTime(2019),
                    lastDate: DateTime.now(),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: Colors.lightBlue,
                                onPrimary: Colors.white,
                                surface:
                                    const Color.fromARGB(255, 212, 234, 255),
                              ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDateRange) {
                    setState(() {
                      _selectedDateRange = picked;
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
          EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = _selectedDateRange != null
        ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
                } else if (snapshot.hasData) {
                  return ListView(
                    children: snapshot.data!.map((product) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ExpansionTile(
                          backgroundColor: Colors.grey[200],
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product.serialNumber}. ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  product.productName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '     Total Quantity Sold: ${product.totalQuantitySold}',
                            style: const TextStyle(
                                color: Color.fromARGB(255, 0, 100, 0),
                                fontSize: 17,
                                fontWeight: FontWeight.w500),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, right: 20, top: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '    Product ID: ${product.id}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '    Brand Name: ${product.brandName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '    Total Sales: RM ${product.totalSales}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '    Last Sold: ${DateFormat('dd-MM-yyyy').format(product.lastSold)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

class Product {
  final int id;
  final int brandId;
  final String productName;
  final String brandName;
  final double totalSales;
  final int totalQuantitySold;
  final DateTime lastSold;
  final int serialNumber;

  Product({
    required this.id,
    required this.brandId,
    required this.productName,
    required this.brandName,
    required this.totalSales,
    required this.totalQuantitySold,
    required this.lastSold,
    required this.serialNumber,
  });

  String get totalSalesDisplay =>
      'RM ${NumberFormat("#,##0", "en_US").format(totalSales)}';
}
