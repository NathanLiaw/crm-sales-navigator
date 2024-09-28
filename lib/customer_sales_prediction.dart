import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerSalesPrediction extends StatelessWidget {
  const CustomerSalesPrediction({super.key});

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
  const CustomerSalesPredictionPage({super.key});

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
      salesData = fetchSalesData(null);
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
    String startDate = dateRange != null
        ? DateFormat('yyyy-MM-dd').format(dateRange.start)
        : DateFormat('yyyy-MM-dd')
            .format(DateTime.now().subtract(const Duration(days: 30)));
    String endDate = dateRange != null
        ? DateFormat('yyyy-MM-dd').format(dateRange.end)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/predict_product_stock/get_predict_product_report.php?username=$loggedInUsername&startDate=$startDate&endDate=$endDate');

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> salesDataJson = jsonData['data'];

          print('Data Length: ${salesDataJson.length}');

          List<CustomerSalesData> salesDataList = salesDataJson.map((data) {
            return CustomerSalesData(
              productId: data['ProductID'],
              productName: data['ProductName'],
              totalQuantitySold: data['QuantitySold'],
              totalSalesValue: double.parse(data['SalesValue']),
              saleDate: DateTime.parse(data['SaleDate']),
              customerCompanyName: data['CustomerCompanyName'],
              unitOfMeasure: data['UnitOfMeasure'],
            );
          }).toList();

          return salesDataList;
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching sales data: $e');
      return [];
    }
  }

  List<CustomerSalesData> calculateMovingAverage(
      List<CustomerSalesData> data, int windowSize) {
    List<CustomerSalesData> movingAverages = [];

    for (int i = 0; i <= data.length - windowSize; i++) {
      var window = data.sublist(i, i + windowSize);
      double avgSalesValue =
          window.map((e) => e.totalSalesValue).reduce((a, b) => a + b) /
              windowSize;
      double avgQuantitySold =
          window.map((e) => e.totalQuantitySold).reduce((a, b) => a + b) /
              windowSize;
      double lastSalesValue = window.last.totalSalesValue;
      double growthRate = lastSalesValue / avgSalesValue;
      double predictedSales = avgSalesValue;
      double predictedStock = avgQuantitySold;
      if (growthRate > 1) {
        predictedSales = avgSalesValue * growthRate;
        predictedStock =
            avgQuantitySold * growthRate * 1.2;
      } else if (growthRate < 1) {
        predictedSales = avgSalesValue * growthRate;
        predictedStock =
            avgQuantitySold * growthRate * 0.8;
      }

      movingAverages.add(CustomerSalesData(
        productId: window.last.productId,
        productName: window.last.productName,
        totalQuantitySold: predictedStock.round(),
        totalSalesValue: predictedSales,
        saleDate: window.last.saleDate,
        customerCompanyName: window.last.customerCompanyName,
        unitOfMeasure: window.last.unitOfMeasure,
      ));
    }

    return movingAverages;
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
        backgroundColor: const Color(0xff0175FF),
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
                  developer.log('Snapshot data: ${snapshot.data!.length} items',
                      level: 1);

                  Map<String, List<CustomerSalesData>> groupedData = {};
                  for (var data in snapshot.data!) {
                    if (!groupedData.containsKey(data.customerCompanyName)) {
                      groupedData[data.customerCompanyName] = [];
                    }
                    groupedData[data.customerCompanyName]!.add(data);
                  }

                  return ListView(
                    children: groupedData.entries.map((entry) {
                      developer.log(
                          'Group: ${entry.key}, Items: ${entry.value.length}',
                          level: 1);
                      if (entry.value.length >= 3) {
                        var movingAverageData =
                            calculateMovingAverage(entry.value, 3);
                        if (movingAverageData.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    const Color.fromRGBO(111, 188, 249, 0.35),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ExpansionTile(
                                  backgroundColor: Colors.transparent,
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: EdgeInsets.zero,
                                  title: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Predicted Sales: RM${NumberFormat('#,##0').format(movingAverageData.last.totalSalesValue)}',
                                          style: const TextStyle(
                                            color: Color(0xFF487C08),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Predicted Stock: ${NumberFormat('#,##0').format(movingAverageData.last.totalQuantitySold)}',
                                          style: const TextStyle(
                                            color: Color(0xFF004072),
                                            fontSize: 15,
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
                                        children: movingAverageData
                                            .take(5)
                                            .map((salesData) {
                                          return Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                        horizontal: 16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Product: ${salesData.productName}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      'UOM: ${salesData.unitOfMeasure}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            'Targeted Sales: RM${NumberFormat('#,##0').format(salesData.totalSalesValue)}',
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                  0xFF004072),
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            'Required Stock: ${NumberFormat('#,##0').format(salesData.totalQuantitySold)}',
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                  0xFF487C08),
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            textAlign:
                                                                TextAlign.end,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (movingAverageData
                                                      .indexOf(salesData) !=
                                                  movingAverageData.length - 1)
                                                const Divider(
                                                  color: Colors.grey,
                                                  thickness: 1,
                                                ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox
                              .shrink();
                        }
                      } else {
                        return const SizedBox
                            .shrink(); 
                      }
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

  CustomerSalesData({
    required this.productId,
    required this.productName,
    required this.totalQuantitySold,
    required this.totalSalesValue,
    required this.saleDate,
    required this.customerCompanyName,
    required this.unitOfMeasure,
  });
}
