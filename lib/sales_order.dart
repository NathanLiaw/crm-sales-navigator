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
          // Changed text color to white
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
    
    // Set selectedDays to null since we're selecting a specific date, not a range like last 7 days.
    selectedDays = null;

    _loadSalesOrders(dateRange: dateRange);
  }


Future<void> _loadSalesOrders({int? days, DateTimeRange? dateRange}) async {
  setState(() => isLoading = true);
  String orderByClause = 'ORDER BY ci.created ${isSortedAscending ? 'ASC' : 'DESC'}';
  String query;

  if (dateRange != null) {
    // Custom date range query
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
$orderByClause;''';  // <-- Add order by clause here
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
$orderByClause;''';  // <-- And here
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
$orderByClause;''';  // <-- And also here
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
            _buildDateRangePicker(), // DatePicker with flexible width
            _buildSortButton(), // Sort button next to the DatePicker
          ],
        ),
        const SizedBox(height: 10),
        _buildQuickAccessDateButtons(), // Quick access date buttons below
        const SizedBox(height: 20),
      ],
    ),
  );
}



Widget _buildQuickAccessDateButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start, // Align to the start of the row
    children: [
      _buildDateButton('Last 7d', 7),
      const SizedBox(width: 8), // Provide some spacing between buttons
      _buildDateButton('Last 30d', 30),
      const SizedBox(width: 8), // Provide some spacing between buttons
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
            Icons.calendar_today, // Use the reference code icon
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
                ? Color(0xFF047CBD)
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
          dateRange = newRange; // Update the displayed date range
          _loadSalesOrders(days: days, dateRange: newRange);
        });
      },
      style: TextButton.styleFrom(
      backgroundColor: isSelected ? Color(0xFF047CBD) : const Color(0xFFD9D9D9), // Use blue for selected state
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Reduce the size of the buttons
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14, // Adjust font size if needed
        color: isSelected ? Colors.white : Colors.black, // White text for selected state
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
              primary: Color(0xFF004C87), // Changed primary color to #004C87
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
            null; // Reset any selection from the quick access buttons
        _loadSalesOrders(
            dateRange:
                dateRange); // Load sales orders for the selected date range
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
        // 'index' is the current item index in the list
        final order = orders[index];
        return _buildSalesOrderItem(
          index: index, // Pass 'index' here as the serial number for each item
          orderNumber: order['cart_item_id']?.toString() ?? 'N/A',
          companyName: order['company_name'] ?? 'Unknown Company',
          creationDate: order['created_date'] != null
              ? DateFormat('dd/MM/yyyy').parse(order['created_date'])
              : DateTime.now(),
          amount: '${order['total']?.toStringAsFixed(2) ?? '0.00'}',
          status: order['status'] ?? 'Unknown Status',
          items: [
            order['product_name'] ?? 'Unknown Product'
          ], // Assuming this is a list of strings
        );
      },
    );
  }

  Widget _buildSalesOrderItem({
    required int index, // The index for the serial number
    required String orderNumber,
    required String companyName,
    required DateTime creationDate,
    required String amount,
    required String
        status, // The status from the database, could be "In Progress"
    required List<String> items,
  }) {
    // Helper method to map the database status to the display status
    String getDisplayStatus(String status) {
      if (status == 'in progress') {
        return 'Pending';
      }
      return status;
    }

    // Helper method to get the status color
    Color getStatusColor(String displayStatus) {
      switch (displayStatus) {
        case 'Confirm':
          return Colors.green;
        case 'Pending': // Note that we use 'Pending' here now
          return const Color.fromARGB(255, 38, 0, 255);
        case 'Void':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    // Helper method to create a non-clickable status label
    Widget getStatusLabel(String status) {
      String displayStatus =
          getDisplayStatus(status); // Get the display version of the status

      return Container(
        
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: getStatusColor(displayStatus),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayStatus, // Use the display status here
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                Text(
                  '${index + 1}. $formattedOrderNumber', // Serial number and Order ID
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  companyName, // Company name
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Created on: ${DateFormat('dd-MM-yyyy').format(creationDate)}', // Created date
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RM $amount', // Amount
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    getStatusLabel(status), // Status label
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
                              child: Text(item,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 0, 0,
                                          0)))), // Changed text color to white
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              // Call addToCart method when copy button is pressed
                              // addToCart(item);
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
