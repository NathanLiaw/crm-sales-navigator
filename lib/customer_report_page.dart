import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_connection.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme.light(
          primary: Colors.lightBlue,
          onPrimary: Colors.white,
          surface: Colors.lightBlue,
        ),
        iconTheme: const IconThemeData(
            color: Colors.lightBlue),
      ),
      home: const CustomerReport(),
    );
  }
}

class CustomerReport extends StatefulWidget {
  const CustomerReport({super.key});

  @override
  _CustomerReportState createState() => _CustomerReportState();
}

class _CustomerReportState extends State<CustomerReport> {
  late Future<List<Customer>> customers;
  bool isSortedAscending = false;
  DateTimeRange? _selectedDateRange;
  int selectedButtonIndex = -1;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    // Set the time to the end of today.
    DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    // Set the range for just the current day.
    _selectedDateRange = DateTimeRange(start: endOfToday, end: endOfToday);
    isSortedAscending = false;
    customers = fetchCustomers(isSortedAscending, _selectedDateRange);
  }

  Future<List<Customer>> fetchCustomers(
      bool isAscending, DateTimeRange? dateRange) async {
    var db = await connectToDatabase();
    var sortOrder = isAscending ? 'ASC' : 'DESC';
    String dateRangeQuery = '';
    if (dateRange != null) {
      dateRangeQuery =
          "AND DATE(ci.created) BETWEEN '${DateFormat('yyyy-MM-dd').format(dateRange.start)}' AND '${DateFormat('yyyy-MM-dd').format(dateRange.end)}'";
    }
    var results = await db.query(
        'SELECT c.id AS Customer_ID, c.username AS Username, c.company_name AS Company_Name, c.email AS Email, c.contact_number AS Contact_Number, SUM(ci.total) AS Total_Sales, MAX(ci.created) AS Last_Purchase FROM customer c LEFT JOIN cart_item ci ON c.id = ci.customer_id WHERE 1 $dateRangeQuery GROUP BY c.id ORDER BY Total_Sales $sortOrder;');
    int serialNumber = 1;
    List<Customer> customersList = results.map((row) {
      return Customer(
        id: row['Customer_ID'] as int,
        companyName: row['Company_Name'].toString(),
        username: row['Username'].toString(),
        email: row['Email'].toString(),
        contactNumber: row['Contact_Number'].toString(),
        totalSales: row['Total_Sales'] as double,
        lastPurchase: DateTime.parse(row['Last_Purchase'].toString()),
        serialNumber: serialNumber++,
      );
    }).toList();
    await db.close();
    return customersList;
  }

  void toggleSortOrder() {
    setState(() {
      isSortedAscending = !isSortedAscending;
      customers = fetchCustomers(isSortedAscending, _selectedDateRange);
    });
  }

  void setDateRange(int days, int selectedIndex) {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(days: days));
    setState(() {
      _selectedDateRange = DateTimeRange(start: start, end: now);
      customers = fetchCustomers(isSortedAscending, _selectedDateRange);
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
                          surface: const Color.fromARGB(255, 212, 234, 255),
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
                    customers =
                        fetchCustomers(isSortedAscending, _selectedDateRange);
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
            _buildTimeFilterButton('Last 7d', () => setDateRange(7, 0), selectedButtonIndex == 0),
            const SizedBox(width: 10),
            _buildTimeFilterButton('Last 30d', () => setDateRange(30, 1), selectedButtonIndex == 1),
            const SizedBox(width: 10),
            _buildTimeFilterButton('Last 90d', () => setDateRange(90, 2), selectedButtonIndex == 2),
          ],
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
}

Widget _buildTimeFilterButton(String text, VoidCallback onPressed, bool isSelected) {
  return TextButton(
    onPressed: onPressed,
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          return isSelected ? const Color(0xFF047CBD) : const Color(0xFFD9D9D9);
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
        title: const Text('Customer Report',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: _buildFilterButtonAndDateRangeSelection(formattedDate),
          ),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: customers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return ListView(
                    children: snapshot.data!.map((customer) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: 
                        
                        ExpansionTile(
  backgroundColor: Colors.grey[200],
  title: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${customer.serialNumber}. ',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(width: 3),
      Expanded(
        child: Text(
          customer.companyName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  ),
  subtitle: Align(
    alignment: Alignment.centerLeft,
    child: Text(
      '     Total Sales: ${customer.totalSalesDisplay}',
      style: const TextStyle(color: Color.fromARGB(255, 0, 100, 0), fontSize: 17, fontWeight: FontWeight.w500),
    ),
  ),
  children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '    ID: ${customer.id}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              '    Username: ${customer.username}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              '    Email: ${customer.email}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              '    Contact Number: ${customer.contactNumber}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              '    Last Purchase: ${DateFormat('yyyy-MM-dd').format(customer.lastPurchase)}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
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

class Customer {
  final int id;
  final String companyName;
  final String username;
  final String email;
  final String contactNumber;
  final double totalSales;
  final DateTime lastPurchase;
  final int serialNumber;

  Customer({
    required this.id,
    required this.companyName,
    required this.username,
    required this.email,
    required this.contactNumber,
    required this.totalSales,
    required this.lastPurchase,
    required this.serialNumber,
  });

  String get totalSalesDisplay =>
      'RM ${NumberFormat("#,##0", "en_US").format(totalSales)}';
}
