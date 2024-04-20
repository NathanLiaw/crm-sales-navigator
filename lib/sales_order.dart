import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_connection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Order',
      theme: ThemeData(
        primaryColor: const Color(0xFF004C87),
        hintColor: const Color(0xFF004C87),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const SalesOrderPage(),
    );
  }
}

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

  @override
  _SalesOrderPageState createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  DateTimeRange? dateRange;
  int? selectedDays;
  bool isSortedAscending = false;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    // Set the time to the start of today.
    DateTime startOfToday = DateTime(now.year, now.month, now.day);
    // Set the time to the end of today.
    DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    dateRange = DateTimeRange(start: startOfToday, end: endOfToday);
    selectedDays = null;

    _loadSalesOrders(dateRange: dateRange);
  }

  Future<void> _loadSalesOrders({int? days, DateTimeRange? dateRange}) async {
    setState(() => isLoading = true);
    String orderByClause =
        'ORDER BY ci.created ${isSortedAscending ? 'ASC' : 'DESC'}';
    String query;

    if (dateRange != null) {
      String startDate = DateFormat('yyyy-MM-dd').format(dateRange.start);
      String endDate = DateFormat('yyyy-MM-dd').format(dateRange.end);
      query = '''
SELECT 
  ci.id AS cart_item_id,
  ci.status,
  ci.product_name,
  ci.product_id,
  DATE_FORMAT(ci.created, '%d/%m/%Y') AS created_date,
  ci.total,
  ci.customer_id,
  c.company_name
FROM cart_item ci
JOIN Customer c ON ci.customer_id = c.id
WHERE ci.created BETWEEN '$startDate' AND '$endDate'
$orderByClause;'''; 
    } else if (days != null) {
      query = '''
SELECT 
  ci.id AS cart_item_id,
  ci.status,
  ci.product_name,
  ci.product_id,
  DATE_FORMAT(ci.created, '%d/%m/%Y') AS created_date,
  ci.total,
  ci.customer_id,
  c.company_name
FROM cart_item ci
JOIN Customer c ON ci.customer_id = c.id
WHERE ci.created >= DATE_SUB(CURDATE(), INTERVAL $days DAY)
$orderByClause;'''; 
    } else {
      query = '''
SELECT 
  ci.id AS cart_item_id,
  ci.status,
  ci.product_name,
  ci.product_id,
  DATE_FORMAT(ci.created, '%d/%m/%Y') AS created_date,
  ci.total,
  ci.customer_id,
  c.company_name
FROM cart_item ci
JOIN Customer c ON ci.customer_id = c.id
$orderByClause;'''; 
    }

    try {
      orders = await executeQuery(query);
    } catch (e) {
      print('Failed to load orders: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Order',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF004C87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          _buildFilterSection(),
          Expanded(child: _buildSalesOrderList()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateRangePicker(),
              _buildSortButton(), 
            ],
          ),
          const SizedBox(height: 8),
          _buildQuickAccessDateButtons(), 
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuickAccessDateButtons() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.start, 
      children: [
        _buildDateButton('Last 7d', 7),
        const SizedBox(width: 8), 
        _buildDateButton('Last 30d', 30),
        const SizedBox(width: 8), 
        _buildDateButton('Last 90d', 90),
      ],
    );
  }

  void toggleSortOrder() {
    setState(() {
      isSortedAscending = !isSortedAscending;
      _loadSalesOrders(days: selectedDays, dateRange: dateRange);
    });
  }

  Widget _buildSortButton() {
    return TextButton.icon(
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
    );
  }

  Widget _buildDateRangePicker() {
    final bool isCustomRangeSelected = dateRange != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          onPressed: () => _selectDateRange(context),
          icon: Icon(
            Icons.calendar_today,
            color: isCustomRangeSelected
                ? Colors.white
                : Theme.of(context).iconTheme.color,
          ),
          label: Text(
            isCustomRangeSelected
                ? '${DateFormat('dd/MM/yyyy').format(dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange!.end)}'
                : 'Filter Date',
            style: TextStyle(
              color: isCustomRangeSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: isCustomRangeSelected
                ? const Color(0xFF047CBD)
                : const Color(0xFFD9D9D9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(String text, int days) {
    bool isSelected = selectedDays == days;
    return TextButton(
      onPressed: () {
        DateTime now = DateTime.now();
        DateTime startDate = now.subtract(Duration(days: days));
        DateTime endDate = now;
        DateTimeRange newRange = DateTimeRange(start: startDate, end: endDate);

        setState(() {
          selectedDays = days;
          dateRange = newRange;
          _loadSalesOrders(days: days, dateRange: newRange);
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFF047CBD)
            : const Color(0xFFD9D9D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isSelected
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context,
      {DateTimeRange? predefinedRange}) async {
    DateTimeRange? newDateRange = predefinedRange;

    newDateRange ??= await showDateRangePicker(
      context: context,
      initialDateRange: dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004C87),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      setState(() {
        dateRange = newDateRange;
        selectedDays =
            null;
        _loadSalesOrders(
            dateRange:
                dateRange);
      });
    }
  }

  Widget _buildSalesOrderList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildSalesOrderItem(
          index: index, 
          orderNumber: order['cart_item_id']?.toString() ?? 'N/A',
          companyName: order['company_name'] ?? 'Unknown Company',
          creationDate: order['created_date'] != null
              ? DateFormat('dd/MM/yyyy').parse(order['created_date'])
              : DateTime.now(),
          amount: '${order['total']?.toStringAsFixed(2) ?? '0.00'}',
          status: order['status'] ?? 'Unknown Status',
          items: [
            order['product_name'] ?? 'Unknown Product'
          ],
        );
      },
    );
  }

  Widget _buildSalesOrderItem({
    required int index,
    required String orderNumber,
    required String companyName,
    required DateTime creationDate,
    required String amount,
    required String
        status,
    required List<String> items,
  }) {

    String getDisplayStatus(String status) {
      if (status == 'in progress') {
        return 'Pending';
      }
      return status;
    }


    Color getStatusColor(String displayStatus) {
      switch (displayStatus) {
        case 'Confirm':
          return Colors.green;
        case 'Pending':
          return const Color.fromARGB(255, 38, 0, 255);
        case 'Void':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    Widget getStatusLabel(String status) {
      String displayStatus =
          getDisplayStatus(status);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: getStatusColor(displayStatus),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayStatus,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    String formattedOrderNumber = 'S${orderNumber.toString().padLeft(7, '0')}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. $formattedOrderNumber',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            companyName, 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Created on: ${DateFormat('dd-MM-yyyy').format(creationDate)}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'RM $amount',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    getStatusLabel(status),
                  ],
                ),
              ],
            ),
          ),
          ExpansionTile(
            title: const Text(
              'Items',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                            },
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
