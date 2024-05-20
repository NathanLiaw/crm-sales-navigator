import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sales_navigator/create_task_page.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'dart:developer' as developer;

class NegotiationLeadItem extends StatefulWidget {
  final LeadItem leadItem;
  final Function(LeadItem) onDeleteLead;
  final Function(LeadItem, String) onUndoLead;
  final Function(LeadItem) onComplete;
  final Function(LeadItem, String, String?) onMoveToOrderProcessing;

  const NegotiationLeadItem({
    Key? key,
    required this.leadItem,
    required this.onDeleteLead,
    required this.onUndoLead,
    required this.onComplete,
    required this.onMoveToOrderProcessing,
  }) : super(key: key);

  @override
  _NegotiationLeadItemState createState() => _NegotiationLeadItemState();
}

class _NegotiationLeadItemState extends State<NegotiationLeadItem> {
  String? title;
  String? description;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    MySqlConnection conn = await connectToDatabase();
    try {
      Results results = await conn.query(
        'SELECT task_title, task_description, task_duedate FROM sales_lead WHERE customer_name = ?',
        [widget.leadItem.customerName],
      );
      if (results.isNotEmpty && mounted) {
        var row = results.first;
        setState(() {
          title = row['task_title'];
          description = row['task_description'];
          dueDate = row['task_duedate'];
        });
      }
    } catch (e) {
      developer.log('Error fetching task details: $e');
    } finally {
      await conn.close();
    }
  }

  Future<void> _navigateToCreateTaskPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          customerName: widget.leadItem.customerName,
          contactNumber: widget.leadItem.contactNumber,
          emailAddress: widget.leadItem.emailAddress,
          address: widget.leadItem.addressLine1,
          lastPurchasedAmount: widget.leadItem.amount,
          existingTitle: title,
          existingDescription: description,
          existingDueDate: dueDate,
        ),
      ),
    );

    if (result != null && result['error'] == null) {
      setState(() {
        title = result['title'] as String?;
        description = result['description'] as String?;
        dueDate = result['dueDate'] as DateTime?;
      });
      // Move NegotiationLeadItem to OrderProcessingLeadItem if the user selects the sales order ID
      if (result['salesOrderId'] != null) {
        String salesOrderId = result['salesOrderId'] as String;
        String? quantity = result['quantity'] as String?;
        await widget.onMoveToOrderProcessing(
            widget.leadItem, salesOrderId, quantity);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.leadItem.customerName.length > 15
                      ? widget.leadItem.customerName.substring(0, 15) + '...'
                      : widget.leadItem.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
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
                    widget.leadItem.amount,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Spacer(),
                PopupMenuButton<String>(
                  onSelected: (String value) async {
                    if (value == 'delete') {
                      bool confirmDelete = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Confirm Delete'),
                            content: Text(
                                'Are you sure you want to delete this sales lead?'),
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
                            [widget.leadItem.customerName],
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
                    const PopupMenuItem<String>(
                      value: 'view details',
                      child: Text('View details'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'complete',
                      child: Text('Complete'),
                    ),
                    PopupMenuItem<String>(
                      value: 'undo',
                      child: Text('Undo'),
                      onTap: () async {
                        MySqlConnection conn = await connectToDatabase();
                        try {
                          Results results = await conn.query(
                            'SELECT previous_stage FROM sales_lead WHERE customer_name = ?',
                            [widget.leadItem.customerName],
                          );
                          if (results.isNotEmpty) {
                            String? previousStage =
                                results.first['previous_stage'];
                            if (previousStage != null &&
                                previousStage.isNotEmpty) {
                              widget.onUndoLead(widget.leadItem, previousStage);
                              widget.leadItem.stage = previousStage;
                              await conn.query(
                                'UPDATE sales_lead SET previous_stage = NULL WHERE customer_name = ?',
                                [widget.leadItem.customerName],
                              );
                            }
                          }
                        } catch (e) {
                          developer.log('Error checking previous stage: $e');
                        } finally {
                          await conn.close();
                        }
                      },
                    ),
                  ],
                  child: const Icon(Icons.more_horiz_outlined,
                      color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.phone,
                  color: Color(0xff0069BA),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.leadItem.contactNumber,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.email,
                  color: Color(0xff0069BA),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.leadItem.emailAddress,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (title != null && description != null && dueDate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.date_range, color: Color(0xff0069BA)),
                      Text(
                          'Due Date: ${DateFormat('dd/MM/yyyy').format(dueDate!)}'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${title?.toUpperCase()}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$description',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                ],
              )
            else
              Text(
                'You haven\'t created a task yet! Click the Create Task button to create it.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: Text(
                      'Negotiation',
                    ),
                    items: ['Negotiation', 'Order Processing', 'Closed']
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    value: 'Negotiation',
                    onChanged: (value) {
                      if (value == 'Closed') {
                        widget.onComplete(widget.leadItem);
                      } else if (value == 'Order Processing') {
                        _navigateToCreateTaskPage(context);
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
                  onPressed: () => _navigateToCreateTaskPage(context),
                  child: Text(
                    title == null ? 'Create Task' : 'Edit Task',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xff0069BA),
                      color: Color(0xff0069BA),
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  'Created on: ${widget.leadItem.createdDate}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
