import 'package:flutter/material.dart';

class ClosedLeadItem extends StatelessWidget {
  // final String status;

  const ClosedLeadItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 193, 255, 203),
      elevation: 2,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Customer A',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xff0069BA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Closed',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.phone,
                  color: Color(0xff0069BA),
                ),
                SizedBox(width: 8),
                Text(
                  '(60)10 23456789',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.email,
                  color: Color(0xff0069BA),
                ),
                SizedBox(width: 8),
                Text(
                  'abc@gmail.com',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'SO0000107',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text('Created date: 29/04/2024'),
            const Text('Expiry date: 29/06/2024'),
            const SizedBox(height: 8),
            const Text(
              'Quantity: 6 items      Total: RM4000',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created on: 04/03/2024',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                // DropdownButtonHideUnderline(
                //   child: DropdownButton2<String>(
                //     isExpanded: true,
                //     hint: Text(
                //       'Order Processing',
                //     ),
                //     items: ['Order Processing']
                //         .map((item) => DropdownMenuItem<String>(
                //               value: item,
                //               child: Text(
                //                 item,
                //                 style: TextStyle(fontSize: 12),
                //               ),
                //             ))
                //         .toList(),
                //     value: 'Order Processing',
                //     onChanged: (value) {},
                //     buttonStyleData: const ButtonStyleData(
                //         padding: EdgeInsets.symmetric(horizontal: 16),
                //         height: 32,
                //         width: 160,
                //         decoration: BoxDecoration(color: Colors.white)),
                //     menuItemStyleData: const MenuItemStyleData(
                //       height: 30,
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
