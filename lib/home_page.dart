import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/create_lead_page.dart';
import 'package:sales_navigator/customer_insight.dart';
import 'package:sales_navigator/notification_page.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/sales_lead_closed_widget.dart';
import 'package:sales_navigator/sales_lead_eng_widget.dart';
import 'package:sales_navigator/sales_lead_nego_widget.dart';
import 'package:sales_navigator/sales_lead_order_processing_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

final List<String> tabbarNames = [
  'Opportunities',
  'Engagement',
  'Negotiation',
  'Order Processing',
  'Closed',
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<LeadItem> leadItems = [];
  List<LeadItem> engagementLeads = [];
  List<LeadItem> negotiationLeads = [];
  Map<int, DateTime> latestModifiedDates = {};
  Map<int, double> latestTotals = {};

  @override
  void initState() {
    super.initState();
    _fetchLeadItems();
  }

  Future<void> _fetchLeadItems() async {
    if (!mounted) return;
    MySqlConnection conn = await connectToDatabase();
    try {
      await _fetchCreateLeadItems(conn);
      Results results = await conn.query('SELECT * FROM cart');
      for (var row in results) {
        var modifiedDate = row['modified'] as DateTime;
        var customerId = row['customer_id'] as int;
        var total = row['total'] as double;

        if (!latestModifiedDates.containsKey(customerId) ||
            modifiedDate.isAfter(latestModifiedDates[customerId]!)) {
          latestModifiedDates[customerId] = modifiedDate;
          latestTotals[customerId] = total;
        }
      }
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
            contactNumber: '',
            emailAddress: '',
            addressLine1: '',
            stage: 'Opportunities',
          );

          // Query the customer table for information based on customer_name.
          Results customerResults = await conn.query(
            'SELECT company_name, address_line_1, contact_number, email FROM customer WHERE company_name = ?',
            [customerName],
          );
          if (customerResults.isNotEmpty) {
            var customerRow = customerResults.first;
            leadItem.contactNumber = customerRow['contact_number'].toString();
            leadItem.emailAddress = customerRow['email'].toString();
            leadItem.addressLine1 = customerRow['address_line_1'].toString();
          }

          // Check if the customer already exists in the create_lead table
          Results existingLeadResults = await conn.query(
            'SELECT * FROM sales_lead WHERE customer_name = ?',
            [leadItem.customerName],
          );
          if (existingLeadResults.isEmpty) {
            // If the customer does not exist in the create_lead table, add it to the list of leadItems.
            setState(() {
              leadItems.add(leadItem);
            });
          }
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
      Results results = await conn.query('SELECT * FROM sales_lead');
      for (var row in results) {
        var customerName = row['customer_name'] as String;
        var description = row['description'] as String? ?? '';
        var amount = row['predicted_sales'].toString();
        var createdDate = DateFormat('MM/dd/yyyy').format(DateTime.now());
        var stage = row['stage'].toString();
        var contactNumber = row['contact_number'].toString();
        var emailAddress = row['email_address'].toString();
        var addressLine1 = row['address'].toString();

        var leadItem = LeadItem(
          customerName: customerName,
          description: description,
          createdDate: createdDate,
          amount: 'RM$amount',
          contactNumber: contactNumber,
          emailAddress: emailAddress,
          stage: stage,
          addressLine1: addressLine1,
        );

        setState(() {
          if (stage == 'Opportunities') {
            leadItems.add(leadItem);
          } else if (stage == 'Engagement') {
            engagementLeads.add(leadItem);
          } else if (stage == 'Negotiation') {
            negotiationLeads.add(leadItem);
          }
          // } else if (stage == 'Order Processing') {
          //   orderProcessingLeads.add(leadItem);
          // } else if (stage == 'Closed') {
          //   closedLeads.add(leadItem);
          // }
        });
      }
    } catch (e) {
      print('Error fetching sales_lead items: $e');
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

  Future<void> _moveToEngagement(LeadItem leadItem) async {
    setState(() {
      leadItems.remove(leadItem);
      engagementLeads.add(leadItem);
    });
    await _updateLeadStage(leadItem, 'Engagement');
  }

  Future<void> _moveToNegotiation(LeadItem leadItem) async {
    setState(() {
      leadItems.remove(leadItem);
      negotiationLeads.add(leadItem);
    });
    await _updateLeadStage(leadItem, 'Negotiation');
  }

  Future<void> _updateLeadStage(LeadItem leadItem, String stage) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      await conn.query(
        'UPDATE sales_lead SET stage = ? WHERE customer_name = ?',
        [stage, leadItem.customerName],
      );
    } catch (e) {
      print('Error updating stage: $e');
    } finally {
      await conn.close();
    }
  }

  void _createLead(String customerName, String description, String amount) {
    LeadItem leadItem = LeadItem(
      customerName: customerName,
      description: description,
      createdDate: DateFormat('MM/dd/yyyy').format(DateTime.now()),
      amount: 'RM$amount',
      contactNumber: '',
      emailAddress: '',
      stage: 'Opportunities',
      addressLine1: '',
    );

    setState(() {
      leadItems.add(leadItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabbarNames.length,
      child: FutureBuilder<String>(
        future: _getSalesmanName(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            String salesmanName = snapshot.data!;
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xff004c87),
                title: Text(
                  'Welcome, $salesmanName',
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationsPage()),
                      );
                    },
                  ),
                ],
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Sales Lead Pipeline',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TabBar(
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: 'Opportunities(${leadItems.length})'),
                      Tab(text: 'Engagement(${engagementLeads.length})'),
                      Tab(text: 'Negotiation(${negotiationLeads.length})'),
                      const Tab(text: 'Order Processing(0)'),
                      const Tab(text: 'Closed(0)'),
                    ],
                    labelStyle:
                        const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildOpportunitiesTab(),
                        _buildEngagementTab(),
                        _buildNegotiationTab(),
                        _buildOrderProcessingTab(),
                        _buildClosedTab(),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: const CustomNavigationBar(),
              floatingActionButton: _buildFloatingActionButton(context),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            );
          } else {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return AnimatedBuilder(
      animation: DefaultTabController.of(context),
      builder: (BuildContext context, Widget? child) {
        final TabController tabController = DefaultTabController.of(context);
        return tabController.index == 0
            ? FloatingActionButton.extended(
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
                icon: const Icon(Icons.add, color: Colors.white),
                label:
                    const Text('Create Lead', style: TextStyle(color: Colors.white)),
                backgroundColor: const Color(0xff0069BA),
              )
            : Container();
      },
    );
  }

  Future<String> _getSalesmanName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('salesmanName') ?? 'HomePage';
  }

  Widget _buildOpportunitiesTab() {
    return ListView.builder(
      itemCount: leadItems.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            _buildLeadItem(leadItems[index]),
            // Check if it's the last item
            if (index == leadItems.length - 1)
              // Add additional padding for the last item
              const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildLeadItem(LeadItem leadItem) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerInsightPage(
              customerName: leadItem.customerName,
            ),
          ),
        );
      },
      child: Card(
        color: const Color.fromARGB(255, 205, 229, 242),
        elevation: 2,
        margin: const EdgeInsets.only(left: 8, right: 8, top: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    leadItem.customerName.length > 10
                        ? '${leadItem.customerName.substring(0, 6)}...'
                        : leadItem.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      leadItem.amount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  DropdownButton2<String>(
                    isExpanded: true,
                    hint: const Text('Opportunities', style: TextStyle(fontSize: 14)),
                    items: tabbarNames
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    value: leadItem.selectedValue,
                    onChanged: (String? value) {
                      if (value == 'Engagement') {
                        _moveToEngagement(leadItem);
                      } else if (value == 'Negotiation') {
                        _moveToNegotiation(leadItem);
                      }
                    },
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 40,
                      width: 150,
                      decoration: BoxDecoration(color: Colors.white),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(leadItem.description),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      leadItem.createdDate,
                      style: const TextStyle(color: Colors.grey),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                              side: const BorderSide(color: Colors.red, width: 2),
                            ),
                            minimumSize: const Size(50, 35),
                          ),
                          child:
                              const Text('Ignore', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Handle Accept action
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff0069BA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            minimumSize: const Size(50, 35),
                          ),
                          child: const Text('Accept',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngagementTab() {
    return ListView.builder(
      itemCount: engagementLeads.length,
      itemBuilder: (context, index) {
        LeadItem leadItem = engagementLeads[index];
        return EngagementLeadItem(leadItem: leadItem);
      },
    );
  }

  Widget _buildNegotiationTab() {
    return ListView.builder(
      itemCount: negotiationLeads.length,
      itemBuilder: (context, index) {
        LeadItem leadItem = negotiationLeads[index];
        return NegotiationLeadItem(leadItem: leadItem);
      },
    );
  }

  Widget _buildOrderProcessingTab() {
    return ListView.builder(
      itemCount: 1,
      itemBuilder: (context, index) {
        return const OrderProcessingLeadItem(
          status: 'Pending',
        );
      },
    );
  }

  Widget _buildClosedTab() {
    return ListView.builder(
      itemCount: 1,
      itemBuilder: (context, index) {
        return const ClosedLeadItem();
      },
    );
  }
}

class LeadItem {
  final String customerName;
  final String description;
  final String createdDate;
  final String amount;
  String? selectedValue;
  String contactNumber;
  String emailAddress;
  final String stage;
  String addressLine1;

  LeadItem({
    required this.customerName,
    required this.description,
    required this.createdDate,
    required this.amount,
    this.selectedValue,
    required this.contactNumber,
    required this.emailAddress,
    required this.stage,
    required this.addressLine1,
  });

  void moveToEngagement(Function(LeadItem) onMoveToEngagement) {
    onMoveToEngagement(this);
  }
}
