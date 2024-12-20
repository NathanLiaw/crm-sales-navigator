import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/screens/home/create_lead_page.dart';
import 'package:sales_navigator/screens/home/create_task_page.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/screens/customer_insight/customer_insights.dart';
import 'package:sales_navigator/model/notification_state.dart';
import 'dart:async';
import 'package:sales_navigator/screens/notification/notification_page.dart';
import 'package:sales_navigator/screens/home/sales_lead_closed_widget.dart';
import 'package:sales_navigator/screens/home/sales_lead_eng_widget.dart';
import 'package:sales_navigator/screens/home/sales_lead_nego_widget.dart';
import 'package:sales_navigator/screens/home/sales_lead_orderprocessing_widget.dart';
import 'package:sales_navigator/utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

final List<String> tabbarNames = [
  'Opportunities',
  'Engagement',
  'Negotiation',
  'Order Processing',
  'Closed',
];

// Auto update salesman performance
class SalesmanPerformanceUpdater {
  Timer? _timer;

  void startPeriodicUpdate(int salesmanId) {
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _updateSalesmanPerformance(salesmanId);
    });
  }

  void stopPeriodicUpdate() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _updateSalesmanPerformance(int salesmanId) async {
    final String apiUrl =
        '${dotenv.env['API_URL']}/sales_lead/update_salesman_performance.php?salesman_id=$salesmanId';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'salesman_id': salesmanId.toString()},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          developer.log('Salesman performance updated successfully.');
        } else {
          developer
              .log('Failed to update performance: ${jsonResponse['message']}');
        }
      } else {
        developer.log('Server error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating salesman performance: $e');
    }
  }
}

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<LeadItem> leadItems = [];
  List<LeadItem> engagementLeads = [];
  List<LeadItem> negotiationLeads = [];
  List<LeadItem> orderProcessingLeads = [];
  List<LeadItem> closedLeads = [];

  Map<int, DateTime> latestModifiedDates = {};
  Map<int, double> latestTotals = {};
  late int salesmanId;

  bool _isLoading = true;
  late SalesmanPerformanceUpdater _performanceUpdater;

  late TabController _tabController;
  String _sortBy = 'created_date';
  bool _sortAscending = true;
  bool _isButtonVisible = true;
  int _unreadNotifications = 0;

  DateTimeRange? dateRange;
  DateTime? _startDate;
  DateTime? _endDate;

  String _timeFilter = 'All Time';
  List<String> timeFilterOptions = [
    'All Time',
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'This Year',
    'Custom Range',
  ];

  List<LeadItem> _filterLeadsByTime(List<LeadItem> leads, String timeFilter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisYearStart = DateTime(now.year, 1, 1);

    return leads.where((lead) {
      if (lead.createdDate.isEmpty) {
        return false;
      }

      DateTime? leadDate;
      try {
        leadDate = DateFormat('MM/dd/yyyy').parse(lead.createdDate);
      } catch (e) {
        developer.log('Error parsing date: ${lead.createdDate}');
        return false;
      }

      switch (timeFilter) {
        case 'Today':
          return leadDate.isAfter(today.subtract(const Duration(seconds: 1))) &&
              leadDate.isBefore(today.add(const Duration(days: 1)));
        case 'Yesterday':
          return leadDate
                  .isAfter(yesterday.subtract(const Duration(seconds: 1))) &&
              leadDate.isBefore(today);
        case 'This Week':
          return leadDate.isAfter(
                  thisWeekStart.subtract(const Duration(seconds: 1))) &&
              leadDate.isBefore(today.add(const Duration(days: 1)));
        case 'This Month':
          return leadDate.isAfter(
                  thisMonthStart.subtract(const Duration(seconds: 1))) &&
              leadDate.isBefore(now);
        case 'This Year':
          return leadDate.isAfter(
                  thisYearStart.subtract(const Duration(seconds: 1))) &&
              leadDate.isBefore(now);
        case 'Custom Range':
          if (_startDate != null && _endDate != null) {
            return leadDate.isAfter(
                    _startDate!.subtract(const Duration(seconds: 1))) &&
                leadDate.isBefore(_endDate!.add(const Duration(days: 1)));
          }
          return true;
        default:
          return true;
      }
    }).toList();
  }

  List<LeadItem> _filteredOpportunities = [];
  List<LeadItem> _filteredEngagement = [];
  List<LeadItem> _filteredNegotiation = [];
  List<LeadItem> _filteredOrderProcessing = [];
  List<LeadItem> _filteredClosed = [];

  void _updateFilteredLists() {
    if (!mounted) return;
    setState(() {
      _filteredOpportunities = _filterLeadsByTime(leadItems, _timeFilter);
      _filteredEngagement = _filterLeadsByTime(engagementLeads, _timeFilter);
      _filteredNegotiation = _filterLeadsByTime(negotiationLeads, _timeFilter);
      _filteredOrderProcessing =
          _filterLeadsByTime(orderProcessingLeads, _timeFilter);
      _filteredClosed = _filterLeadsByTime(closedLeads, _timeFilter);
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeSalesmanId();
    _performanceUpdater = SalesmanPerformanceUpdater();
    _loadUnreadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).addListener(() {
        if (FocusScope.of(context).hasFocus) {
          _updateFilteredLists();
        }
      });
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        _updateFilteredLists();
      });
    });
    _tabController = TabController(
      length: tabbarNames.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      setState(() {
        _isButtonVisible = _tabController.index == 0;
      });
    });
  }

  Future<void> _showDateRangePicker() async {
    final previousStartDate = _startDate;
    final previousEndDate = _endDate;
    final previousDateRange = dateRange;
    final previousTimeFilter = _timeFilter;

    final initialDateRange = dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );

    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.9;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime? tempStartDate = _startDate;
        DateTime? tempEndDate = _endDate;
        DateTimeRange? tempDateRange = dateRange;

        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 400,
                  child: CalendarDatePicker2(
                    config: CalendarDatePicker2Config(
                      calendarType: CalendarDatePicker2Type.range,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      selectedDayHighlightColor: const Color(0xFF0175FF),
                      weekdayLabelTextStyle: const TextStyle(
                        color: Color(0xFF0175FF),
                        fontWeight: FontWeight.bold,
                      ),
                      centerAlignModePicker: true,
                      customModePickerIcon: const SizedBox(),
                      yearTextStyle: const TextStyle(
                        fontSize: 13,
                        height: 1.0,
                      ),
                      controlsTextStyle: const TextStyle(
                        fontSize: 13,
                        height: 1.0,
                      ),
                      dayTextStyle: const TextStyle(
                        fontSize: 13,
                        height: 1.0,
                      ),
                      selectedDayTextStyle: const TextStyle(
                        fontSize: 13,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    value: [initialDateRange.start, initialDateRange.end],
                    onValueChanged: (dates) {
                      if (dates.length == 2) {
                        tempStartDate = dates[0];
                        tempEndDate = dates[1];
                        tempDateRange = DateTimeRange(
                          start: dates[0],
                          end: dates[1],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _startDate = previousStartDate;
                          _endDate = previousEndDate;
                          dateRange = previousDateRange;
                          _timeFilter = previousTimeFilter;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _startDate = tempStartDate;
                          _endDate = tempEndDate;
                          dateRange = tempDateRange;
                          _timeFilter = 'Custom Range';
                        });
                        _updateFilteredLists();
                        Navigator.pop(context);
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: timeFilterOptions.map((option) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(option),
                      if (_timeFilter == option)
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFF0175FF),
                        ),
                    ],
                  ),
                  tileColor:
                      _timeFilter == option ? const Color(0xFFF5F8FF) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _timeFilter == option
                        ? const BorderSide(color: Color(0xFF0175FF), width: 1)
                        : BorderSide.none,
                  ),
                  onTap: () {
                    if (option == 'Custom Range') {
                      Navigator.of(context).pop();
                      _showDateRangePicker();
                    } else {
                      setState(() {
                        _timeFilter = option;
                        _startDate = null;
                        _endDate = null;
                        _updateFilteredLists();
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  subtitle: option == 'Custom Range' &&
                          _startDate != null &&
                          _endDate != null
                      ? Text(
                          '${DateFormat('MM/dd/yyyy').format(_startDate!)} - ${DateFormat('MM/dd/yyyy').format(_endDate!)}',
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        );
      },
    );
  }

  Future<void> _loadUnreadNotifications() async {
    final salesmanId = await UtilityFunction.getUserId();
    final count = await NotificationsPage.getUnreadCount(salesmanId);

    if (mounted) {
      Provider.of<NotificationState>(context, listen: false)
          .setUnreadCount(count);
    }
  }

  void _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    developer.log('Initialized salesmanId: $id');
    setState(() {
      salesmanId = id;
    });
    _performanceUpdater.startPeriodicUpdate(salesmanId);
    await _cleanAndValidateLeadData();
    await _fetchLeadItems();
  }

  void _sortLeads(List<LeadItem> leads) {
    setState(() {
      leads.sort((a, b) {
        switch (_sortBy) {
          case 'created_date':
            return _sortAscending
                ? a.createdDate.compareTo(b.createdDate)
                : b.createdDate.compareTo(a.createdDate);
          case 'predicted_sales':
            double aAmount = double.parse(a.amount.substring(2));
            double bAmount = double.parse(b.amount.substring(2));
            return _sortAscending
                ? aAmount.compareTo(bAmount)
                : bAmount.compareTo(aAmount);
          case 'customer_name':
            return _sortAscending
                ? a.customerName.compareTo(b.customerName)
                : b.customerName.compareTo(a.customerName);
          default:
            return 0;
        }
      });
    });
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort by'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Created Date'),
                      if (_sortBy == 'created_date')
                        Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: const Color(0xFF0175FF),
                        ),
                    ],
                  ),
                  tileColor: _sortBy == 'created_date'
                      ? const Color(0xFFF5F8FF)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _sortBy == 'created_date'
                        ? const BorderSide(color: Color(0xFF0175FF), width: 1)
                        : BorderSide.none,
                  ),
                  onTap: () {
                    _updateSortCriteria('created_date');
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Predicted Sales'),
                      if (_sortBy == 'predicted_sales')
                        Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: const Color(0xFF0175FF),
                        ),
                    ],
                  ),
                  tileColor: _sortBy == 'predicted_sales'
                      ? const Color(0xFFF5F8FF)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _sortBy == 'predicted_sales'
                        ? const BorderSide(color: Color(0xFF0175FF), width: 1)
                        : BorderSide.none,
                  ),
                  onTap: () {
                    _updateSortCriteria('predicted_sales');
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer Name'),
                      if (_sortBy == 'customer_name')
                        Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: const Color(0xFF0175FF),
                        ),
                    ],
                  ),
                  tileColor: _sortBy == 'customer_name'
                      ? const Color(0xFFF5F8FF)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _sortBy == 'customer_name'
                        ? const BorderSide(color: Color(0xFF0175FF), width: 1)
                        : BorderSide.none,
                  ),
                  onTap: () {
                    _updateSortCriteria('customer_name');
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        );
      },
    );
  }

  void _updateSortCriteria(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSortBy;
        _sortAscending = true;
      }
      _sortLeads(leadItems);
      _sortLeads(engagementLeads);
      _sortLeads(negotiationLeads);
      _sortLeads(orderProcessingLeads);
      _sortLeads(closedLeads);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _performanceUpdater.stopPeriodicUpdate();
    super.dispose();
  }

  // Update salesman performance
  Future<void> _updateSalesmanPerformance(int salesmanId) async {
    final String apiUrl =
        '${dotenv.env['API_URL']}/sales_lead/update_salesman_performance.php?salesman_id=$salesmanId';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'salesman_id': salesmanId.toString()},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          developer.log('Salesman performance updated successfully.');
        } else {
          developer
              .log('Failed to update performance: ${jsonResponse['message']}');
        }
      } else {
        developer.log('Server error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating salesman performance: $e');
    }
  }

  // Get average closed value
  Future<double> _getAverageClosedValue(
      int salesmanId, String startDate, String endDate) async {
    final String apiUrl =
        '${dotenv.env['API_URL']}/sales_lead/get_average_closed_value.php?salesman_id=$salesmanId&start_date=$startDate&end_date=$endDate';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'salesman_id': salesmanId.toString(),
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['averageClosedValue'];
        } else {
          developer.log(
              'Failed to get average closed value: ${jsonResponse['message']}');
          return 0;
        }
      } else {
        developer.log('Server error: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      developer.log('Error getting average closed value: $e');
      return 0;
    }
  }

  Future<void> _cleanAndValidateLeadData() async {
    developer
        .log('Starting _cleanAndValidateLeadData for salesman_id: $salesmanId');
    final url = Uri.parse(
        '${dotenv.env['API_URL']}/sales_lead/clean_validate_leads.php?salesman_id=$salesmanId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        developer.log('_cleanAndValidateLeadData response: ${response.body}');
        if (data['status'] == 'success') {
          developer.log('Lead data cleaned and validated successfully.');
        } else {
          developer.log('Error: ${data['message']}');
        }
      } else {
        developer
            .log('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error making API call: $e');
    }
  }

  // Auto generate lead item from cart
  Future<void> _fetchLeadItems() async {
    if (!mounted) return;
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/get_sales_lead_automatically.php?salesman_id=$salesmanId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final leads = data['leads'] as List;

          for (var lead in leads) {
            var id = lead['id'] ?? 0;
            var customerName = lead['customer_name'] ?? 'Unknown';
            var description = lead['description'] ?? '';
            var total =
                double.tryParse(lead['total']?.toString() ?? '0') ?? 0.0;
            var createdDate = lead['created_date'] ?? '';
            var contactNumber = lead['contact_number'] ?? '';
            var emailAddress = lead['email_address'] ?? '';
            var addressLine1 = lead['address'] ?? '';

            setState(() {
              leadItems.add(LeadItem(
                id: id,
                salesmanId: salesmanId,
                customerName: customerName,
                description: description,
                createdDate: createdDate,
                amount: 'RM${total.toStringAsFixed(2)}',
                contactNumber: contactNumber,
                emailAddress: emailAddress,
                stage: 'Opportunities',
                addressLine1: addressLine1,
                salesOrderId: '',
              ));
            });

            developer.log("Created new lead for customer: $customerName");
          }
        } else {
          developer.log('Error fetching lead items: ${data['message']}');
        }
      } else {
        developer.log('Error fetching lead items: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching lead items: $e');
    }

    await _fetchCreateLeadItems();

    _sortLeads(leadItems);
    _sortLeads(engagementLeads);
    _sortLeads(negotiationLeads);
    _sortLeads(orderProcessingLeads);
    _sortLeads(closedLeads);
    _updateFilteredLists();
    developer.log("Finished _fetchLeadItems");
  }

  Future<void> _fetchCreateLeadItems() async {
    final apiUrl = dotenv.env['API_URL'];
    const offset = 0;
    const limit = 100;

    try {
      final response = await http.get(Uri.parse(
          '$apiUrl/sales_lead/get_sales_leads.php?salesman_id=$salesmanId&offset=$offset&limit=$limit'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final salesLeads = data['salesLeads'] as List;

          leadItems.clear();
          engagementLeads.clear();
          negotiationLeads.clear();
          orderProcessingLeads.clear();
          closedLeads.clear();

          for (var item in salesLeads) {
            String createdDate = item['created_date'] != null
                ? DateFormat('MM/dd/yyyy')
                    .format(DateTime.parse(item['created_date']))
                : DateFormat('MM/dd/yyyy').format(DateTime.now());

            final leadItem = LeadItem(
              id: item['id'] != null ? item['id'] as int : 0,
              salesmanId: salesmanId,
              customerName: item['customer_name'] as String,
              description: item['description'] ?? '',
              createdDate: createdDate,
              amount: 'RM${item['predicted_sales']}',
              contactNumber: item['contact_number'] ?? '',
              emailAddress: item['email_address'] ?? '',
              stage: item['stage'] as String,
              addressLine1: item['address'] ?? '',
              salesOrderId: item['so_id']?.toString(),
              previousStage: item['previous_stage']?.toString(),
              quantity: item['quantity'] != null ? item['quantity'] as int : 0,
              engagementStartDate: item['engagement_start_date'] != null
                  ? DateTime.parse(item['engagement_start_date'])
                  : null,
              negotiationStartDate: item['negotiation_start_date'] != null
                  ? DateTime.parse(item['negotiation_start_date'])
                  : null,
            );

            setState(() {
              if (leadItem.stage == 'Opportunities') {
                leadItems.add(leadItem);
              } else if (leadItem.stage == 'Engagement') {
                engagementLeads.add(leadItem);
              } else if (leadItem.stage == 'Negotiation') {
                negotiationLeads.add(leadItem);
              } else if (leadItem.stage == 'Order Processing') {
                orderProcessingLeads.add(leadItem);
              } else if (leadItem.stage == 'Closed') {
                closedLeads.add(leadItem);
              }
            });
          }
        } else {
          developer.log('Error: ${data['message']}');
        }
      } else {
        developer.log('Error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching sales_lead items: $e');
    }
    _updateFilteredLists();
  }

  Future<String> _fetchCustomerName(int customerId) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/get_customer_name.php?customer_id=$customerId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          return data['company_name'];
        } else {
          developer.log('Error fetching customer name: ${data['message']}');
          return 'Unknown';
        }
      } else {
        developer
            .log('Error fetching customer name: HTTP ${response.statusCode}');
        return 'Unknown';
      }
    } catch (e) {
      developer.log('Error fetching customer name: $e');
      return 'Unknown';
    }
  }

  Future<void> _updateSalesOrderId(
      LeadItem leadItem, String salesOrderId) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse('$apiUrl/sales_lead/update_sales_order_id.php');

    try {
      final response = await http.post(
        url,
        body: {
          'lead_id': leadItem.id.toString(),
          'sales_order_id': salesOrderId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          developer.log('Sales order ID updated successfully');
        } else {
          developer.log('Error updating sales order ID: ${data['message']}');
        }
      } else {
        developer
            .log('Error updating sales order ID: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating sales order ID: $e');
    }
  }

  Future<void> _moveFromNegotiationToOrderProcessing(
      LeadItem leadItem, String salesOrderId, int? quantity) async {
    String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/update_sales_lead_from_negotiation_to_order_processing.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'sales_order_id': salesOrderId,
      'quantity': quantity?.toString() ?? '',
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            negotiationLeads.remove(leadItem);
            leadItem.salesOrderId = salesOrderId;
            leadItem.quantity = quantity;
          });

          await _updateLeadStage(leadItem, 'Negotiation');
          await _updateSalesOrderId(leadItem, salesOrderId);
          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Successfully moved lead to Order Processing stage'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to move lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Order Processing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving lead to Order Processing: $e')),
      );
    }
  }

  Future<void> _moveToEngagement(LeadItem leadItem) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/update_sales_lead_to_engagement.php?lead_id=${leadItem.id}&salesman_id=$salesmanId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          leadItem.contactNumber = data['contact_number'];
          leadItem.emailAddress = data['email_address'];

          setState(() {
            leadItems.remove(leadItem);
            engagementLeads.add(leadItem);
          });

          await _updateLeadStage(leadItem, 'Engagement');
          await _updateSalesmanPerformance(salesmanId);

          developer.log('Lead moved to Engagement stage successfully');
        } else {
          developer
              .log('Error moving lead to Engagement stage: ${data['message']}');
        }
      } else {
        developer.log(
            'Error moving lead to Engagement stage: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Engagement stage: $e');
    }
  }

  Future<void> _moveToNegotiation(LeadItem leadItem) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/update_sales_lead_to_negotiation.php?lead_id=${leadItem.id}&salesman_id=$salesmanId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          leadItem.contactNumber = data['contact_number'];
          leadItem.emailAddress = data['email_address'];

          setState(() {
            leadItems.remove(leadItem);
            negotiationLeads.add(leadItem);
          });

          await _updateLeadStage(leadItem, 'Negotiation');
          await _updateSalesmanPerformance(salesmanId);

          developer.log('Lead moved to Negotiation stage successfully');
        } else {
          developer.log(
              'Error moving lead to Negotiation stage: ${data['message']}');
        }
      } else {
        developer.log(
            'Error moving lead to Negotiation stage: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Negotiation stage: $e');
    }
  }

  Future<void> _moveFromEngagementToNegotiation(LeadItem leadItem) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
            '$apiUrl/sales_lead/update_sales_lead_from_engagement_to_negotiation.php')
        .replace(queryParameters: {
      'lead_id': leadItem.id.toString(),
      'salesman_id': salesmanId.toString(),
    });

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            engagementLeads.remove(leadItem);
            negotiationLeads.add(leadItem);
          });

          await _updateLeadStage(leadItem, 'Negotiation');
          await _updateSalesmanPerformance(salesmanId);

          developer.log('Successfully moved lead to Negotiation stage');
        } else {
          developer.log(
              'Error moving lead to Negotiation stage: ${data['message']}');
        }
      } else {
        developer.log(
            'Error moving lead to Negotiation stage: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Negotiation stage: $e');
    }
  }

  Future<void> _moveFromOrderProcessingToClosed(LeadItem leadItem) async {
    String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/update_sales_lead_from_order_processing_to_closed.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            orderProcessingLeads.remove(leadItem);
            leadItem.stage = 'Closed';
            leadItem.previousStage = responseData['previous_stage'];
            closedLeads.add(leadItem);
          });

          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully moved lead to Closed stage'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to move lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Closed stage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving lead to Closed stage: $e')),
      );
    }
  }

  Future<void> _updateLeadStage(LeadItem leadItem, String stage) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/update_lead_stage.php?lead_id=${leadItem.id}&stage=$stage');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            leadItem.previousStage = leadItem.stage;
            leadItem.stage = stage;
            if (stage == 'Negotiation' &&
                leadItem.negotiationStartDate == null) {
              leadItem.negotiationStartDate = DateTime.now();
            } else if (stage == 'Engagement' &&
                leadItem.engagementStartDate == null) {
              leadItem.engagementStartDate = DateTime.now();
            }
          });

          developer.log(
              'Successfully updated lead stage to $stage for lead ${leadItem.id}');
        } else {
          developer.log('Error updating stage: ${data['message']}');
        }
      } else {
        developer.log('Error updating stage: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating stage: $e');
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
    String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/update_sales_lead_from_opportunities_to_order_processing.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'sales_order_id': salesOrderId,
      'quantity': quantity?.toString() ?? '',
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            leadItems.remove(leadItem);
            leadItem.salesOrderId = salesOrderId;
            leadItem.quantity = quantity;
            leadItem.stage = 'Order Processing';
            leadItem.previousStage = responseData['previous_stage'];
          });

          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Successfully moved lead to Order Processing stage'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to move lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Order Processing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving lead to Order Processing: $e')),
      );
    }
  }

  Future<void> _onDeleteEngagementLead(LeadItem leadItem) async {
    String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/delete_engagement_lead.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            engagementLeads.remove(leadItem);
          });

          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully deleted Engagement lead'),
              backgroundColor: Colors.green,
            ),
          );
          developer
              .log('Engagement lead deleted and event logged successfully');
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to delete lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error deleting engagement lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting Engagement lead: $e')),
      );
    }
  }

  Future<void> _onDeleteNegotiationLead(LeadItem leadItem) async {
    String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/delete_negotiation_lead.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            negotiationLeads.remove(leadItem);
          });

          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully deleted Negotiation lead'),
              backgroundColor: Colors.green,
            ),
          );

          developer
              .log('Negotiation lead deleted and event logged successfully');
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to delete lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error deleting negotiation lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting Negotiation lead: $e')),
      );
    }
  }

  Future<void> _onUndoEngagementLead(
      LeadItem leadItem, String previousStage) async {
    String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/update_engagement_to_previous_stage.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'previous_stage': previousStage,
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            engagementLeads.remove(leadItem);
            leadItem.stage = previousStage;
            leadItem.previousStage = null;
            leadItem.engagementStartDate = null;
            if (previousStage == 'Opportunities') {
              leadItems.add(leadItem);
            } else if (previousStage == 'Negotiation') {
              negotiationLeads.add(leadItem);
            }
          });

          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully undone Engagement lead'),
              backgroundColor: Colors.green,
            ),
          );

          developer.log('Engagement lead undone and event logged successfully');
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to undo lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error undoing engagement lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error undoing Engagement lead: $e')),
      );
    }
  }

  Future<void> _onUndoNegotiationLead(
      LeadItem leadItem, String previousStage) async {
    String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/update_negotiation_to_previous_stage.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'previous_stage': previousStage,
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            negotiationLeads.remove(leadItem);
            leadItem.stage = previousStage;
            leadItem.previousStage = null;
            leadItem.negotiationStartDate = null;
            if (previousStage == 'Opportunities') {
              leadItems.add(leadItem);
            } else if (previousStage == 'Engagement') {
              engagementLeads.add(leadItem);
            }
          });

          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully undone Negotiation lead'),
              backgroundColor: Colors.green,
            ),
          );

          developer
              .log('Negotiation lead undone and event logged successfully');
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to undo lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error undoing negotiation lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error undoing Negotiation lead: $e')),
      );
    }
  }

  Future<void> _createLead(
      String customerName, String description, String amount) async {
    String baseUrl = '${dotenv.env['API_URL']}/sales_lead/update_new_lead.php';

    final Map<String, String> queryParameters = {
      'customer_name': customerName,
      'description': description,
      'amount': amount,
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          LeadItem leadItem = LeadItem(
            id: responseData['lead_id'],
            salesmanId: salesmanId,
            customerName: customerName,
            description: description,
            createdDate: DateFormat('MM/dd/yyyy').format(DateTime.now()),
            amount: 'RM$amount',
            contactNumber: responseData['contact_number'],
            emailAddress: responseData['email_address'],
            stage: 'Opportunities',
            addressLine1: responseData['address_line_1'],
            salesOrderId: '',
          );

          setState(() {
            leadItems.add(leadItem);
          });

          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to create lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error creating lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create lead: $e')),
      );
    }
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
      String baseUrl =
          '${dotenv.env['API_URL']}/sales_lead/delete_opportunities_lead.php';

      final Map<String, String> queryParameters = {
        'lead_id': leadItem.id.toString(),
        'salesman_id': salesmanId.toString(),
      };

      final Uri uri =
          Uri.parse(baseUrl).replace(queryParameters: queryParameters);

      try {
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success') {
            setState(() {
              leadItems.remove(leadItem);
            });

            await _updateSalesmanPerformance(salesmanId);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'])),
            );
          } else {
            throw Exception(responseData['message']);
          }
        } else {
          throw Exception('Failed to delete lead: ${response.statusCode}');
        }
      } catch (e) {
        developer.log('Error deleting lead: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete lead: $e')),
        );
      }
    }
  }

  void _addNewLead(LeadItem newLead) {
    setState(() {
      leadItems.add(newLead);
    });
  }

  void _handleRemoveOrderProcessingLead(LeadItem leadItem) {
    setState(() {
      orderProcessingLeads.remove(leadItem);
    });
  }

  Future<int?> _getSalesmanId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('id');
    developer.log("_getSalesmanId returned: $id");
    return id;
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
                actions: [
                  Consumer<NotificationState>(
                    builder: (context, notificationState, child) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications,
                                  color: Colors.white),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationsPage(),
                                  ),
                                );
                                _loadUnreadNotifications();
                              },
                            ),
                            if (notificationState.unreadCount > 0)
                              Positioned(
                                right: 4,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    notificationState.unreadCount > 99
                                        ? '99+'
                                        : notificationState.unreadCount
                                            .toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          _unreadNotifications > 99
                              ? '99+'
                              : _unreadNotifications.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    padding: EdgeInsets.zero,
                    onSelected: (String choice) {
                      if (choice == 'sort') {
                        _showSortOptions();
                      } else if (choice == 'filter') {
                        _showFilterDialog();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'sort',
                        child: Row(
                          children: [
                            Icon(Icons.sort, size: 20),
                            SizedBox(width: 8),
                            Text('Sort'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'filter',
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, size: 20),
                            SizedBox(width: 8),
                            Text('Filter'),
                          ],
                        ),
                      ),
                    ],
                    position: PopupMenuPosition.under,
                  ),
                ],
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
                        padding: const EdgeInsets.only(left: 12, bottom: 2),
                        child: Column(
                          children: [
                            const Spacer(),
                            Text(
                              'Sales Lead Pipeline',
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(letterSpacing: -0.8),
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
                    controller: _tabController,
                    labelColor: const Color(0xff0175FF),
                    indicatorColor: const Color(0xff0175FF),
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(
                          text:
                              'Opportunities(${_filteredOpportunities.length})'),
                      Tab(text: 'Engagement(${_filteredEngagement.length})'),
                      Tab(text: 'Negotiation(${_filteredNegotiation.length})'),
                      Tab(
                          text:
                              'Order Processing(${_filteredOrderProcessing.length})'),
                      Tab(text: 'Closed(${_filteredClosed.length})'),
                    ],
                    labelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
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
              floatingActionButton:
                  _isButtonVisible ? _buildFloatingActionButton(context) : null,
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

  Widget _buildShimmerTab() {
    return ListView.builder(
      itemCount: 4,
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
                const SizedBox(height: 8.0),
                Container(
                  width: double.infinity,
                  height: 16.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 8.0),
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
                        onCreateLead: (LeadItem newLead) {
                          setState(() {
                            leadItems.add(newLead);
                          });
                        },
                      ),
                    ),
                  ).then((_) {
                    setState(() {
                      _fetchLeadItems();
                    });
                  });
                },
                icon: const Icon(Icons.add, color: Colors.white),
                shape: const RoundedRectangleBorder(
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
    if (_isLoading) {
      return _buildShimmerTab();
    }
    final filteredLeads = _filterLeadsByTime(leadItems, _timeFilter);

    if (filteredLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No Sales Leads found for selected time period,\ncreate one now!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredLeads.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            _buildLeadItem(filteredLeads[index]),
            if (index == filteredLeads.length - 1) const SizedBox(height: 80),
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
            builder: (context) => CustomerInsightsPage(
              customerName: leadItem.customerName,
            ),
          ),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
            image: const DecorationImage(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      leadItem.customerName,
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(letterSpacing: -0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 25, 23, 49),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 18),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(71, 148, 255, 223),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        leadItem.formattedAmount,
                        style: const TextStyle(
                          color: Color(0xff008A64),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                leadItem.description,
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(letterSpacing: -0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color.fromARGB(255, 25, 23, 49),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      iconStyleData: const IconStyleData(
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
                        decoration: BoxDecoration(color: Color(0xff0175FF)),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 30,
                      ),
                    ),
                  ),
                ],
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
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 30,
                          width: 80,
                          child: TextButton(
                            style: ButtonStyle(
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.all(1.0)),
                              shape: WidgetStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side:
                                          const BorderSide(color: Colors.red))),
                              backgroundColor: WidgetStateProperty.all<Color>(
                                  const Color(0xffF01C54)),
                              foregroundColor: WidgetStateProperty.all<Color>(
                                  const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            onPressed: () {
                              _handleIgnore(leadItem);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        SizedBox(
                          height: 30,
                          width: 80,
                          child: TextButton(
                            style: ButtonStyle(
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.all(1.0)),
                              shape: WidgetStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xff4566DD)))),
                              backgroundColor: WidgetStateProperty.all<Color>(
                                  const Color(0xff4566DD)),
                              foregroundColor: WidgetStateProperty.all<Color>(
                                  const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            onPressed: () {
                              _moveToEngagement(leadItem);
                            },
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w300),
                            ),
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
      ),
    );
  }

  Widget _buildEngagementTab() {
    if (_isLoading) {
      return _buildShimmerTab();
    }
    final filteredLeads = _filterLeadsByTime(engagementLeads, _timeFilter);
    if (filteredLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No Engagement Leads yet,\nstart building relationships!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: filteredLeads.length,
        itemBuilder: (context, index) {
          LeadItem leadItem = filteredLeads[index];
          return EngagementLeadItem(
            leadItem: leadItem,
            onMoveToNegotiation: () =>
                _moveFromEngagementToNegotiation(leadItem),
            onMoveToOrderProcessing: (leadItem, salesOrderId, quantity) async {
              await _updateSalesmanPerformance(salesmanId);
              await _moveFromEngagementToOrderProcessing(
                  leadItem, salesOrderId, quantity);
              setState(() {
                filteredLeads.remove(leadItem);
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
                  filteredLeads.remove(leadItem);
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
  }

  Future<void> _moveFromEngagementToOrderProcessing(
      LeadItem leadItem, String salesOrderId, int? quantity) async {
    String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/update_sales_lead_from_engagement_to_order_processing.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'sales_order_id': salesOrderId,
      'quantity': quantity?.toString() ?? '',
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            engagementLeads.remove(leadItem);
            leadItem.salesOrderId = salesOrderId;
            leadItem.quantity = quantity;
            leadItem.stage = 'Order Processing';
            leadItem.previousStage = responseData['previous_stage'];
          });

          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Successfully moved lead to Order Processing stage'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to move lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Order Processing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving lead to Order Processing: $e')),
      );
    }
  }

  Widget _buildNegotiationTab() {
    if (_isLoading) {
      return _buildShimmerTab();
    }
    final filteredLeads = _filterLeadsByTime(negotiationLeads, _timeFilter);
    if (filteredLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No leads in negotiation,\nstart negotiating with your leads!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: filteredLeads.length,
        itemBuilder: (context, index) {
          LeadItem leadItem = filteredLeads[index];
          return NegotiationLeadItem(
            leadItem: leadItem,
            onMoveToOrderProcessing: (leadItem, salesOrderId, quantity) async {
              await _moveFromNegotiationToOrderProcessing(
                  leadItem, salesOrderId, quantity);
              await _updateSalesmanPerformance(salesmanId);
              setState(() {
                filteredLeads.remove(leadItem);
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
                    showTaskDetails: false,
                  ),
                ),
              );
              if (result != null && result['salesOrderId'] != null) {
                setState(() {
                  filteredLeads.remove(leadItem);
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
  }

  Widget _buildOrderProcessingTab() {
    if (_isLoading) {
      return _buildShimmerTab();
    }
    final filteredLeads = _filterLeadsByTime(orderProcessingLeads, _timeFilter);
    if (filteredLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fact_check,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No orders are being processed yet,\nstart managing your sales orders!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: filteredLeads.length,
        itemBuilder: (context, index) {
          LeadItem leadItem = filteredLeads[index];
          if (leadItem.salesOrderId == null) {
            return OrderProcessingLeadItem(
              leadItem: leadItem,
              status: 'Unknown',
              onMoveToClosed: _moveFromOrderProcessingToClosed,
              onRemoveLead: _handleRemoveOrderProcessingLead,
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
                              const SizedBox(height: 8.0),
                              Container(
                                width: double.infinity,
                                height: 24.0,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8.0),
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
                    onRemoveLead: _handleRemoveOrderProcessingLead,
                  );
                }
              },
            );
          }
        },
      );
    }
  }

  Future<String> _fetchSalesOrderStatus(String salesOrderId) async {
    try {
      final String apiUrl =
          '${dotenv.env['API_URL']}/sales_lead/get_sales_order_status.php?salesOrderId=$salesOrderId';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          var data = jsonResponse['data'];
          String newStatus = data['status'].toString();
          String createdDate = data['created'].toString();
          String expirationDate = data['expiration_date'].toString();
          String total = data['total'].toString();

          return '$newStatus|$createdDate|$expirationDate|$total';
        } else {
          developer.log('Error: ${jsonResponse['message']}');
          return 'Unknown|Unknown|Unknown|Unknown';
        }
      } else {
        developer.log(
            'Error: Failed to fetch data from API with status code ${response.statusCode}');
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
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_URL']}/sales_lead/get_sales_order_details.php?id=$salesOrderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'formattedCreatedDate':
                responseData['data']['formattedCreatedDate'].toString(),
            'expirationDate': responseData['data']['expirationDate'].toString(),
            'total': responseData['data']['total'].toString(),
            'quantity': responseData['data']['quantity'].toString(),
          };
        } else {
          developer.log('Error: ${responseData['message']}');
          return {};
        }
      } else {
        developer
            .log('HTTP request failed with status: ${response.statusCode}');
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
    if (_isLoading) {
      return _buildShimmerTab();
    }
    final filteredLeads = _filterLeadsByTime(closedLeads, _timeFilter);
    if (filteredLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No leads are closed yet,\nkeep working towards your goals!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: filteredLeads.length,
        itemBuilder: (context, index) {
          LeadItem leadItem = filteredLeads[index];
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
}

class LeadItem {
  final int id;
  final int? salesmanId;
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
  String status;
  String get formattedAmount {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return 'RM${formatter.format(double.parse(amount.substring(2)))}';
  }

  LeadItem({
    this.salesmanId,
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
    this.status = 'Pending',
  });

  void moveToEngagement(Function(LeadItem) onMoveToEngagement) {
    onMoveToEngagement(this);
  }
}
