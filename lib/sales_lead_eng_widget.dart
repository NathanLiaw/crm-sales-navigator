import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/create_task_page.dart';
import 'package:sales_navigator/customer_insight.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/home_page.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';

class EngagementLeadItem extends StatelessWidget {
  final LeadItem leadItem;
  final VoidCallback onMoveToNegotiation;
  final Function(LeadItem) onDeleteLead;
  final Function(LeadItem, String) onUndoLead;
  final Function(LeadItem) onComplete;
  final Function(LeadItem, String, int?) onMoveToOrderProcessing;

  const EngagementLeadItem({
    super.key,
    required this.leadItem,
    required this.onMoveToNegotiation,
    required this.onDeleteLead,
    required this.onUndoLead,
    required this.onComplete,
    required this.onMoveToOrderProcessing,
  });

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String _formatCurrency(String amount) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(double.parse(amount));
  }

  @override
  Widget build(BuildContext context) {
    String formattedAmount = _formatCurrency(leadItem.amount.substring(2));

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
                  // Text(
                  //   leadItem.customerName.length > 10
                  //       ? '${leadItem.customerName.substring(0, 15)}...'
                  //       : leadItem.customerName,
                  //   style: const TextStyle(
                  //     fontWeight: FontWeight.bold,
                  //     fontSize: 20,
                  //   ),
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  Container(
                    width: 200,
                    child: Text(
                      leadItem.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  const Spacer(),
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
                      PopupMenuItem<String>(
                        value: 'view details',
                        child: const Text('View details'),
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: leadItem.contactNumber.isNotEmpty
                        ? () => _launchURL('tel:${leadItem.contactNumber}')
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xff0069BA),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          leadItem.contactNumber.isNotEmpty
                              ? leadItem.contactNumber
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
                    onTap: leadItem.emailAddress.isNotEmpty
                        ? () => _launchURL('mailto:${leadItem.emailAddress}')
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email,
                          color: Color(0xff0069BA),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          leadItem.emailAddress.isNotEmpty
                              ? leadItem.emailAddress
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
              const SizedBox(height: 16),
              Text(
                leadItem.description,
                style: const TextStyle(
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
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true,
                      hint: const Text('Engagement'),
                      items: tabbarNames
                          .skip(1)
                          .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: const TextStyle(fontSize: 12),
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
                          _navigateToCreateTaskPage(context, false);
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
      ),
    );
  }

  Future<void> _navigateToCreateTaskPage(
      BuildContext context, bool showTaskDetails) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
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
      // Move EngagementLeadItem to OrderProcessingLeadItem if the user selects the sales order ID
      if (result['salesOrderId'] != null) {
        String salesOrderId = result['salesOrderId'] as String;
        int? quantity = result['quantity'];
        await onMoveToOrderProcessing(leadItem, salesOrderId, quantity);
      }
    }
  }
}
