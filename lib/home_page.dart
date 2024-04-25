import 'package:flutter/material.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/notification_page.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:sales_navigator/db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getSalesmanName(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          String salesmanName = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Color(0xff0069BA),
              title: Text(
                'Welcome, $salesmanName',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationsPage()),
                    );
                  },
                ),
              ],
            ),
            body: SalesLeadPipeline(),
            bottomNavigationBar: CustomNavigationBar(),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                // Handle "Create Lead" action
              },
              icon: Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: Text(
                'Create Lead',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xff0069BA),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        } else {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Future<String> _getSalesmanName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('salesmanName') ?? 'HomePage';
  }
}

class SalesLeadPipeline extends StatefulWidget {
  @override
  _SalesLeadPipelineState createState() => _SalesLeadPipelineState();
}

class _SalesLeadPipelineState extends State<SalesLeadPipeline> {
  late List<LeadItem> leadItems;

  // Store the latest modified date and total for each customer_id
  Map<int, DateTime> latestModifiedDates = {};
  Map<int, double> latestTotals = {};

  @override
  void initState() {
    super.initState();
    leadItems = [];
    _fetchLeadItems();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Sales Lead Pipeline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          TabBar(
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Opportunities(3)'),
              Tab(text: 'Engagement(3)'),
              Tab(text: 'Negotiation(3)'),
              Tab(text: 'Order Processing(2)'),
              Tab(text: 'Closed(1)'),
            ],
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  itemCount: leadItems.length,
                  itemBuilder: (context, index) {
                    return _buildLeadItem(leadItems[index]);
                  },
                ),
                Center(child: Text('Engagement Content')),
                Center(child: Text('Negotiation Content')),
                Center(child: Text('Order Processing Content')),
                Center(child: Text('Closed Content')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadItem(LeadItem leadItem) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                leadItem.customerName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                margin: EdgeInsets.only(left: 20),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  leadItem.amount,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(leadItem.description),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  leadItem.createdDate,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle Ignore action
                    },
                    child: Text('Ignore', style: TextStyle(color: Colors.red)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.red, width: 2),
                      ),
                      minimumSize: Size(50, 35),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Handle Accept action
                    },
                    child:
                        Text('Accept', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff0069BA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      minimumSize: Size(50, 35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLeadItems() async {
    MySqlConnection conn = await connectToDatabase();
    try {
      // Fetch data from the database
      Results results = await conn.query('SELECT * FROM cart');
      for (var row in results) {
        var modifiedDate = row['modified'] as DateTime;
        var customerId = row['customer_id'] as int;
        var total = row['total'] as double;

        // Update the latest modified date for the customer_id
        if (!latestModifiedDates.containsKey(customerId) ||
            modifiedDate.isAfter(latestModifiedDates[customerId]!)) {
          latestModifiedDates[customerId] = modifiedDate;
          latestTotals[customerId] = total;
        }
      }
      // Generate lead items for customers with modified dates older than 30 days
      DateTime currentDate = DateTime.now();
      for (var entry in latestModifiedDates.entries) {
        var customerId = entry.key;
        var modifiedDate = entry.value;
        var difference = currentDate.difference(modifiedDate).inDays;
        if (difference >= 30) {
          var customerName = await _fetchCustomerName(conn, customerId);
          var total = latestTotals[customerId]!;
          var description = "Hasn't purchased since 30 days ago";
          var createdDate = DateFormat('MM/dd/yyyy').format(modifiedDate);
          var leadItem = LeadItem(
            customerName: customerName,
            description: description,
            createdDate: createdDate,
            amount: 'RM${total.toStringAsFixed(2)}',
          );
          setState(() {
            leadItems.add(leadItem);
          });
        }
      }
    } catch (e) {
      print('Error fetching lead items: $e');
    } finally {
      await conn.close();
    }
  }

  Future<String> _fetchCustomerName(
      MySqlConnection connection, int customerId) async {
    try {
      Results results = await connection.query(
          'SELECT company_name FROM customer WHERE id = ?', [customerId]);
      if (results.isNotEmpty) {
        var row = results.first;
        return row['company_name'];
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching customer name: $e');
      return 'Unknown';
    }
  }
}

class LeadItem {
  final String customerName;
  final String description;
  final String createdDate;
  final String amount;

  LeadItem({
    required this.customerName,
    required this.description,
    required this.createdDate,
    required this.amount,
  });
}
