import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/db_connection.dart';

class OrderDetailsPage extends StatefulWidget {
  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late String companyName;
  late String address;
  late String salesmanName;
  late String salesOrderId;
  late String createdDate;
  late List<OrderItem> orderItems = [];
  double subtotal = 0.0;
  bool isVoidButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    final conn = await connectToDatabase();

    try {
      // Fetch cartId
      final results = await readData(
        conn,
        'cart c JOIN cart_item ci ON ci.session = c.session',
        'ci.buyer_id = 3 AND c.buyer_user_group = "salesman"',
        '',
        'c.id AS cartId',
      );

      // Preset cartId as 107
      final cartId = 100;

      // Fetch customer_id using cartId
      final customerResults = await readData(
        conn,
        'cart',
        'id = $cartId',
        '',
        'customer_id',
      );

      // Fetch companyName and address using customer_id
      final customerID = customerResults.first['customer_id'] as int;
      final customerDetails = await readData(
        conn,
        'customer',
        'id = $customerID',
        '',
        'company_name, address_line_1',
      );

      // Fetch salesmanName using cartId
      final salesmanResults = await readData(
        conn,
        'cart',
        'id = $cartId',
        '',
        'buyer_name',
      );

      // Fetch createdDate using cartId
      final createdDateResults = await readData(
        conn,
        'cart',
        'id = $cartId',
        '',
        'created',
      );

      // Fetch session using cartId
      final sessionResults = await readData(
        conn,
        'cart',
        'id = $cartId',
        '',
        'session',
      );

      // Fetch cart_item data using session
      final session = sessionResults.first['session'] as String;
      final cartItemResults = await readData(
        conn,
        'cart_item',
        'session = "$session"',
        '',
        'product_name, unit_price, qty, total, status',
      );

      final createdDateTime =
          DateTime.parse(createdDateResults.first['created'] as String);
      final formattedCreatedDate =
          DateFormat('yyyy-MM-dd').format(createdDateTime);

      // Format salesOrderId
      final formattedSalesOrderId = 'SO' + cartId.toString().padLeft(7, '0');

      // Format order items
      final items = <OrderItem>[];
      double total = 0.0;
      for (var result in cartItemResults) {
        final productName = result['product_name'] as String;
        final unitPrice = result['unit_price'].toString();
        final qty = result['qty'].toString();
        final status = result['status'] as String;
        final itemTotal = result['total'].toString();
        final photoPath = await fetchProductPhoto(productName);
        items.add(OrderItem(
          productName: productName,
          unitPrice: unitPrice,
          qty: qty,
          status: status,
          total: itemTotal,
          photoPath: photoPath,
        ));
        total += double.parse(itemTotal);
      }

      setState(() {
        companyName = customerDetails.first['company_name'] as String;
        address = customerDetails.first['address_line_1'] as String;
        salesmanName = salesmanResults.first['buyer_name'] as String;
        salesOrderId = formattedSalesOrderId;
        createdDate = formattedCreatedDate;
        orderItems = items;
        subtotal = total;
      });
    } catch (e) {
      print('Failed to fetch order details: $e');
    } finally {
      await conn.close();
    }
  }

  Future<String> fetchProductPhoto(String productName) async {
    try {
      final conn = await connectToDatabase();
      final results = await readData(
        conn,
        'product',
        'product_name = "$productName"',
        '',
        'photo1',
      );
      await conn.close();
      if (results.isNotEmpty && results[0]['photo1'] != null) {
        String photoPath = results[0]['photo1'];
        if (photoPath.startsWith('photo/')) {
          photoPath = 'asset/photo/' + photoPath.substring(6);
        }
        return photoPath;
      } else {
        return 'asset/no_photo_available.jpg';
      }
    } catch (e) {
      print('Error fetching product photo: $e');
      return 'asset/no_photo_available.jpg';
    }
  }

  Future<void> voidOrder() async {
    final conn = await connectToDatabase();
    final success = await saveData(conn, 'cart', {
      'status': 'Void',
      'id': 100,
    });
    await conn.close();
    if (success) {
      setState(() {
        // 更新状态为 "Void" 成功后，将按钮禁用并更改颜色
        isVoidButtonDisabled = true;
      });
    }
  }

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
                Expanded(
                  flex: 2,
                  child: Text(
                    'To: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: '$companyName, ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        TextSpan(
                          text: '$address',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'From: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                    flex: 5,
                    child: Text('Fong Yuan Hung Import & Export Sdn Bhd.')),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Salesman: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(flex: 5, child: Text('$salesmanName')),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Order ID: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(flex: 5, child: Text('$salesOrderId')),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Created Date: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(flex: 5, child: Text('$createdDate')),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text('Subtotal (${orderItems.length} items)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('RM$subtotal',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildOrderItem(OrderItem item) {
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

class OrderItem {
  final String productName;
  final String unitPrice;
  final String qty;
  final String status;
  final String total;
  final String photoPath;

  OrderItem({
    required this.productName,
    required this.unitPrice,
    required this.qty,
    required this.status,
    required this.total,
    required this.photoPath,
  });
}
