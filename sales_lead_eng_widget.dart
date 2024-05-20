import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/create_task_page.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/home_page.dart';
import 'dart:developer' as developer;

class EngagementLeadItem extends StatelessWidget {
  final LeadItem leadItem;
  final VoidCallback onMoveToNegotiation;
  final Function(LeadItem) onDeleteLead;
  final Function(LeadItem, String) onUndoLead;
  final Function(LeadItem) onComplete;
  final Function(LeadItem, String, String?) onMoveToOrderProcessing;

  const EngagementLeadItem({
    Key? key,
    required this.leadItem,
    required this.onMoveToNegotiation,
    required this.onDeleteLead,
    required this.onUndoLead,
    required this.onComplete,
    required this.onMoveToOrderProcessing,
  }) : super(key: key);

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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  leadItem.customerName.length > 10
                      ? leadItem.customerName.substring(0, 15) + '...'
                      : leadItem.customerName,
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
                    leadItem.amount,
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
                            [leadItem.customerName],
                          );
                          onDeleteLead(leadItem);
                        } catch (e) {
                          developer.log('Error deleting lead item: $e');
                        } finally {
                          await conn.close();
                        }
                      }
                    }
                    if (value == 'complete') {
                      onComplete(leadItem);
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
                            [leadItem.customerName],
                          );
                          if (results.isNotEmpty) {
                            String? previousStage =
                                results.first['previous_stage'];
                            if (previousStage != null &&
                                previousStage.isNotEmpty) {
                              onUndoLead(leadItem, previousStage);
                              leadItem.stage = previousStage;
                              await conn.query(
                                'UPDATE sales_lead SET previous_stage = NULL WHERE customer_name = ?',
                                [leadItem.customerName],
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
                  leadItem.contactNumber,
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
                  leadItem.emailAddress,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              leadItem.description,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created on: ${leadItem.createdDate}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: Text('Engagement'),
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
                    value: 'Engagement',
                    onChanged: (value) {
                      if (value == 'Negotiation') {
                        onMoveToNegotiation();
                      } else if (value == 'Closed') {
                        onComplete(leadItem);
                      } else if (value == 'Order Processing') {
                        _navigateToCreateTaskPage(context);
                      }
                    },
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 32,
                      width: 130,
                      decoration: BoxDecoration(color: Colors.white),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 30,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCreateTaskPage(BuildContext context) async {
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
      // Move EngagementLeadItem to OrderProcessingLeadItem if the user selects the sales order ID
      if (result['salesOrderId'] != null) {
        String salesOrderId = result['salesOrderId'] as String;
        String? quantity = result['quantity'] as String?;
        await onMoveToOrderProcessing(leadItem, salesOrderId, quantity);
      }
    }
  }

  void _handleDropdownChange(String? value, LeadItem leadItem) async {
    if (value == 'Negotiation') {
      await _updateLeadStage(leadItem, 'Negotiation');
    } else if (value == 'Order Processing') {
      await _updateLeadStage(leadItem, 'Order Processing');
    } else if (value == 'Closed') {
      await _updateLeadStage(leadItem, 'Closed');
    }
  }

  Future<void> _updateLeadStage(LeadItem leadItem, String stage) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      await conn.query(
        'UPDATE sales_lead SET stage = ? WHERE customer_name = ?',
        [stage, leadItem.customerName],
      );
    } catch (e) {
      developer.log('Error updating stage: $e');
    } finally {
      await conn.close();
    }
  }
}
