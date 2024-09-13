import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/create_lead_page.dart';
import 'package:sales_navigator/create_task_page.dart';
import 'package:sales_navigator/customer_insight.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/sales_lead_closed_widget.dart';
import 'package:sales_navigator/sales_lead_eng_widget.dart';
import 'package:sales_navigator/sales_lead_nego_widget.dart';
import 'package:sales_navigator/sales_lead_orderprocessing_widget.dart';
import 'package:sales_navigator/utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';

final List<String> tabbarNames = [
  'Opportunities',
  'Engagement',
  'Negotiation',
  'Order Processing',
  'Closed',
];

class SalesmanPerformanceUpdater {
  Timer? _timer;

  void startPeriodicUpdate(int salesmanId) {
    // 每小时更新一次
    _timer = Timer.periodic(Duration(hours: 1), (timer) {
      _updateSalesmanPerformance(salesmanId);
    });
  }

  void stopPeriodicUpdate() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _updateSalesmanPerformance(int salesmanId) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      await conn.query(
          'CALL update_salesman_performance(?, CURDATE())', [salesmanId]);
    } catch (e) {
      print('Error updating salesman performance: $e');
    } finally {
      await conn.close();
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
  late int salesmanId;

  bool _isLoading = true; // Track loading state
  late SalesmanPerformanceUpdater _performanceUpdater;

  @override
  void initState() {
    super.initState();
    _performanceUpdater = SalesmanPerformanceUpdater();
    _initializeSalesmanId();
    // _fetchLeadItems();
    _cleanAndValidateLeadData().then((_) => _fetchLeadItems());
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false; // Set loading state to false when data is loaded
      });
    });
  }

  void _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    setState(() {
      salesmanId = id;
    });
    _performanceUpdater.startPeriodicUpdate(salesmanId);
  }

  @override
  void dispose() {
    _performanceUpdater?.stopPeriodicUpdate();
    super.dispose();
  }

  // Update salesman performance by calling the sql Stored Procedure
  Future<void> _updateSalesmanPerformance(int salesmanId) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      await conn.query(
          'CALL update_salesman_performance(?, CURDATE())', [salesmanId]);
    } catch (e) {
      developer.log('Error updating salesman performance: $e');
    } finally {
      await conn.close();
    }
  }

  // Get average closed value by calling the sql function
  Future<double> _getAverageClosedValue(
      int salesmanId, String startDate, String endDate) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      var result = await conn.query(
          'SELECT calculate_average_closed_value(?, ?, ?)',
          [salesmanId, startDate, endDate]);
      return (result.first.values!.first as num).toDouble();
    } catch (e) {
      developer.log('Error getting average closed value: $e');
      return 0;
    } finally {
      await conn.close();
    }
  }

  // Get stage duration by calling the sql function
  Future<int> getStageDuration(int leadId, String stage) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      var results = await conn.query(
          'SELECT calculate_stage_duration(?, ?) AS duration', [leadId, stage]);
      if (results.isNotEmpty) {
        return results.first['duration'] as int;
      }
      return 0;
    } catch (e) {
      developer.log('Error calculating stage duration: $e');
      return 0;
    } finally {
      await conn.close();
    }
  }

  // Clean and validate lead data
  Future<void> _cleanAndValidateLeadData() async {
    MySqlConnection conn = await connectToDatabase();
    try {
      await conn.query('''
      UPDATE sales_lead
      SET 
        engagement_start_date = CASE 
          WHEN stage IN ('Engagement', 'Negotiation', 'Order Processing', 'Closed') AND engagement_start_date IS NULL 
          THEN created_date 
          ELSE engagement_start_date 
        END,
        negotiation_start_date = CASE 
          WHEN stage IN ('Negotiation', 'Order Processing', 'Closed') AND negotiation_start_date IS NULL 
          THEN COALESCE(engagement_start_date, created_date)
          ELSE negotiation_start_date 
        END
      WHERE salesman_id = ?
    ''', [salesmanId]);

      developer.log('Lead data cleaned and validated');
    } catch (e) {
      developer.log('Error cleaning and validating lead data: $e');
    } finally {
      await conn.close();
    }
  }

  Future<void> _fetchLeadItems() async {
    if (!mounted) return;
    MySqlConnection conn = await connectToDatabase();
    try {
      print(salesmanId);
      Results results =
          await conn.query('SELECT * FROM cart WHERE buyer_id = $salesmanId');
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
          var createdDate =
              DateFormat('yyyy-MM-dd').format(currentDate); // Use current date
          var leadItem = LeadItem(
            id: 0,
            salesmanId: salesmanId,
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
            'SELECT * FROM sales_lead WHERE customer_name = ? AND salesman_id = $salesmanId',
            [leadItem.customerName],
          );
          // If the customer does not exist in the sales_lead table or exists but the stage is 'Closed',
          // save it to the sales_lead table and add it to the list of leadItems.
          if (existingLeadResults.isEmpty ||
              (existingLeadResults.isNotEmpty &&
                  existingLeadResults.first['stage'] == 'Closed')) {
            try {
              // Save the lead item to the sales_lead table
              await conn.query(
                'INSERT INTO sales_lead (salesman_id, customer_name, description, created_date, predicted_sales, contact_number, email_address, address, stage) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                [
                  leadItem.salesmanId,
                  leadItem.customerName,
                  leadItem.description,
                  leadItem.createdDate,
                  leadItem.amount.substring(2),
                  leadItem.contactNumber,
                  leadItem.emailAddress,
                  leadItem.addressLine1,
                  leadItem.stage,
                ],
              );
              // If the INSERT operation is successful, add the leadItem to the list
              setState(() {
                leadItems.add(leadItem);
              });
            } catch (e) {
              developer
                  .log('Error inserting lead item into sales_lead table: $e');
              developer.log('Lead item details:');
              developer.log('customerName: ${leadItem.customerName}');
              developer.log('description: ${leadItem.description}');
              developer.log('createdDate: ${leadItem.createdDate}');
              developer.log('amount: ${leadItem.amount}');
              developer.log('contactNumber: ${leadItem.contactNumber}');
              developer.log('emailAddress: ${leadItem.emailAddress}');
              developer.log('addressLine1: ${leadItem.addressLine1}');
              developer.log('stage: ${leadItem.stage}');
            }
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
      Results results = await conn
          .query('SELECT * FROM sales_lead WHERE salesman_id = $salesmanId');
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
        var quantity = row['quantity'];
        // 添加这两行来获取 engagement_start_date 和 negotiation_start_date
        var engagementStartDate = row['engagement_start_date'] as DateTime?;
        var negotiationStartDate = row['negotiation_start_date'] as DateTime?;

        var leadItem = LeadItem(
          id: row['id'] as int, // 添加这一行
          salesmanId: salesmanId,
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
          engagementStartDate: engagementStartDate, // 添加这行
          negotiationStartDate: negotiationStartDate, // 添加这行
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

  Future<void> _updateSalesOrderId(
      LeadItem leadItem, String salesOrderId) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      await conn.query(
        'UPDATE sales_lead SET so_id = ? WHERE id = ?',
        [salesOrderId, leadItem.id],
      );
    } catch (e) {
      developer.log('Error updating sales order ID: $e');
    } finally {
      await conn.close();
    }
  }

  Future<void> _moveFromNegotiationToOrderProcessing(
      LeadItem leadItem, String salesOrderId, int? quantity) async {
    setState(() {
      negotiationLeads.remove(leadItem);
      leadItem.salesOrderId = salesOrderId;
      leadItem.quantity = quantity;
    });
    await _updateLeadStage(leadItem, 'Order Processing');
    await _updateSalesOrderId(leadItem, salesOrderId);
    // 调用更新销售人员表现的函数
    await _updateSalesmanPerformance(salesmanId);
  }

  Future<void> _moveToEngagement(LeadItem leadItem) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      // 更新阶段和开始时间
      await conn.query(
          'UPDATE sales_lead SET stage = ?, engagement_start_date = NOW() WHERE id = ?',
          ['Engagement', leadItem.id]);
      Results results = await conn.query(
        'SELECT contact_number, email_address FROM sales_lead WHERE id = ?',
        [leadItem.id],
      );
      if (results.isNotEmpty) {
        var row = results.first;
        leadItem.contactNumber = row['contact_number'];
        leadItem.emailAddress = row['email_address'];
      }
      // 调用更新销售人员表现的函数
      await _updateSalesmanPerformance(salesmanId);
    } catch (e) {
      developer.log('Error fetching contact number and email address: $e');
    } finally {
      await conn.close();
    }

    setState(() {
      leadItems.remove(leadItem);
      engagementLeads.add(leadItem);
    });
    await _updateLeadStage(leadItem, 'Engagement');
  }

  Future<void> _moveToNegotiation(LeadItem leadItem) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      // 更新阶段和开始时间
      await conn.query(
          'UPDATE sales_lead SET stage = ?, negotiation_start_date = NOW() WHERE id = ?',
          ['Negotiation', leadItem.id]);
      Results results = await conn.query(
        'SELECT contact_number, email_address FROM sales_lead WHERE id = ?',
        [leadItem.id],
      );
      if (results.isNotEmpty) {
        var row = results.first;
        leadItem.contactNumber = row['contact_number'];
        leadItem.emailAddress = row['email_address'];
      }
      // 调用更新销售人员表现的函数
      await _updateSalesmanPerformance(salesmanId);
    } catch (e) {
      developer.log('Error fetching contact number and email address: $e');
    } finally {
      await conn.close();
    }
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
    // 调用更新销售人员表现的函数
    await _updateSalesmanPerformance(salesmanId);
  }

  Future<void> _moveFromOrderProcessingToClosed(LeadItem leadItem) async {
    setState(() {
      orderProcessingLeads.remove(leadItem);
      closedLeads.add(leadItem);
    });
    await _updateLeadStage(leadItem, 'Closed');
    // 调用更新销售人员表现的函数
    await _updateSalesmanPerformance(salesmanId);
  }

  // Future<void> _updateLeadStage(LeadItem leadItem, String stage) async {
  //   setState(() {
  //     leadItem.previousStage = leadItem.stage;
  //     leadItem.stage = stage;
  //   });
  //   await _updateLeadStageInDatabase(leadItem);
  // }

  Future<void> _updateLeadStage(LeadItem leadItem, String stage) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      String query;
      List<Object> params;

      if (stage == 'Negotiation' && leadItem.negotiationStartDate == null) {
        query = '''
        UPDATE sales_lead 
        SET stage = ?, previous_stage = ?, negotiation_start_date = NOW() 
        WHERE id = ?
      ''';
        params = [stage, leadItem.stage, leadItem.id];
      } else if (stage == 'Engagement' &&
          leadItem.engagementStartDate == null) {
        query = '''
        UPDATE sales_lead 
        SET stage = ?, previous_stage = ?, engagement_start_date = NOW() 
        WHERE id = ?
      ''';
        params = [stage, leadItem.stage, leadItem.id];
      } else {
        query =
            'UPDATE sales_lead SET stage = ?, previous_stage = ? WHERE id = ?';
        params = [stage, leadItem.stage, leadItem.id];
      }

      await conn.query(query, params);

      setState(() {
        leadItem.previousStage = leadItem.stage;
        leadItem.stage = stage;
        if (stage == 'Negotiation' && leadItem.negotiationStartDate == null) {
          leadItem.negotiationStartDate = DateTime.now();
        } else if (stage == 'Engagement' &&
            leadItem.engagementStartDate == null) {
          leadItem.engagementStartDate = DateTime.now();
        }
      });

      developer.log(
          'Successfully updated lead stage to $stage for lead ${leadItem.id}');
    } catch (e) {
      developer.log('Error updating stage: $e');
    } finally {
      await conn.close();
    }
  }

  Future<void> _moveToCreateTaskPage(
      BuildContext context, LeadItem leadItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          id: leadItem.id,
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
      BuildContext context, LeadItem leadItem, bool showTaskDetails) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          id: leadItem.id,
          customerName: leadItem.customerName,
          contactNumber: leadItem.contactNumber,
          emailAddress: leadItem.emailAddress,
          address: leadItem.addressLine1,
          lastPurchasedAmount: leadItem.amount,
          showTaskDetails: showTaskDetails,
        ),
      ),
    );

    if (result != null && result['error'] == null) {
      // If the user selects a sales order ID, move the LeadItem to OrderProcessingLeadItem
      if (result['salesOrderId'] != null) {
        String salesOrderId = result['salesOrderId'] as String;
        int? quantity = result['quantity'];
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
      LeadItem leadItem, String salesOrderId, int? quantity) async {
    setState(() {
      leadItems.remove(leadItem);
      leadItem.salesOrderId = salesOrderId;
      leadItem.quantity = quantity;
    });
    await _updateLeadStage(leadItem, 'Order Processing');
    await _updateSalesOrderId(leadItem, salesOrderId);
    // 调用更新销售人员表现的函数
    await _updateSalesmanPerformance(salesmanId);
  }

  // Future<void> _updateLeadStageInDatabase(LeadItem leadItem) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     await conn.query(
  //       'UPDATE sales_lead SET stage = ?, previous_stage = ? WHERE id = ?',
  //       [leadItem.stage, leadItem.previousStage, leadItem.id],
  //     );
  //   } catch (e) {
  //     developer.log('Error updating stage: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

  Future<void> _updateLeadStageInDatabase(LeadItem leadItem) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      String query;
      List<Object> params;

      if (leadItem.stage == 'Negotiation') {
        query = '''
        UPDATE sales_lead 
        SET stage = ?, previous_stage = ?, negotiation_start_date = NOW() 
        WHERE id = ?
      ''';
        params = [leadItem.stage, leadItem.previousStage ?? '', leadItem.id];
      } else if (leadItem.stage == 'Engagement') {
        query = '''
        UPDATE sales_lead 
        SET stage = ?, previous_stage = ?, engagement_start_date = NOW() 
        WHERE id = ?
      ''';
        params = [leadItem.stage, leadItem.previousStage ?? '', leadItem.id];
      } else {
        query =
            'UPDATE sales_lead SET stage = ?, previous_stage = ? WHERE id = ?';
        params = [leadItem.stage, leadItem.previousStage ?? '', leadItem.id];
      }

      await conn.query(query, params);

      developer.log(
          'Successfully updated lead stage to ${leadItem.stage} for lead ${leadItem.id}');
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
    // 调用更新销售人员表现的函数
    _updateSalesmanPerformance(salesmanId);
  }

  void _onDeleteNegotiationLead(LeadItem leadItem) {
    setState(() {
      negotiationLeads.remove(leadItem);
    });
    // 调用更新销售人员表现的函数
    _updateSalesmanPerformance(salesmanId);
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
    // 调用更新销售人员表现的函数
    _updateSalesmanPerformance(salesmanId);
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
    // 调用更新销售人员表现的函数
    _updateSalesmanPerformance(salesmanId);
  }

  Future<void> _createLead(
      String customerName, String description, String amount) async {
    LeadItem leadItem = LeadItem(
      id: 0,
      salesmanId: salesmanId,
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

    MySqlConnection conn = await connectToDatabase();
    try {
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
    } catch (e) {
      developer.log('Error fetching customer details: $e');
    } finally {
      await conn.close();
    }

    setState(() {
      leadItems.add(leadItem);
    });
    await _updateSalesmanPerformance(salesmanId); // 添加这行
  }

  Future<void> _handleIgnore(LeadItem leadItem) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this sales lead?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Confirm'),
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
          'DELETE FROM sales_lead WHERE id = ?',
          [leadItem.id],
        );
        setState(() {
          leadItems.remove(leadItem);
        });
        await _updateSalesmanPerformance(salesmanId); // 添加这行
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
                automaticallyImplyLeading: false,

                backgroundColor: const Color(0xff0175FF),
                title: Text(
                  'Welcome, $salesmanName',
                  style: const TextStyle(color: Colors.white),
                ),
                // actions: [
                //   IconButton(
                //     icon: const Icon(Icons.notifications, color: Colors.white),
                //     onPressed: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //             builder: (context) => const NotificationsPage()),
                //       );
                //     },
                //   ),
                // ],
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                          padding: EdgeInsets.zero,
                          color: Colors.white,
                          child: Image.asset(
                            'asset/SalesPipeline_Head2.png',
                            width: 700,
                            height: 78,
                            fit: BoxFit.cover,
                          )),
                      Container(
                        height: 78,
                        padding: EdgeInsets.only(left: 12, bottom: 2),
                        child: Column(
                          children: [
                            Spacer(),
                            Text(
                              'Sales Lead Pipeline',
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(letterSpacing: -0.8),
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TabBar(
                    isScrollable: true,
                    labelColor: const Color(0xff0175FF),
                    indicatorColor: const Color(0xff0175FF),
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
                    labelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _isLoading
                            ? _buildShimmerTab()
                            : _buildOpportunitiesTab(),
                        _isLoading ? _buildShimmerTab() : _buildEngagementTab(),
                        _isLoading
                            ? _buildShimmerTab()
                            : _buildNegotiationTab(),
                        _isLoading
                            ? _buildShimmerTab()
                            : _buildOrderProcessingTab(),
                        _isLoading ? _buildShimmerTab() : _buildClosedTab(),
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

  // Shimmer effect for both tabs
  Widget _buildShimmerTab() {
    return ListView.builder(
      itemCount: 4, // Number of shimmer items to show while loading
      itemBuilder: (context, index) {
        return _buildShimmerCard();
      },
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 64.0,
                  color: Colors.white,
                ),
                SizedBox(height: 8.0),
                Container(
                  width: double.infinity,
                  height: 16.0,
                  color: Colors.white,
                ),
                SizedBox(height: 8.0),
                Container(
                  width: double.infinity,
                  height: 16.0,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
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
                        salesmanId: salesmanId,
                        onCreateLead: _createLead,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                label: const Text('Create Lead',
                    style: TextStyle(color: Colors.white)),
                backgroundColor: const Color(0xff0175FF),
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
      child: Container(
        height: 200,
        decoration: BoxDecoration(
            image: DecorationImage(
              image: ResizeImage(AssetImage('asset/bttm_start.png'),
                  width: 128, height: 98),
              alignment: Alignment.bottomLeft,
            ),
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Color.fromARGB(75, 117, 117, 117),
                spreadRadius: 0.1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ]),
        margin: const EdgeInsets.only(left: 8, right: 8, top: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Text(
                    //   leadItem.customerName.length > 20
                    //       ? '${leadItem.customerName.substring(0, 20)}...'
                    //       : leadItem.customerName,
                    //   style: const TextStyle(
                    //       fontWeight: FontWeight.bold, fontSize: 18),
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                    Container(
                      width: 200,
                      child: Text(
                        leadItem.customerName,
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(letterSpacing: -0.8),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 25, 23, 49),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Spacer(),
                    Container(
                      margin: const EdgeInsets.only(left: 18),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(71, 148, 255, 223),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        leadItem.formattedAmount,
                        style: const TextStyle(
                          color: Color(0xff008A64),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // const Spacer(),
                    // DropdownButtonHideUnderline(
                    //   child: DropdownButton2<String>(
                    //     isExpanded: true,
                    //     hint: const Text(
                    //       'Opportunities',
                    //       style: TextStyle(fontSize: 12, color: Colors.black),
                    //     ),
                    //     items: tabbarNames
                    //         .skip(1)
                    //         .map((item) => DropdownMenuItem<String>(
                    //               value: item,
                    //               child: Text(
                    //                 item,
                    //                 style: const TextStyle(fontSize: 12),
                    //               ),
                    //             ))
                    //         .toList(),
                    //     value: leadItem.selectedValue,
                    //     onChanged: (String? value) {
                    //       if (value == 'Engagement') {
                    //         _moveToEngagement(leadItem);
                    //       } else if (value == 'Negotiation') {
                    //         _moveToNegotiation(leadItem);
                    //       } else if (value == 'Closed') {
                    //         _moveToCreateTaskPage(context, leadItem);
                    //       } else if (value == 'Order Processing') {
                    //         _navigateToCreateTaskPage(context, leadItem, false);
                    //       }
                    //     },
                    //     buttonStyleData: const ButtonStyleData(
                    //       padding: EdgeInsets.symmetric(horizontal: 16),
                    //       height: 32,
                    //       width: 140,
                    //       decoration: BoxDecoration(color: Colors.white),
                    //     ),
                    //     menuItemStyleData: const MenuItemStyleData(
                    //       height: 30,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                leadItem.description,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(letterSpacing: -0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color.fromARGB(255, 25, 23, 49),
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      iconStyleData: IconStyleData(
                          icon: Icon(Icons.arrow_drop_down),
                          iconDisabledColor: Colors.white,
                          iconEnabledColor: Colors.white),
                      isExpanded: true,
                      hint: const Text(
                        'Opportunities',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      items: tabbarNames
                          .skip(1)
                          .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
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
                          _navigateToCreateTaskPage(context, leadItem, false);
                        }
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 24,
                        width: 136,
                        decoration:
                            BoxDecoration(color: const Color(0xff0175FF)),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 30,
                      ),
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 8),
              // Text(leadItem.description),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    leadItem.createdDate,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.w600),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ElevatedButton(
                        //   onPressed: () {
                        //     _handleIgnore(leadItem);
                        //   },
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: Colors.white,
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(5),
                        //       side:
                        //           const BorderSide(color: Colors.red, width: 2),
                        //     ),
                        //     minimumSize: const Size(50, 35),
                        //   ),
                        //   child: const Text('Ignore',
                        //       style: TextStyle(color: Colors.red)),
                        // ),

                        /*
                        IconButton(
                          iconSize: 40,
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _handleIgnore(leadItem);  
                          },
                        ),*/

                        SizedBox(
                          height: 22,
                          width: 80,
                          child: TextButton(
                            style: ButtonStyle(
                              padding:
                                  MaterialStatePropertyAll(EdgeInsets.all(1.0)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: BorderSide(color: Colors.red))),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  const Color(0xffF01C54)),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            onPressed: () {
                              _handleIgnore(leadItem);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 12,
                        ),
                        // const SizedBox(width: 8),
                        // ElevatedButton(
                        //   onPressed: () {
                        //     _moveToEngagement(leadItem);
                        //   },
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: const Color(0xff0069BA),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(5),
                        //     ),
                        //     minimumSize: const Size(50, 35),
                        //   ),
                        //   child: const Text('Accept',
                        //       style: TextStyle(color: Colors.white)),
                        // ),

                        SizedBox(
                          height: 22,
                          width: 80,
                          child: TextButton(
                            style: ButtonStyle(
                              padding:
                                  MaterialStatePropertyAll(EdgeInsets.all(1.0)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: BorderSide(
                                          color: const Color(0xff4566DD)))),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  const Color(0xff4566DD)),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            onPressed: () {
                              _moveToEngagement(leadItem);
                            },
                            child: Text(
                              'Accept',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),

                        /*
                        IconButton(
                          iconSize: 40,
                          icon: Icon(
                            Icons.check_circle,
                            color: Color(0xff0069BA),
                          ),
                          onPressed: () {
                            _moveToEngagement(leadItem);
                          },
                        ),
                        */
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
        return EngagementLeadItem(
          leadItem: leadItem,
          onMoveToNegotiation: () => _moveFromEngagementToNegotiation(leadItem),
          onMoveToOrderProcessing: (leadItem, salesOrderId, quantity) async {
            // 调用更新销售人员表现的函数
            await _updateSalesmanPerformance(salesmanId);
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
                  id: leadItem.id,
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
      LeadItem leadItem, String salesOrderId, int? quantity) async {
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
            // 调用更新销售人员表现的函数
            await _updateSalesmanPerformance(salesmanId);
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
                  id: leadItem.id,
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
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 2.0, horizontal: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200.0,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8.0),
                            Container(
                              width: double.infinity,
                              height: 24.0,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8.0),
                            Container(
                              width: double.infinity,
                              height: 24.0,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
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
              return _buildShimmerCard();
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
  final int id; // 添加这一行
  final int salesmanId;
  final String customerName;
  final String description;
  final String createdDate;
  final String amount;
  DateTime? engagementStartDate;
  DateTime? negotiationStartDate;
  String? selectedValue;
  String contactNumber;
  String emailAddress;
  String stage;
  String addressLine1;
  String? salesOrderId;
  String? previousStage;
  int? quantity;
  String get formattedAmount {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return 'RM${formatter.format(double.parse(amount.substring(2)))}';
  }

  LeadItem({
    required this.salesmanId,
    required this.customerName,
    required this.description,
    required this.createdDate,
    required this.amount,
    this.selectedValue,
    required this.contactNumber,
    required this.emailAddress,
    required this.stage,
    required this.addressLine1,
    this.salesOrderId,
    this.previousStage,
    this.quantity,
    required this.id,
    this.engagementStartDate,
    this.negotiationStartDate,
  });

  void moveToEngagement(Function(LeadItem) onMoveToEngagement) {
    onMoveToEngagement(this);
  }
}
