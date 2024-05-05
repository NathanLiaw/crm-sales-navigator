import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/create_lead_page.dart';
import 'package:sales_navigator/notification_page.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/sales_lead_eng_widget.dart';
import 'package:sales_navigator/sales_lead_nego_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

final List<String> tabbarNames = [
  'Opportunities',
  'Engagement',
  'Negotiation',
  'Order Processing',
  'Closed',
];
String? selectedValue;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<LeadItem> leadItems;
  String? contactNumber; // 添加联系电话字段
  String? emailAddress; // 添加电子邮件字段

  @override
  void initState() {
    super.initState();
    leadItems = [];
    contactNumber = ''; // 初始化联系电话
    emailAddress = ''; // 初始化电子邮件
  }

  // Function to handle lead creation
  void _createLead(String customerName, String description, String amount) {
    LeadItem leadItem = LeadItem(
      customerName: customerName,
      description: description,
      createdDate: DateFormat('MM/dd/yyyy').format(DateTime.now()),
      amount: 'RM$amount',
      contactNumber: contactNumber, // 添加联系电话
      emailAddress: emailAddress, // 添加电子邮件
    );

    setState(() {
      leadItems.add(leadItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getSalesmanName(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          String salesmanName = snapshot.data!;
          return DefaultTabController(
            length: tabbarNames.length,
            child: Scaffold(
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
              body: TabBarView(
                children: [
                  SalesLeadPipeline(leadItems: leadItems),
                  // Add other tab views here
                ],
              ),
              bottomNavigationBar: CustomNavigationBar(),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateLeadPage(
                        onCreateLead: _createLead,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.add, color: Colors.white),
                label:
                    Text('Create Lead', style: TextStyle(color: Colors.white)),
                backgroundColor: Color(0xff0069BA),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            ),
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
  final List<LeadItem> leadItems; // Add this line

  SalesLeadPipeline({required this.leadItems, Key? key})
      : super(key: key); // Modify the constructor

  @override
  _SalesLeadPipelineState createState() => _SalesLeadPipelineState();
}

class _SalesLeadPipelineState extends State<SalesLeadPipeline> {
  // Store the latest modified date and total for each customer_id
  Map<int, DateTime> latestModifiedDates = {};
  Map<int, double> latestTotals = {};

  @override
  void initState() {
    super.initState();
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
              Tab(text: 'Opportunities(${widget.leadItems.length})'),
              Tab(text: 'Engagement(0)'),
              Tab(text: 'Negotiation(0)'),
              Tab(text: 'Order Processing(0)'),
              Tab(text: 'Closed(0)'),
            ],
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  itemCount: widget.leadItems.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        _buildLeadItem(widget.leadItems[index]),
                        // Check if it's the last item
                        if (index == widget.leadItems.length - 1)
                          // Add additional padding for the last item
                          SizedBox(height: 80),
                      ],
                    );
                  },
                ),
                ListView(
                  shrinkWrap: true,
                  children: [
                    EngagementLeadItem(),
                  ],
                ),
                ListView(
                  shrinkWrap: true,
                  children: [
                    NegotiationLeadItem(),
                  ],
                ),
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
    // Check if the current tab is "Opportunities"
    if (tabbarNames[DefaultTabController.of(context).index] ==
        'Opportunities') {
      return Card(
        color: const Color.fromARGB(255, 205, 229, 242),
        elevation: 2, // Add elevation for shadow effect
        margin: EdgeInsets.only(left: 8, right: 8, top: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    leadItem.customerName.length > 10
                        ? leadItem.customerName.substring(0, 6) + '...'
                        : leadItem.customerName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
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
                  Container(
                    margin: EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: Text(
                          'Select Item',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        items: tabbarNames
                            .map((item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ))
                            .toList(),
                        value: leadItem.selectedValue,
                        onChanged: (String? value) {
                          setState(() {
                            leadItem.selectedValue = value;
                          });
                        },
                        buttonStyleData: ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            height: 30,
                            width: 140,
                            decoration: BoxDecoration(color: Colors.white)),
                        menuItemStyleData: MenuItemStyleData(
                          height: 30,
                        ),
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
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      leadItem.createdDate,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Handle Ignore action
                          },
                          child: Text('Ignore',
                              style: TextStyle(color: Colors.red)),
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
                          child: Text('Accept',
                              style: TextStyle(color: Colors.white)),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (tabbarNames[DefaultTabController.of(context).index] ==
        'Engagement') {
      // 如果是 "Engagement" 选项，则构建 EngagementLeadItem 并传递 LeadItem 对象
      return EngagementLeadItem(leadItem: leadItem);
    } else {
      return Container(); // Return an empty container for other tabs
    }
  }

  Future<void> _fetchLeadItems() async {
    if (!mounted) return;
    MySqlConnection conn = await connectToDatabase();
    try {
      await _fetchCreateLeadItems(conn); // Fetch create_lead items
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
            widget.leadItems.add(leadItem);
          });
        }
      }
    } catch (e) {
      print('Error fetching lead items: $e');
    } finally {
      await conn.close();
    }
  }

  Future<void> _fetchCreateLeadItems(MySqlConnection conn) async {
    try {
      // Fetch data from the create_lead table
      Results results = await conn.query('SELECT * FROM create_lead');
      for (var row in results) {
        print('Row data: $row');

        var customerName = row['customer_name'] as String;
        var description = row['description'].toString();
        var amount = row['predicted_sales'].toString();
        var createdDate = DateFormat('MM/dd/yyyy').format(DateTime.now());

        // Create a LeadItem object from the fetched data
        var leadItem = LeadItem(
          customerName: customerName,
          description: description,
          createdDate: createdDate,
          amount: 'RM$amount',
        );

        setState(() {
          // Add the lead item to the list of lead items
          widget.leadItems.add(leadItem);
        });
      }
    } catch (e) {
      print('Error fetching create_lead items: $e');
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
  String? selectedValue; // Move selectedValue to LeadItem class
  String? contactNumber; // 添加联系电话字段
  String? emailAddress; // 添加电子邮件字段

  LeadItem({
    required this.customerName,
    required this.description,
    required this.createdDate,
    required this.amount,
    this.selectedValue, // Add selectedValue to constructor
    this.contactNumber, // 在构造函数中初始化联系电话
    this.emailAddress, // 在构造函数中初始化电子邮件
  });
}
