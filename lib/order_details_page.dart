import 'package:flutter/material.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0069BA),
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'To:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Flexible(
                  child: Wrap(
                    children: [
                      Text(
                        'Resource Factory Sdn Bhd. 082-101-101, Lot 1661, Section 63, KTLD., Jalan Datuk Abang Abdul Rahim, Lorong 5/9, 3540 Kuching, Sarawak, Malaysia',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text(
                  'From:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Fong Yuan Hung Import & Export Sdn Bhd.'),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text(
                  'Salesman:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Norman Lu'),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text(
                  'Order ID:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('SO0234678'),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text(
                  'Created Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('sample date'),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text(
                  'Expiry Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('sample date'),
              ],
            ),
            const SizedBox(height: 16),
            _buildOrderItem(
              itemName: '2M Hose Reel & Cart',
              itemModel: 'SX-901-18',
              unitPrice: 'RM 150.40',
              quantity: 'Qty: 3',
              status: 'None',
              totalPrice: 'RM 450.00',
            ),
            _buildOrderItem(
              itemName: '2M Hose Reel & Cart',
              itemModel: 'SX-901-18',
              unitPrice: 'RM 100.00',
              quantity: 'Qty: 3',
              status: 'No Stock',
              totalPrice: 'RM 300.00',
            ),
            const SizedBox(height: 16),
            const Text('Subtotal (6 items) RM700.00'),
            const Text('Total RM700.00'),
            const SizedBox(height: 16),
            const Text(
              '*This is not an invoice & prices are not finalised',
              style: TextStyle(color: Colors.grey),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle "Void" button click
              },
              child: const Text('Void', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem({
    required String itemName,
    required String itemModel,
    required String unitPrice,
    required String quantity,
    required String status,
    required String totalPrice,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(itemName),
        Text(itemModel),
        Text('Unit Price: $unitPrice $quantity'),
        Text('Status: $status Total: $totalPrice'),
        const Divider(),
      ],
    );
  }
}
