import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/home_page.dart';

class EngagementLeadItem extends StatelessWidget {
  final LeadItem leadItem;

  const EngagementLeadItem({Key? key, required this.leadItem})
      : super(key: key);

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
                  leadItem.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                  leadItem.createdDate,
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
                        .skip(1) // 跳过第一个选项 'Opportunities'
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    value: 'Engagement',
                    onChanged: (value) =>
                        _handleDropdownChange(value, leadItem),
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

  void _handleDropdownChange(String? value, LeadItem leadItem) async {
    if (value == 'Negotiation') {
      // 执行将 leadItem 移动到 Negotiation 标签页的操作
      await _updateLeadStage(leadItem, 'Negotiation');
    } else if (value == 'Order Processing') {
      // 执行将 leadItem 移动到 Order Processing 标签页的操作
      await _updateLeadStage(leadItem, 'Order Processing');
    } else if (value == 'Closed') {
      // 执行将 leadItem 移动到 Closed 标签页的操作
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
      print('Error updating stage: $e');
    } finally {
      await conn.close();
    }
  }
}
