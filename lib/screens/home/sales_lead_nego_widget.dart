import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/screens/home/create_task_page.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/screens/customer_insight/customer_insights.dart';
import 'package:sales_navigator/screens/home/home_page.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:sales_navigator/screens/home/view_tasks_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NegotiationLeadItem extends StatefulWidget {
  final LeadItem leadItem;
  final Function(LeadItem) onDeleteLead;
  final Function(LeadItem, String) onUndoLead;
  final Function(LeadItem) onComplete;
  final Function(LeadItem, String, int?) onMoveToOrderProcessing;

  const NegotiationLeadItem({
    super.key,
    required this.leadItem,
    required this.onDeleteLead,
    required this.onUndoLead,
    required this.onComplete,
    required this.onMoveToOrderProcessing,
  });

  @override
  _NegotiationLeadItemState createState() => _NegotiationLeadItemState();
}

class _NegotiationLeadItemState extends State<NegotiationLeadItem> {
  String? title;
  String? description;
  DateTime? dueDate;
  List<Map<String, dynamic>> tasks = [];
  String _sortBy = 'creation_date';
  String _sortOrder = 'descending';
  bool _isTasksExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
    );
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email.trim(),
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  Future<void> _fetchTaskDetails() async {
    final String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/get_task_details.php';

    final Map<String, String> queryParameters = {
      'lead_id': widget.leadItem.id.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          if (mounted) {
            setState(() {
              tasks = (responseData['tasks'] as List).map((task) {
                return {
                  'id': task['id'],
                  'title': task['title'],
                  'description': task['description'],
                  'due_date': DateTime.parse(task['due_date']),
                  'creation_date': DateTime.parse(task['creation_date']),
                };
              }).toList();
            });
          }
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to fetch task details: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching task details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch task details: $e')),
      );
    }
  }

  Future<void> _navigateToCreateTaskPage(
      BuildContext context, bool showTaskDetails) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          id: widget.leadItem.id,
          customerName: widget.leadItem.customerName,
          contactNumber: widget.leadItem.contactNumber,
          emailAddress: widget.leadItem.emailAddress,
          address: widget.leadItem.addressLine1,
          lastPurchasedAmount: widget.leadItem.amount,
          existingTitle: title,
          existingDescription: description,
          existingDueDate: dueDate,
          showTaskDetails: showTaskDetails,
        ),
      ),
    );

    if (result != null && result['error'] == null) {
      if (result['hasTaskDetails'] == true) {
        _fetchTaskDetails();
      }

      if (result['salesOrderId'] != null) {
        String salesOrderId = result['salesOrderId'] as String;
        int? quantity = result['quantity'];
        await widget.onMoveToOrderProcessing(
            widget.leadItem, salesOrderId, quantity);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _navigateToEditTaskPage(
      BuildContext context, Map<String, dynamic> task) async {
    final taskId = task['id'];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          id: 0,
          customerName: widget.leadItem.customerName,
          contactNumber: widget.leadItem.contactNumber,
          emailAddress: widget.leadItem.emailAddress,
          address: widget.leadItem.addressLine1,
          lastPurchasedAmount: widget.leadItem.amount,
          existingTitle: task['title'],
          existingDescription: task['description'],
          existingDueDate: task['due_date'],
          showTaskDetails: true,
          taskId: taskId,
          showSalesOrderId: false,
        ),
      ),
    );
    _fetchTaskDetails();
  }

  Future<void> _deleteTask(int taskId) async {
    final String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/delete_task.php';

    final Map<String, String> queryParameters = {
      'task_id': taskId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            tasks.removeWhere((task) => task['id'] == taskId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error deleting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task: $e')),
      );
    }
  }

  void _showDeleteConfirmationDialog(int taskId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTask(taskId);
              },
            ),
          ],
        );
      },
    );
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
                      const Text('Creation Date'),
                      if (_sortBy == 'creation_date')
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            _sortOrder == 'ascending'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: const Color(0xFF0175FF),
                          ),
                        ),
                    ],
                  ),
                  tileColor: _sortBy == 'creation_date'
                      ? const Color(0xFFF5F8FF)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _sortBy == 'creation_date'
                        ? const BorderSide(color: Color(0xFF0175FF), width: 1)
                        : BorderSide.none,
                  ),
                  onTap: () {
                    _sortTasks('creation_date');
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
                      const Text('Due Date'),
                      if (_sortBy == 'due_date')
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            _sortOrder == 'ascending'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: const Color(0xFF0175FF),
                          ),
                        ),
                    ],
                  ),
                  tileColor:
                      _sortBy == 'due_date' ? const Color(0xFFF5F8FF) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _sortBy == 'due_date'
                        ? const BorderSide(color: Color(0xFF0175FF), width: 1)
                        : BorderSide.none,
                  ),
                  onTap: () {
                    _sortTasks('due_date');
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
                      const Text('Title (A-Z)'),
                      if (_sortBy == 'title')
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            _sortOrder == 'ascending'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: const Color(0xFF0175FF),
                          ),
                        ),
                    ],
                  ),
                  tileColor:
                      _sortBy == 'title' ? const Color(0xFFF5F8FF) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _sortBy == 'title'
                        ? const BorderSide(color: Color(0xFF0175FF), width: 1)
                        : BorderSide.none,
                  ),
                  onTap: () {
                    _sortTasks('title');
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

  void _sortTasks(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortOrder = _sortOrder == 'ascending' ? 'descending' : 'ascending';
      } else {
        _sortBy = sortBy;
        _sortOrder = 'ascending';
      }

      switch (sortBy) {
        case 'creation_date':
          tasks.sort((a, b) => _sortOrder == 'ascending'
              ? a['creation_date'].compareTo(b['creation_date'])
              : b['creation_date'].compareTo(a['creation_date']));
          break;
        case 'due_date':
          tasks.sort((a, b) => _sortOrder == 'ascending'
              ? a['due_date'].compareTo(b['due_date'])
              : b['due_date'].compareTo(a['due_date']));
          break;
        case 'title':
          tasks.sort((a, b) => _sortOrder == 'ascending'
              ? a['title'].compareTo(b['title'])
              : b['title'].compareTo(a['title']));
          break;
      }
    });
  }

  String _getSortButtonText() {
    switch (_sortBy) {
      case 'creation_date':
        return 'Sort by Creation Date';
      case 'due_date':
        return 'Sort by Due Date';
      case 'title':
        return 'Sort by Title (A-Z)';
      default:
        return 'Sort';
    }
  }

  String _formatCurrency(String amount) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(double.parse(amount));
  }

  @override
  Widget build(BuildContext context) {
    String formattedAmount =
        _formatCurrency(widget.leadItem.amount.substring(2));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerInsightsPage(
              customerName: widget.leadItem.customerName,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
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
                      widget.leadItem.customerName,
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
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(71, 148, 255, 223),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'RM$formattedAmount',
                          style: const TextStyle(
                            color: Color(0xff008A64),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        onSelected: (String value) async {
                          if (value == 'delete') {
                            bool confirmDelete = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                      'Are you sure you want to delete this sales lead?'),
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
                              widget.onDeleteLead(widget.leadItem);
                            }
                          } else if (value == 'complete') {
                            widget.onComplete(widget.leadItem);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'View details',
                            child: const Text('View details'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerInsightsPage(
                                    customerName: widget.leadItem.customerName,
                                  ),
                                ),
                              );
                            },
                          ),
                          const PopupMenuItem<String>(
                            value: 'complete',
                            child: Text('Complete'),
                          ),
                          PopupMenuItem<String>(
                            value: 'undo',
                            child: const Text('Undo'),
                            onTap: () async {
                              if (widget.leadItem.previousStage != null &&
                                  widget.leadItem.previousStage!.isNotEmpty) {
                                try {
                                  await widget.onUndoLead(widget.leadItem,
                                      widget.leadItem.previousStage!);
                                  setState(() {
                                    widget.leadItem.stage =
                                        widget.leadItem.previousStage!;
                                    widget.leadItem.previousStage = null;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Successfully undone Negotiation lead')),
                                  );
                                } catch (e) {
                                  developer.log(
                                      'Error undoing negotiation lead: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error undoing Negotiation lead: $e')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Cannot undo: No previous stage available')),
                                );
                              }
                            },
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        child: const Icon(Icons.more_horiz_outlined,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.leadItem.contactNumber.isNotEmpty
                        ? () =>
                            _launchPhone('tel:${widget.leadItem.contactNumber}')
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xff0175FF),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            widget.leadItem.contactNumber.isNotEmpty
                                ? widget.leadItem.contactNumber
                                : 'Unavailable',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.leadItem.emailAddress.isNotEmpty
                        ? () => _launchEmail(
                            'mailto:${widget.leadItem.emailAddress}')
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email,
                          color: Color(0xff0175FF),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
                          child: Text(
                            widget.leadItem.emailAddress.isNotEmpty
                                ? widget.leadItem.emailAddress
                                : 'Unavailable',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (tasks.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isTasksExpanded = !_isTasksExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F8FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF0175FF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0175FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tasks (${tasks.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (!_isTasksExpanded)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6EFFF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Click to expand',
                                  style: TextStyle(
                                    color: Color(0xFF0175FF),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              _isTasksExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: const Color(0xFF0175FF),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isTasksExpanded) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewTasksPage(
                                      tasks: tasks, leadItem: widget.leadItem),
                                ),
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'View More',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F8FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF0175FF),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: _showSortOptions,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.sort,
                                    color: Color(0xFF0175FF),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getSortButtonText(),
                                    style: const TextStyle(
                                      color: Color(0xFF0175FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 220,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: tasks.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task['title'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF2C3E50),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              task['description'],
                                              style: const TextStyle(
                                                color: Color(0xFF7F8C8D),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F8FF),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    size: 14,
                                                    color: Color(0xFF0175FF),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Due: ${DateFormat('dd/MM/yyyy').format(task['due_date'])}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF0175FF),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Color(0xFF0175FF),
                                            ),
                                            onPressed: () =>
                                                _navigateToEditTaskPage(
                                                    context, task),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Color(0xFFFF4444),
                                            ),
                                            onPressed: () =>
                                                _showDeleteConfirmationDialog(
                                                    task['id']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              else
                const Text(
                  'You haven\'t created any tasks yet! Click the Create Task button to create one.',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Created on: ${widget.leadItem.createdDate}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down),
                          iconDisabledColor: Colors.white,
                          iconEnabledColor: Colors.white),
                      isExpanded: true,
                      hint: const Text(
                        'Negotiation',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      items: ['Negotiation', 'Order Processing', 'Closed']
                          .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ))
                          .toList(),
                      value: widget.leadItem.selectedValue,
                      onChanged: (value) {
                        if (value == 'Closed') {
                          widget.onComplete(widget.leadItem);
                        } else if (value == 'Order Processing') {
                          _navigateToCreateTaskPage(context, false);
                        }
                      },
                      buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          height: 24,
                          width: 130,
                          decoration: BoxDecoration(color: Color(0xff0175FF))),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 30,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 14,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () =>
                            _navigateToCreateTaskPage(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 62, 147, 252),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                        ),
                        child: const Text(
                          'Create Task / Select Order ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
