import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/sales_order_page.dart';
import 'package:sales_navigator/utility_function.dart';
import 'package:sales_navigator/event_logger.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool _isExpanded = false;

  late int salesmanId;

  // Tax Section
  double gst = 0;
  double sst = 0;

  @override
  void initState() {
    super.initState();
    _orderDetailsFuture = fetchOrderDetails();
    getTax();
    _initializeSalesmanId();
  }

  void _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    setState(() {
      salesmanId = id;
    });
  }

  Future<void> fetchOrderDetails() async {
    final cartId = widget.cartID;

    try {
      final response = await http.get(
        Uri.parse('https://haluansama.com/crm-sales/api/cart/get_order_details.php?cartId=$cartId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final orderDetails = data['orderDetails'];
          final cartItems = List<Map<String, dynamic>>.from(data['cartItems']);

          setState(() {
            companyName = orderDetails['company_name'];
            address = orderDetails['address_line_1'];
            salesmanName = orderDetails['salesman_name'];
            createdDate = orderDetails['created_date'];
            salesOrderId = 'SO${cartId.toString().padLeft(7, '0')}';

            orderItems = [];

            // Loop through each cart item to fetch its photo
            cartItems.forEach((item) async {
              final productId = item['product_id'];
              final productName = item['product_name'];

              // Fetch the product photo for each item
              final photoPath = await fetchProductPhoto(productId);

              orderItems.add(OrderItem(
                productId: productId,
                productName: productName,
                unitPrice: item['unit_price'] ?? '0.00',
                qty: item['qty']?.toString() ?? '0',
                status: item['status'] ?? '',
                total: item['total'] ?? '0.00',
                photoPath: photoPath,
              ));

              // Calculate subtotal
              subtotal = orderItems.fold(0.0, (sum, item) => sum + double.parse(item.total));

              calculateTotalAndSubTotal();
            });
          });
        } else {
          developer.log('Failed to fetch order details: ${data['message']}');
        }
      } else {
        developer.log('Failed to fetch order details: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching order details: $e', error: e);
    }
  }

  Future<String> fetchProductPhoto(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('https://haluansama.com/crm-sales/api/product/get_prod_photo_by_prod_id.php?productId=$productId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Extract photo1 from the response
          final photos = List<Map<String, dynamic>>.from(data['photos']);
          if (photos.isNotEmpty && photos[0]['photo1'] != null) {
            String photoPath = photos[0]['photo1'];
            if (photoPath.startsWith('photo/')) {
              photoPath = 'https://haluansama.com/crm-sales/$photoPath';
            }
            return photoPath;
          }
        }
      }
      return 'asset/no_image.jpg';  // Default image if no photo found
    } catch (e) {
      developer.log('Error fetching product photo: $e', error: e);
      return 'asset/no_image.jpg';
    }
  }

  Future<void> voidOrder() async {
    final conn = await connectToDatabase();
    try {
      final success = await saveData(conn, 'cart', {
        'status': 'Void',
        'id': widget.cartID,
      });
      if (!success) {
        developer.log('Failed to void order in cart');
        return;
      }

      final cartItemResults = await readData(
        conn,
        'cart_item',
        'cart_id = ${widget.cartID}',
        '',
        'id',
      );
      for (var result in cartItemResults) {
        await saveData(conn, 'cart_item', {
          'status': 'Void',
          'id': result['id'],
        });
      }

      setState(() {
        isVoidButtonDisabled = true;
        shouldHideVoidButton();
      });

      await fetchOrderDetails();

      await EventLogger.logEvent(
        salesmanId,
        'Order voided',
        'Order Void',
        leadId: null,
      );
    } catch (e) {
      developer.log('Error voiding order: $e');
    } finally {
      await conn.close();
    }
  }

  Future<void> calculateTotalAndSubTotal() async {
    double finalTotal = subtotal * (1 + gst + sst);

    setState(() {
      total = finalTotal;
    });
  }

  Future<void> getTax() async {
    gst = await UtilityFunction.retrieveTax('GST');
    sst = await UtilityFunction.retrieveTax('SST');
  }

  Future<void> showVoidConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Void Order'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to void this order?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                voidOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesOrderPage(),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: FutureBuilder<void>(
          future: _orderDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Failed to fetch order details'));
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExpandableOrderInfo(),
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
                  _buildOrderSummary(),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildExpandableOrderInfo() {
    return Card(
      child: ExpansionTile(
        title: const Text('Order Information',
            style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('To:', '$companyName, $address'),
                _buildInfoRow(
                    'From:', 'Fong Yuan Hung Import & Export Sdn Bhd.'),
                _buildInfoRow('Salesman:', salesmanName),
                _buildInfoRow('Order ID:', salesOrderId),
                _buildInfoRow('Created Date:', createdDate),
              ],
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      children: [
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
            Text('RM${total.toStringAsFixed(3)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
            Opacity(
              opacity:
                  (isVoidButtonDisabled || shouldHideVoidButton()) ? 0.0 : 1.0,
              child: ElevatedButton(
                onPressed: shouldHideVoidButton()
                    ? null
                    : () => showVoidConfirmationDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: shouldHideVoidButton()
                      ? Colors.transparent
                      : Colors.white,
                  shape: shouldHideVoidButton()
                      ? null
                      : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: const BorderSide(color: Colors.red, width: 2),
                        ),
                  minimumSize: const Size(120, 40),
                ),
                child: shouldHideVoidButton()
                    ? const SizedBox.shrink()
                    : const Text(
                        'Void',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
              ),
            )
          ],
        ),
      ],
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
            (item.photoPath.isNotEmpty && Uri.parse(item.photoPath).isAbsolute)
                ? Image.network(
                    item.photoPath,
                    height: 80,
                    width: 80,
                  )
                : Image.asset(
                    'asset/no_image.jpg',
                    height: 80,
                    width: 80,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text('Total: RM${item.total}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  bool shouldHideVoidButton() {
    return orderItems
        .any((item) => item.status == 'Void' || item.status == 'Confirm');
  }
}

class OrderItem {
  final int productId;
  final String productName;
  final String unitPrice;
  final String qty;
  final String status;
  final String total;
  final String photoPath;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.qty,
    required this.status,
    required this.total,
    required this.photoPath,
  });
}
