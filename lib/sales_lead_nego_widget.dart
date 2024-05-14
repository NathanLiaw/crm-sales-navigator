import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sales_navigator/create_task_page.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';

class NegotiationLeadItem extends StatefulWidget {
  final LeadItem leadItem;
  const NegotiationLeadItem({super.key, required this.leadItem});

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
        'SELECT task_title, task_description, task_duedate FROM create_lead WHERE customer_name = ?',
        [widget.leadItem.customerName],
      );
      if (results.isNotEmpty) {
        var row = results.first;
        setState(() {
          title = row['task_title'];
          description = row['task_description'];
          dueDate = row['task_duedate'];
        });
      }
    } catch (e) {
      print('Error fetching task details: $e');
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
        ),
      ),
    );

    if (result != null) {
      setState(() {
        title = result['title'];
        description = result['description'];
        dueDate = result['dueDate'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Text(
                  widget.leadItem.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.leadItem.amount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    // Perform an action based on the selected value
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'view details',
                      child: Text('View details'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'archive',
                      child: Text('Archive'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'complete',
                      child: Text('Complete'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'undo',
                      child: Text('Undo'),
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
                  style: const TextStyle(
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
                  style: const TextStyle(
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
                  // Text(
                  //   'Task Details',
                  //   style: TextStyle(
                  //     fontWeight: FontWeight.bold,
                  //     fontSize: 16,
                  //   ),
                  // ),
                  // SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.date_range, color: Color(0xff0069BA)),
                      Text(
                          'Due Date: ${DateFormat('dd/MM/yyyy').format(dueDate!)}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Icon(Icons.task, color: Color(0xff0069BA)),
                      Text(
                        '${title?.toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$description',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
              )
            else
              const Text(
                'You haven\'t created a task yet! Click the Create Task button to create it.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            // const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: const Text(
                      'Negotiation',
                    ),
                    items: ['Negotiation']
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    value: 'Negotiation',
                    onChanged: (value) {},
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
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xff0069BA),
                      color: Color(0xff0069BA),
                      fontSize: 14,
                    ),
                  ),
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
    );
  }
}
