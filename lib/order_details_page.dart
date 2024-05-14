import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/utility_function.dart';
import 'dart:developer' as developer;

class OrderDetailsPage extends StatefulWidget {
  final int cartID;

  const OrderDetailsPage({super.key, required this.cartID});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Future<void> _orderDetailsFuture;
  late String companyName = '';
  late String address = '';
  late String salesmanName = '';
  late String salesOrderId = '';
  late String createdDate = '';
  late List<OrderItem> orderItems = [];
  double subtotal = 0.0;
  double total = 0.0;
  bool isVoidButtonDisabled = false;

  // Tax Section
  double gst = 0;
  double sst = 0;

  @override
  void initState() {
    super.initState();
    _orderDetailsFuture = fetchOrderDetails();
    getTax();
  }

  Future<void> fetchOrderDetails() async {
    final conn = await connectToDatabase();

    try {
      final cartId = widget.cartID;

      final customerResults = await readData(
        conn,
        'cart',
        'id = $cartId',
        '',
        'customer_id',
      );

      final customerID = customerResults.first['customer_id'] as int;
      final customerDetails = await readData(
        conn,
        'customer',
        'id = $customerID',
        '',
        'company_name, address_line_1',
      );

      final salesmanResults = await readData(
        conn,
        'cart',
        'id = $cartId',
        '',
        'buyer_name',
      );

      final createdDateResults = await readData(
        conn,
        'cart',
        'id = $cartId',
        '',
        'created',
      );

      final sessionResults = await readData(
        conn,
        'cart',
        'id = $cartId',
        '',
        'session',
      );

      String session = '';
      if (sessionResults.isNotEmpty) {
        // Check if sessionResults is not empty
        session = sessionResults.first['session'].toString();
      }

      final cartItemResults = await readData(
        conn,
        'cart_item',
        'session = "$session" OR cart_id = "$cartId"',
        '',
        'product_name, unit_price, qty, total, status',
      );

      final createdDateTime = DateTime.parse(createdDateResults.first['created'] as String);
      final formattedCreatedDate = DateFormat('yyyy-MM-dd').format(createdDateTime);

      final formattedSalesOrderId = 'SO${cartId.toString().padLeft(7, '0')}';

      final items = <OrderItem>[];
      double total = 0.0;
      for (var result in cartItemResults) {
        final productName = result['product_name'] as String?;
        final unitPrice = result['unit_price']?.toString() ?? '0.00';
        final qty = result['qty']?.toString() ?? '0';
        final status = result['status'] as String?;
        final itemTotal = result['total']?.toString() ?? '0.00';

        // Fetch photo path asynchronously
        String photoPath = 'asset/no_image.jpg';
        if (productName != null) {
          photoPath = await fetchProductPhoto(productName);
        }

        // Create OrderItem only if required fields are not null
        if (productName != null && status != null) {
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
      }

      setState(() {
        companyName = customerDetails.first['company_name'] as String;
        address = customerDetails.first['address_line_1'] as String;
        salesmanName = salesmanResults.first['buyer_name'] as String;
        salesOrderId = formattedSalesOrderId;
        createdDate = formattedCreatedDate;
        orderItems = items;
        subtotal = total;
        calculateTotalAndSubTotal();
      });
    } catch (e) {
      developer.log('Failed to fetch order details: $e', error: e);
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
          photoPath = 'asset/photo/${photoPath.substring(6)}';
        }
        return photoPath;
      } else {
        return 'asset/no_image.jpg';
      }
    } catch (e) {
      developer.log('Error fetching product photo: $e', error: e);
      return 'asset/no_image.jpg';
    }
  }

  Future<void> voidOrder() async {
    final conn = await connectToDatabase();
    final success = await saveData(conn, 'cart', {
      'status': 'Void',
      'id': widget.cartID,
    });
    await conn.close();
    if (success) {
      setState(() {
        isVoidButtonDisabled = true;
      });
    }
  }

  Future<void> calculateTotalAndSubTotal() async {
    // Calculate final total using fetched tax values
    double finalTotal = subtotal * (1 + gst + sst);

    // Update state with calculated values
    setState(() {
      total = finalTotal;
    });
  }

  Future<void> getTax() async {
    gst = await UtilityFunction.retrieveTax('GST');
    sst = await UtilityFunction.retrieveTax('SST');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
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
        child: FutureBuilder<void>(
          future: _orderDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return const Center(
                child: Text('Failed to fetch order details'),
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text: address,
                                style: const TextStyle(color: Colors.black),
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
                          child:
                          Text('Fong Yuan Hung Import & Export Sdn Bhd.')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Salesman: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(flex: 5, child: Text(salesmanName)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Order ID: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(flex: 5, child: Text(salesOrderId)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Created Date: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(flex: 5, child: Text(createdDate)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      thickness: 3,
                      child: ListView.builder(
                        itemCount: orderItems.length,
                        itemBuilder: (context, index) {
                          return _buildOrderItem(orderItems[index]);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal (${orderItems.length} items)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'RM${subtotal.toStringAsFixed(3)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('RM${total.toStringAsFixed(3)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          '*This is not an invoice & prices are not finalised',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isVoidButtonDisabled ? null : voidOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isVoidButtonDisabled ? Colors.grey : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(color: Colors.red, width: 2),
                          ),
                          minimumSize: const Size(120, 40),
                        ),
                        child: const Text(
                          'Void',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    double unitPriceConverted = double.parse(item.unitPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              item.photoPath,
              width: 80,
              height: 80,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Unit Price: RM${unitPriceConverted.toStringAsFixed(3)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          'Qty: ${item.qty}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Status: ${item.status}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text('Total: RM${subtotal.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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