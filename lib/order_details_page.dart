import 'package:flutter/material.dart';

class OrderDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0069BA),
        title: Text(
          'Order Details',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
            Row(
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
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'From:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Fong Yuan Hung Import & Export Sdn Bhd.'),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Salesman:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Norman Lu'),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Order ID:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('SO0234678'),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Created Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('sample date'),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Expiry Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('sample date'),
              ],
            ),
            SizedBox(height: 16),
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
            SizedBox(height: 16),
            Text('Subtotal (6 items) RM700.00'),
            Text('Total RM700.00'),
            SizedBox(height: 16),
            Text(
              '*This is not an invoice & prices are not finalised',
              style: TextStyle(color: Colors.grey),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle "Void" button click
              },
              child: Text('Void', style: TextStyle(color: Colors.white)),
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
        Divider(),
      ],
    );
  }
}
