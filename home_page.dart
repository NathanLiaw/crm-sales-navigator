import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/create_lead_page.dart';
import 'package:sales_navigator/create_task_page.dart';
import 'package:sales_navigator/notification_page.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/sales_lead_closed_widget.dart';
import 'package:sales_navigator/sales_lead_eng_widget.dart';
import 'package:sales_navigator/sales_lead_nego_widget.dart';
import 'package:sales_navigator/sales_lead_orderprocessing_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

final List<String> tabbarNames = [
  'Opportunities',
  'Engagement',
  'Negotiation',
  'Order Processing',
  'Closed',
];

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<LeadItem> leadItems = [];
  List<LeadItem> engagementLeads = [];
  List<LeadItem> negotiationLeads = [];
  List<LeadItem> orderProcessingLeads = [];
  List<LeadItem> closedLeads = [];

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
      Results results = await conn.query('SELECT * FROM cart');
      await _fetchCreateLeadItems(conn);

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
            salesOrderId: '',
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

          // Check if the customer already exists in the sales_lead table
          Results existingLeadResults = await conn.query(
            'SELECT * FROM sales_lead WHERE customer_name = ?',
            [leadItem.customerName],
          );
          // If the customer does not exist in the sales_lead table or exists but the stage is 'Closed',
          // add it to the list of leadItems.
          if (existingLeadResults.isEmpty ||
              (existingLeadResults.isNotEmpty &&
                  existingLeadResults.first['stage'] == 'Closed')) {
            setState(() {
              leadItems.add(leadItem);
            });
          }
        }
      }
    } catch (e) {
      developer.log('Error fetching lead items: $e');
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
        var createdDate = row['created_date'] != null
            ? DateFormat('MM/dd/yyyy').format(row['created_date'])
            : DateFormat('MM/dd/yyyy').format(DateTime.now());
        var stage = row['stage'].toString();
        var contactNumber = row['contact_number'].toString();
        var emailAddress = row['email_address'].toString();
        var addressLine1 = row['address'].toString();
        var salesOrderId = row['so_id']?.toString();
        var previousStage = row['previous_stage']?.toString();
        var quantity =
            row['quantity'] != null ? row['quantity'].toString() : null;

        var leadItem = LeadItem(
          customerName: customerName,
          description: description,
          createdDate: createdDate,
          amount: 'RM$amount',
          contactNumber: contactNumber,
          emailAddress: emailAddress,
          stage: stage,
          addressLine1: addressLine1,
          salesOrderId: salesOrderId,
          previousStage: previousStage,
          quantity: quantity,
        );

        setState(() {
          if (stage == 'Opportunities') {
            leadItems.add(leadItem);
          } else if (stage == 'Engagement') {
            engagementLeads.add(leadItem);
          } else if (stage == 'Negotiation') {
            negotiationLeads.add(leadItem);
          } else if (stage == 'Order Processing') {
            orderProcessingLeads.add(leadItem);
          } else if (stage == 'Closed') {
            closedLeads.add(leadItem);
          }
        });
      }
    } catch (e) {
      developer.log('Error fetching sales_lead items: $e');
    }
  }

  Future<String> _fetchCustomerName(
      MySqlConnection connection, int customerId) async {
    try {
      Results results = await connection.query(
          'SELECT id, company_name FROM customer WHERE id = ?', [customerId]);
      if (results.isNotEmpty) {
        var row = results.first;
        return row['company_name'];
      } else {
        return 'Unknown';
      }
    } catch (e) {
      developer.log('Error fetching customer name: $e');
      return 'Unknown';
    }
  }

  Future<void> _moveFromNegotiationToOrderProcessing(
      LeadItem leadItem, String salesOrderId, String? quantity) async {
    setState(() {
      negotiationLeads.remove(leadItem);
      leadItem.salesOrderId = salesOrderId;
      leadItem.quantity = quantity;
    });
    await _updateLeadStage(leadItem, 'Order Processing');
    await _updateSalesOrderId(leadItem, salesOrderId);
  }

  Future<void> _updateSalesOrderId(
      LeadItem leadItem, String salesOrderId) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      await conn.query(
        'UPDATE sales_lead SET so_id = ? WHERE customer_name = ?',
        [salesOrderId, leadItem.customerName],
      );
    } catch (e) {
      developer.log('Error updating sales order ID: $e');
    } finally {
      await conn.close();
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

  Future<void> _moveFromEngagementToNegotiation(LeadItem leadItem) async {
    setState(() {
      engagementLeads.remove(leadItem);
      negotiationLeads.add(leadItem);
    });
    await _updateLeadStage(leadItem, 'Negotiation');
  }

  Future<void> _moveFromOrderProcessingToClosed(LeadItem leadItem) async {
    setState(() {
      orderProcessingLeads.remove(leadItem);
      closedLeads.add(leadItem);
    });
    await _updateLeadStage(leadItem, 'Closed');
  }

  Future<void> _updateLeadStage(LeadItem leadItem, String stage) async {
    setState(() {
      leadItem.previousStage = leadItem.stage;
      leadItem.stage = stage;
    });
    await _updateLeadStageInDatabase(leadItem);
  }

  Future<void> _moveToCreateTaskPage(
      BuildContext context, LeadItem leadItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          customerName: leadItem.customerName,
          contactNumber: leadItem.contactNumber,
          emailAddress: leadItem.emailAddress,
          address: leadItem.addressLine1,
          lastPurchasedAmount: leadItem.amount,
          showTaskDetails: false,
        ),
      ),
    );
    if (result != null && result['salesOrderId'] != null) {
      setState(() {
        leadItems.remove(leadItem);
        leadItem.salesOrderId = result['salesOrderId'];
        leadItem.quantity = result['quantity'];
        closedLeads.add(leadItem);
      });
      await _updateLeadStage(leadItem, 'Closed');
    }
  }

  Future<void> _navigateToCreateTaskPage(
      BuildContext context, LeadItem leadItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          customerName: leadItem.customerName,
          contactNumber: leadItem.contactNumber,
          emailAddress: leadItem.emailAddress,
          address: leadItem.addressLine1,
          lastPurchasedAmount: leadItem.amount,
          showTaskDetails: true,
        ),
      ),
    );

    if (result != null && result['error'] == null) {
      // If the user selects a sales order ID, move the LeadItem to OrderProcessingLeadItem
      if (result['salesOrderId'] != null) {
        String salesOrderId = result['salesOrderId'] as String;
        String? quantity = result['quantity'] as String?;
        await _moveFromOpportunitiesToOrderProcessing(
            leadItem, salesOrderId, quantity);
        setState(() {
          leadItems.remove(leadItem);
          orderProcessingLeads.add(leadItem);
        });
      }
    }
  }

  Future<void> _moveFromOpportunitiesToOrderProcessing(
      LeadItem leadItem, String salesOrderId, String? quantity) async {
    setState(() {
      leadItems.remove(leadItem);
      leadItem.salesOrderId = salesOrderId;
      leadItem.quantity = quantity;
    });
    await _updateLeadStage(leadItem, 'Order Processing');
    await _updateSalesOrderId(leadItem, salesOrderId);
  }

  Future<void> _updateLeadStageInDatabase(LeadItem leadItem) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      await conn.query(
        'UPDATE sales_lead SET stage = ?, previous_stage = ? WHERE customer_name = ?',
        [leadItem.stage, leadItem.previousStage, leadItem.customerName],
      );
    } catch (e) {
      developer.log('Error updating stage: $e');
    } finally {
      await conn.close();
    }
  }

  void _onDeleteEngagementLead(LeadItem leadItem) {
    setState(() {
      engagementLeads.remove(leadItem);
    });
  }

  void _onDeleteNegotiationLead(LeadItem leadItem) {
    setState(() {
      negotiationLeads.remove(leadItem);
    });
  }

  void _onUndoEngagementLead(LeadItem leadItem, String previousStage) {
    setState(() {
      engagementLeads.remove(leadItem);
      leadItem.stage = previousStage;
      leadItem.previousStage = null;
      if (previousStage == 'Opportunities') {
        leadItems.add(leadItem);
      } else if (previousStage == 'Negotiation') {
        negotiationLeads.add(leadItem);
      }
    });
    _updateLeadStageInDatabase(leadItem);
  }

  void _onUndoNegotiationLead(LeadItem leadItem, String previousStage) {
    setState(() {
      negotiationLeads.remove(leadItem);
      leadItem.stage = previousStage;
      leadItem.previousStage = null;
      if (previousStage == 'Opportunities') {
        leadItems.add(leadItem);
      } else if (previousStage == 'Engagement') {
        engagementLeads.add(leadItem);
      }
    });
    _updateLeadStageInDatabase(leadItem);
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
      salesOrderId: '',
    );

    setState(() {
      leadItems.add(leadItem);
    });
  }

  Future<void> _handleIgnore(LeadItem leadItem) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this sales lead?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      MySqlConnection conn = await connectToDatabase();
      try {
        await conn.query(
          'DELETE FROM sales_lead WHERE customer_name = ?',
          [leadItem.customerName],
        );
        setState(() {
          leadItems.remove(leadItem);
        });
      } catch (e) {
        developer.log('Error deleting lead item: $e');
      } finally {
        await conn.close();
      }
    }
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
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
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
                      Tab(
                          text:
                              'Order Processing(${orderProcessingLeads.length})'),
                      Tab(text: 'Closed(${closedLeads.length})'),
                    ],
                    labelStyle:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
              bottomNavigationBar: CustomNavigationBar(),
              floatingActionButton: _buildFloatingActionButton(context),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            );
          } else {
            return Scaffold(
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
        final TabController tabController = DefaultTabController.of(context)!;
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
                icon: Icon(Icons.add, color: Colors.white),
                label:
                    Text('Create Lead', style: TextStyle(color: Colors.white)),
                backgroundColor: Color(0xff0069BA),
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
              SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildLeadItem(LeadItem leadItem) {
    return Card(
      color: const Color.fromARGB(255, 205, 229, 242),
      elevation: 2,
      margin: EdgeInsets.only(left: 8, right: 8, top: 10),
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
                Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: Text(
                      'Opportunities',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    items: tabbarNames
                        .skip(1)
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    value: leadItem.selectedValue,
                    onChanged: (String? value) {
                      if (value == 'Engagement') {
                        _moveToEngagement(leadItem);
                      } else if (value == 'Negotiation') {
                        _moveToNegotiation(leadItem);
                      } else if (value == 'Closed') {
                        _moveToCreateTaskPage(context, leadItem);
                      } else if (value == 'Order Processing') {
                        _navigateToCreateTaskPage(context, leadItem);
                      }
                    },
                    buttonStyleData: ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 32,
                      width: 140,
                      decoration: BoxDecoration(color: Colors.white),
                    ),
                    menuItemStyleData: MenuItemStyleData(
                      height: 30,
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
                          _handleIgnore(leadItem);
                        },
                        child:
                            Text('Ignore', style: TextStyle(color: Colors.red)),
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
                          _moveToEngagement(leadItem);
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
  }

  Widget _buildEngagementTab() {
    return ListView.builder(
      itemCount: engagementLeads.length,
      itemBuilder: (context, index) {
        LeadItem leadItem = engagementLeads[index];
        return EngagementLeadItem(
          leadItem: leadItem,
          onMoveToNegotiation: () => _moveFromEngagementToNegotiation(leadItem),
          onMoveToOrderProcessing: (leadItem, salesOrderId, quantity) async {
            await _moveFromEngagementToOrderProcessing(
                leadItem, salesOrderId, quantity);
            setState(() {
              engagementLeads.remove(leadItem);
              orderProcessingLeads.add(leadItem);
            });
          },
          onDeleteLead: _onDeleteEngagementLead,
          onUndoLead: _onUndoEngagementLead,
          onComplete: (leadItem) async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTaskPage(
                  customerName: leadItem.customerName,
                  contactNumber: leadItem.contactNumber,
                  emailAddress: leadItem.emailAddress,
                  address: leadItem.addressLine1,
                  lastPurchasedAmount: leadItem.amount,
                  showTaskDetails: false,
                ),
              ),
            );
            if (result != null && result['salesOrderId'] != null) {
              setState(() {
                engagementLeads.remove(leadItem);
                leadItem.salesOrderId = result['salesOrderId'];
                leadItem.quantity = result['quantity'];
                closedLeads.add(leadItem);
              });
              await _updateLeadStage(leadItem, 'Closed');
            }
          },
        );
      },
    );
  }

  Future<void> _moveFromEngagementToOrderProcessing(
      LeadItem leadItem, String salesOrderId, String? quantity) async {
    setState(() {
      engagementLeads.remove(leadItem);
      leadItem.salesOrderId = salesOrderId;
      leadItem.quantity = quantity;
    });
    await _updateLeadStage(leadItem, 'Order Processing');
    await _updateSalesOrderId(leadItem, salesOrderId);
  }

  Widget _buildNegotiationTab() {
    return ListView.builder(
      itemCount: negotiationLeads.length,
      itemBuilder: (context, index) {
        LeadItem leadItem = negotiationLeads[index];
        return NegotiationLeadItem(
          leadItem: leadItem,
          onMoveToOrderProcessing: (leadItem, salesOrderId, quantity) async {
            await _moveFromNegotiationToOrderProcessing(
                leadItem, salesOrderId, quantity);
            setState(() {
              negotiationLeads.remove(leadItem);
              orderProcessingLeads.add(leadItem);
            });
          },
          onDeleteLead: _onDeleteNegotiationLead,
          onUndoLead: _onUndoNegotiationLead,
          onComplete: (leadItem) async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTaskPage(
                  customerName: leadItem.customerName,
                  contactNumber: leadItem.contactNumber,
                  emailAddress: leadItem.emailAddress,
                  address: leadItem.addressLine1,
                  lastPurchasedAmount: leadItem.amount,
                  // existingTitle: leadItem.title,
                  // existingDescription: leadItem.description,
                  // existingDueDate: leadItem.dueDate,
                  showTaskDetails: false,
                ),
              ),
            );
            if (result != null && result['salesOrderId'] != null) {
              setState(() {
                negotiationLeads.remove(leadItem);
                leadItem.salesOrderId = result['salesOrderId'];
                leadItem.quantity = result['quantity'];
                closedLeads.add(leadItem);
              });
              await _updateLeadStage(leadItem, 'Closed');
            }
          },
        );
      },
    );
  }

  Widget _buildOrderProcessingTab() {
    return ListView.builder(
      itemCount: orderProcessingLeads.length,
      itemBuilder: (context, index) {
        LeadItem leadItem = orderProcessingLeads[index];
        if (leadItem.salesOrderId == null) {
          return OrderProcessingLeadItem(
            leadItem: leadItem,
            status: 'Unknown',
            onMoveToClosed: _moveFromOrderProcessingToClosed,
          );
        } else {
          return FutureBuilder<String>(
            future: _fetchSalesOrderStatus(leadItem.salesOrderId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                String status = snapshot.data ?? 'Unknown';
                return OrderProcessingLeadItem(
                  leadItem: leadItem,
                  status: status,
                  onMoveToClosed: _moveFromOrderProcessingToClosed,
                );
              }
            },
          );
        }
      },
    );
  }

  Future<String> _fetchSalesOrderStatus(String salesOrderId) async {
    int salesOrderIdInt = int.parse(salesOrderId);
    try {
      MySqlConnection conn = await connectToDatabase();
      Results results = await conn.query(
        'SELECT status, created, expiration_date, total FROM cart WHERE id = ?',
        [salesOrderIdInt],
      );
      if (results.isNotEmpty) {
        var row = results.first;
        String status = row['status'].toString();
        String createdDate = row['created'].toString();
        String expirationDate = row['expiration_date'].toString();
        String total = row['total'].toString();
        return '$status|$createdDate|$expirationDate|$total';
      } else {
        return 'Unknown|Unknown|Unknown|Unknown';
      }
    } catch (e) {
      developer.log('Error fetching sales order status: $e');
      return 'Unknown|Unknown|Unknown|Unknown';
    }
  }

  Future<Map<String, String>> _fetchSalesOrderDetails(
      String salesOrderId) async {
    try {
      MySqlConnection conn = await connectToDatabase();
      Results results = await conn.query(
        'SELECT created, expiration_date, total, session FROM cart WHERE id = ?',
        [int.parse(salesOrderId)],
      );
      if (results.isNotEmpty) {
        var row = results.first;
        String createdDate = row['created'].toString();
        String expirationDate = row['expiration_date'].toString();
        String total = row['total'].toString();
        String session = row['session'].toString();

        Results quantityResults = await conn.query(
          'SELECT CAST(SUM(qty) AS UNSIGNED) AS total_qty FROM cart_item WHERE session = ?',
          [session],
        );
        String totalQuantity = quantityResults.first['total_qty'].toString();

        String formattedCreatedDate = _formatDate(createdDate);
        return {
          'formattedCreatedDate': formattedCreatedDate,
          'expirationDate': expirationDate,
          'total': total,
          'quantity': totalQuantity,
        };
      } else {
        return {};
      }
    } catch (e) {
      developer.log('Error fetching sales order details: $e');
      return {};
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) {
      return '';
    }
    DateTime parsedDate = DateTime.parse(dateString);
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(parsedDate);
  }

  Widget _buildClosedTab() {
    return ListView.builder(
      itemCount: closedLeads.length,
      itemBuilder: (context, index) {
        LeadItem leadItem = closedLeads[index];
        return FutureBuilder<Map<String, String>>(
          future: _fetchSalesOrderDetails(leadItem.salesOrderId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              Map<String, String> salesOrderDetails = snapshot.data ?? {};
              return ClosedLeadItem(
                leadItem: leadItem,
                formattedCreatedDate:
                    salesOrderDetails['formattedCreatedDate'] ?? '',
                expirationDate: salesOrderDetails['expirationDate'] ?? '',
                total: salesOrderDetails['total'] ?? '',
                quantity: salesOrderDetails['quantity'] ?? 'Unknown',
              );
            }
          },
        );
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
  String stage;
  String addressLine1;
  String? salesOrderId;
  String? previousStage;
  String? quantity;

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
    required this.salesOrderId,
    this.previousStage,
    this.quantity,
  });

  void moveToEngagement(Function(LeadItem) onMoveToEngagement) {
    onMoveToEngagement(this);
  }
}