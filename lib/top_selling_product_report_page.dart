import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_connection.dart'; // Assumes implementation of database connection logic

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Top Selling Product Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TopSellingProductReport(),
    );
  }
}

class TopSellingProductReport extends StatefulWidget {
  @override
  _TopSellingProductReportState createState() => _TopSellingProductReportState();
}

class _TopSellingProductReportState extends State<TopSellingProductReport> {
  late Future<List<Product>> topSellingProducts;
  String selectedSortOption = 'Top Product'; // Default selected sort option
  bool isSortedAscending = false; // Sort initially from highest to lowest total sales
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    topSellingProducts = fetchTopSellingProducts(isSortedAscending, _selectedDateRange);
    DateTime today = DateTime.now();
    _selectedDateRange = DateTimeRange(start: today, end: today);
  }

  Future<List<Product>> fetchTopSellingProducts(bool isAscending, DateTimeRange? dateRange) async {
    var db = await connectToDatabase();
    var sortOrder = isAscending ? 'ASC' : 'DESC';
    String dateRangeQuery = '';
    if (dateRange != null) {
      dateRangeQuery = "AND DATE(ci.created) BETWEEN '${DateFormat('yyyy-MM-dd').format(dateRange.start)}' AND '${DateFormat('yyyy-MM-dd').format(dateRange.end)}'";
    }
    var results = await db.query(
      '''
      SELECT 
        b.id AS `BrandID`, 
        b.brand AS `BrandName`, 
        p.id AS `ProductID`, 
        p.product_name AS `ProductName`, 
        SUM(ci.qty) AS `TotalQuantitySold`,
        SUM(ci.total) AS `TotalSalesValue`,
        MIN(ci.created) AS `FirstSoldDate`,
        MAX(ci.created) AS `LastSoldDate`
      FROM cart_item ci
      JOIN product p ON ci.product_id = p.id
      JOIN brand b ON p.brand = b.id
      WHERE 1 $dateRangeQuery
      GROUP BY b.id, p.id
      ORDER BY `TotalQuantitySold` $sortOrder;
      '''
    );

    return results.map((row) {
      DateTime parseDate(dynamic date) => date is String ? DateTime.parse(date) : date;
      return Product(
        brandId: row['BrandID'] as int,
        brandName: row['BrandName'],
        productId: row['ProductID'] as int,
        productName: row['ProductName'],
        totalQuantitySold: (row['TotalQuantitySold'] as num).toInt(),
        totalSalesValue: (row['TotalSalesValue'] as num).toDouble(),
        firstSoldDate: parseDate(row['FirstSoldDate']),
        lastSoldDate: parseDate(row['LastSoldDate']),
      );
    }).toList();
  }

  void toggleSortOrder() {
    setState(() {
      isSortedAscending = !isSortedAscending;
      topSellingProducts = fetchTopSellingProducts(isSortedAscending, _selectedDateRange);
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = _selectedDateRange != null ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}' : DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF004C87),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Set back button color to white
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Products Report',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {                      
                      final pickedDateRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                        initialDateRange: _selectedDateRange,
                      );
                      if (pickedDateRange != null) {
                        setState(() {
                          _selectedDateRange = pickedDateRange;
                          topSellingProducts = fetchTopSellingProducts(isSortedAscending, _selectedDateRange);
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                      decoration: BoxDecoration(color: Colors.lightBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(formattedDate, style: TextStyle(color: Colors.black, fontSize: 15)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedSortOption,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSortOption = newValue!;
                      isSortedAscending = newValue == 'Base Product';
                      topSellingProducts = fetchTopSellingProducts(isSortedAscending, _selectedDateRange);
                    });
                  },
                  items: ['Top Product', 'Base Product'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: topSellingProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error.toString()}'));
                } else if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final product = snapshot.data![index];
                      final serialNumber = index + 1;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ExpansionTile(
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$serialNumber. ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.productName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('Total Quantity Sold: ${product.totalQuantitySold}', style: TextStyle(color: Colors.black, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          children: <Widget>[
                            Container( // Add Container to create grey extension
                              color: Colors.grey[200],
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text('Brand Name: ${product.brandName}'),
                                    subtitle: Text('Brand ID: ${product.brandId}'),
                                  ),
                                  ListTile(
                                    title: Text('Product ID: ${product.productId}'),
                                  ),
                                  ListTile(
                                    title: Text('Total Sales Value: RM ${NumberFormat("#,##0.00", "en_US").format(product.totalSalesValue)}'),
                                  ),
                                  ListTile(
                                    title: Text('Last Sold Date: ${DateFormat('yyyy-MM-dd').format(product.lastSoldDate)}'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  return Center(child: Text('No data available'));
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
  final int brandId;
  final String brandName;
  final int productId;
  final String productName;
  final int totalQuantitySold;
  final double totalSalesValue;
  final DateTime firstSoldDate;
  final DateTime lastSoldDate;

  Product({
    required this.brandId,
    required this.brandName,
    required this.productId,
    required this.productName,
    required this.totalQuantitySold,
    required this.totalSalesValue,
    required this.firstSoldDate,
    required this.lastSoldDate,
  });
}
