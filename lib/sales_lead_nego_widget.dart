import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sales_navigator/create_task_page.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/customer_insight.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'dart:developer' as developer;

import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _fetchTaskDetails() async {
    MySqlConnection conn = await connectToDatabase();
    try {
      Results results = await conn.query(
        // 'SELECT t.id, t.title, t.description, t.due_date FROM tasks t JOIN sales_lead sl ON t.lead_id = sl.id WHERE sl.customer_name = ?',
        'SELECT t.id, t.title, t.description, t.due_date FROM tasks t JOIN sales_lead sl ON t.lead_id = sl.id WHERE sl.id = ?',
        [widget.leadItem.id],
      );
      if (results.isNotEmpty && mounted) {
        setState(() {
          tasks = results.map((row) {
            return {
              'title': row['title'],
              'description': row['description'],
              'due_date': row['due_date'],
              'id': row['id'], // add tasks ID
            };
          }).toList();
        });
      }
    } catch (e) {
      developer.log('Error fetching task details: $e');
    } finally {
      await conn.close();
    }
  }

  // Future<void> _fetchTaskDetails() async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     Results results = await conn.query(
  //       'SELECT task_title, task_description, task_duedate FROM sales_lead WHERE id = ?',
  //       [widget.leadItem.id],
  //     );
  //     if (results.isNotEmpty && mounted) {
  //       var row = results.first;
  //       setState(() {
  //         title = row['task_title'];
  //         description = row['task_description'];
  //         dueDate = row['task_duedate'];
  //       });
  //     }
  //   } catch (e) {
  //     developer.log('Error fetching task details: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

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
        _fetchTaskDetails(); // 只有在有任务详情时才刷新任务列表
      }

      // 检查是否需要移动到 Order Processing
      if (result['salesOrderId'] != null) {
        String salesOrderId = result['salesOrderId'] as String;
        int? quantity = result['quantity'];
        await widget.onMoveToOrderProcessing(
            widget.leadItem, salesOrderId, quantity);
        Navigator.pop(context);
      }
    }
    // if (result != null && result['error'] == null) {
    //   setState(() {
    //     title = result['title'] as String?;
    //     description = result['description'] as String?;
    //     dueDate = result['dueDate'] as DateTime?;
    //   });
    //   // Move NegotiationLeadItem to OrderProcessingLeadItem if the user selects the sales order ID
    //   if (result['salesOrderId'] != null) {
    //     String salesOrderId = result['salesOrderId'] as String;
    //     int? quantity = result['quantity'];
    //     await widget.onMoveToOrderProcessing(
    //         widget.leadItem, salesOrderId, quantity);
    //     Navigator.pop(context);
    //   }
    // }
    // _fetchTaskDetails();
  }

  Future<void> _navigateToEditTaskPage(
      BuildContext context, Map<String, dynamic> task) async {
    final taskId = task['id']; // fetch taskId
    print('taskId: $taskId');

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
          taskId: taskId, // 将任务ID传递给CreateTaskPage
          showSalesOrderId: false, // 设置为 false，不显示 sales order ID 部分
        ),
      ),
    );
    _fetchTaskDetails();
    // if (result != null && result['error'] == null) {
    //   _fetchTaskDetails(); // 刷新任务列表
    //   // Move NegotiationLeadItem to OrderProcessingLeadItem if the user selects the sales order ID
    //   if (result['salesOrderId'] != null) {
    //     String salesOrderId = result['salesOrderId'] as String;
    //     int? quantity = result['quantity'];
    //     await widget.onMoveToOrderProcessing(
    //         widget.leadItem, salesOrderId, quantity);
    //     Navigator.pop(context);
    //   }
    // }
  }

  Future<void> _deleteTask(int taskId) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      await conn.query('DELETE FROM tasks WHERE id = ?', [taskId]);
      setState(() {
        tasks.removeWhere((task) => task['id'] == taskId);
      });
    } catch (e) {
      developer.log('Error deleting task: $e');
    } finally {
      await conn.close();
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
            builder: (context) => CustomerInsightPage(
              customerName: widget.leadItem.customerName,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text(
                  //   widget.leadItem.customerName.length > 15
                  //       ? '${widget.leadItem.customerName.substring(0, 15)}...'
                  //       : widget.leadItem.customerName,
                  //   style: const TextStyle(
                  //     fontWeight: FontWeight.bold,
                  //     fontSize: 20,
                  //   ),
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  Container(
                    width: 170,
                    child: Text(
                      widget.leadItem.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 3,
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
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'RM$formattedAmount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
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
                              MySqlConnection conn = await connectToDatabase();
                              try {
                                await conn.query(
                                  'DELETE FROM sales_lead WHERE id = ?',
                                  [widget.leadItem.id],
                                );
                                widget.onDeleteLead(widget.leadItem);
                              } catch (e) {
                                developer.log('Error deleting lead item: $e');
                              } finally {
                                await conn.close();
                              }
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
                                  builder: (context) => CustomerInsightPage(
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
                              MySqlConnection conn = await connectToDatabase();
                              try {
                                Results results = await conn.query(
                                  'SELECT previous_stage FROM sales_lead WHERE id = ?',
                                  [widget.leadItem.id],
                                );
                                if (results.isNotEmpty) {
                                  String? previousStage =
                                      results.first['previous_stage'];
                                  if (previousStage != null &&
                                      previousStage.isNotEmpty) {
                                    widget.onUndoLead(
                                        widget.leadItem, previousStage);
                                    widget.leadItem.stage = previousStage;
                                    await conn.query(
                                      'UPDATE sales_lead SET previous_stage = NULL WHERE id = ?',
                                      [widget.leadItem.id],
                                    );
                                  }
                                }
                              } catch (e) {
                                developer
                                    .log('Error checking previous stage: $e');
                              } finally {
                                await conn.close();
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.leadItem.contactNumber.isNotEmpty
                        ? () =>
                            _launchURL('tel:${widget.leadItem.contactNumber}')
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xff0069BA),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.leadItem.contactNumber.isNotEmpty
                              ? widget.leadItem.contactNumber
                              : 'Unavailable',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.leadItem.emailAddress.isNotEmpty
                        ? () =>
                            _launchURL('mailto:${widget.leadItem.emailAddress}')
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email,
                          color: Color(0xff0069BA),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.leadItem.emailAddress.isNotEmpty
                              ? widget.leadItem.emailAddress
                              : 'Unavailable',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Replace the existing task details section with a ListView
              if (tasks.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Tasks',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      // Column(
                                      //   children: [
                                      //     IconButton(
                                      //       icon: const Icon(Icons.edit),
                                      //       onPressed: () =>
                                      //           _navigateToEditTaskPage(
                                      //               context, task),
                                      //     ),
                                      //     IconButton(
                                      //       icon: const Icon(Icons.delete,
                                      //           color: Colors.red),
                                      //       onPressed: () =>
                                      //           _showDeleteConfirmationDialog(
                                      //               task['id']),
                                      //     ),
                                      //   ],
                                      // ),
                                      const SizedBox(height: 8),
                                      Text(task['description']),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Due Date: ${DateFormat('dd/MM/yyyy').format(task['due_date'])}'),
                                    ],
                                  ),
                                  Spacer(),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _navigateToEditTaskPage(
                                                context, task),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _showDeleteConfirmationDialog(
                                                task['id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
              // if (title != null && description != null && dueDate != null)
              //   Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       const SizedBox(height: 8),
              //       Row(
              //         children: [
              //           const Icon(Icons.date_range, color: Color(0xff0069BA)),
              //           Text(
              //               'Due Date: ${DateFormat('dd/MM/yyyy').format(dueDate!)}'),
              //         ],
              //       ),
              //       const SizedBox(height: 16),
              //       Row(
              //         children: [
              //           Text(
              //             '${title?.toUpperCase()}',
              //             style: const TextStyle(
              //                 fontWeight: FontWeight.bold, fontSize: 16),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 4),
              //       Text(
              //         '$description',
              //         style: const TextStyle(fontSize: 14),
              //       ),
              //       const SizedBox(height: 16),
              //     ],
              //   )
              // else
              //   const Text(
              //     'You haven\'t created a task yet! Click the Create Task button to create it.',
              //     style: TextStyle(
              //       color: Colors.black,
              //       fontSize: 14,
              //     ),
              //   ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true,
                      hint: const Text(
                        'Negotiation',
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
                      value: 'Negotiation',
                      onChanged: (value) {
                        if (value == 'Closed') {
                          widget.onComplete(widget.leadItem);
                        } else if (value == 'Order Processing') {
                          _navigateToCreateTaskPage(context, false);
                        }
                      },
                      buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          height: 32,
                          width: 130,
                          decoration: BoxDecoration(color: Colors.white)),
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
                  TextButton(
                    onPressed: () => _navigateToCreateTaskPage(context, true),
                    child: Container(
                      width: 100,
                      child: Text(
                        'Create Task / Select Order ID',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xff0069BA),
                          color: Color(0xff0069BA),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    //   Container(
                    //   width: 170,
                    //   child: Text(
                    //     widget.leadItem.customerName,
                    //     style: const TextStyle(
                    //         fontWeight: FontWeight.bold, fontSize: 18),
                    //     maxLines: 3,
                    //     overflow: TextOverflow.ellipsis,
                    //   ),
                    // ),
                  ),
                  Text(
                    'Created on: ${widget.leadItem.createdDate}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
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
}
