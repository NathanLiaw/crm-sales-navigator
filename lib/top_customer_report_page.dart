import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_connection.dart'; // Replace with your actual database connection utility

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TopCustomerReport(),
    );
  }
}

class TopCustomerReport extends StatefulWidget {
  @override
  _TopCustomerReportState createState() => _TopCustomerReportState();
}

class _TopCustomerReportState extends State<TopCustomerReport> {
  late Future<List<Customer>> customers;
  String selectedSortOption = 'Top Customer'; // Default selected sort option
  bool isSortedAscending = false; // Sort initially from highest to lowest total sales
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    customers = fetchCustomers(isSortedAscending, _selectedDateRange);
    // Set the initial date range to today
    DateTime today = DateTime.now();
    _selectedDateRange = DateTimeRange(start: today, end: today);
  }

  Future<List<Customer>> fetchCustomers(bool isAscending, DateTimeRange? dateRange) async {
    var db = await connectToDatabase();
    var sortOrder = isAscending ? 'ASC' : 'DESC';
    String dateRangeQuery = '';
    if (dateRange != null) {
      dateRangeQuery =
          "AND DATE(ci.created) BETWEEN '${DateFormat('yyyy-MM-dd').format(dateRange.start)}' AND '${DateFormat('yyyy-MM-dd').format(dateRange.end)}'";
    }
    var results = await db.query(
      'SELECT '
      'c.ID, '
      'c.company_name AS `Company Name`, '
      'c.Username, '
      'c.email AS Email, '
      'c.contact_number AS `Contact Number`, '
      'ROUND(SUM(ci.total), 0) AS `Total Sales` '
      'FROM customer c '
      'JOIN cart_item ci ON c.ID = ci.customer_id '
      'WHERE 1 $dateRangeQuery '
      'GROUP BY c.ID, c.company_name, c.Username, c.email, c.contact_number '
      'ORDER BY `Total Sales` $sortOrder;'
    );

    int serialNumber = 1; // Initialize serial number from 1
    List<Customer> customersList = results.map((row) {
      return Customer(
        id: row['ID'] as int,
        companyName: row['Company Name'].toString(),
        username: row['Username'].toString(),
        email: row['Email'].toString(),
        contactNumber: row['Contact Number'].toString(),
        totalSales: row['Total Sales'] as double,
        serialNumber: serialNumber++, // Increment serial number for each customer
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

  @override
  Widget build(BuildContext context) {
    String formattedDate = _selectedDateRange != null
        ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF004C87), // Set app bar color to #004C87
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Set back arrow color to white
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Top Customer Report',
          style: TextStyle(color: Colors.white), // Set text color to white
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
                          customers = fetchCustomers(isSortedAscending, _selectedDateRange);
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.withOpacity(0.1), // Set light blue color with opacity
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formattedDate,
                        style: TextStyle(color: Colors.black, fontSize: 15), // Set text color to black and font size to 15
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedSortOption,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSortOption = newValue!;
                      if (selectedSortOption == 'Base Customer') {
                        isSortedAscending = true;
                      } else {
                        isSortedAscending = false;
                      }
                      customers = fetchCustomers(isSortedAscending, _selectedDateRange);
                    });
                  },
                  items: <String>[
                    'Top Customer',
                    'Base Customer'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: customers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return ListView(
                    children: snapshot.data!.map((customer) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Text(
                                '${customer.serialNumber}. ', // Serial number
                                style: TextStyle(fontWeight: FontWeight.bold), // Bold font
                              ),
                              Text(
                                customer.companyName,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Increase font size and add bold weight
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Total Sales: ${customer.totalSalesDisplay}',
                            style: TextStyle(color: Colors.black, fontSize: 16), // Increase font size
                          ),
                          children: <Widget>[
                            Container(
                              color: Colors.grey[200], // Grey color
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text('ID: ${customer.id}'),
                                  ),
                                  ListTile(
                                    title: Text('Username: ${customer.username}'),
                                  ),
                                  ListTile(
                                    title: Text('Email: ${customer.email}'),
                                  ),
                                  ListTile(
                                    title: Text('Contact Number: ${customer.contactNumber}'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

class Customer {
  final int id;
  final String companyName;
  final String username;
  final String email;
  final String contactNumber;
  final double totalSales;
  final int serialNumber; // Serial number

  Customer({
    required this.id,
    required this.companyName,
    required this.username,
    required this.email,
    required this.contactNumber,
    required this.totalSales,
    required this.serialNumber, // Added serial number
  });

  String get totalSalesDisplay => 'RM ${NumberFormat("#,##0", "en_US").format(totalSales)}';
}
