// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_navigator/model/cart_item.dart';
import 'package:sales_navigator/screens/cart/cart_page.dart';
import 'package:sales_navigator/data/db_sqlite.dart';
import 'package:sales_navigator/model/cart_model.dart';
import 'package:sales_navigator/model/order_status_provider.dart';
import 'package:sales_navigator/screens/sales_order/pdf_viewer_page.dart';
import 'package:sales_navigator/utility_function.dart';
import 'package:sales_navigator/screens/notification/event_logger.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sales_navigator/screens/sales_order/pdf_generator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrderDetailsPage extends StatefulWidget {
  final int cartID;
  final bool fromOrderConfirmation;
  final bool fromSalesOrder;
  final double? discountRate;

  const OrderDetailsPage({
    super.key,
    required this.cartID,
    required this.fromOrderConfirmation,
    required this.fromSalesOrder,
    this.discountRate,
  });

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
  late String status = '';
  late List<OrderItem> orderItems = [];
  double subtotal = 0.0;
  double total = 0.0;
  bool isVoidButtonDisabled = false;
  bool _isExpanded = false;
  bool _isSummaryExpanded = false;
  final PdfInvoiceGenerator pdfGenerator = PdfInvoiceGenerator();

  late int salesmanId;

  double gst = 0;
  double sst = 0;

  late double discountRate = 0.0;

  @override
  void initState() {
    super.initState();
    discountRate = widget.discountRate ?? 0.0;
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
        Uri.parse(
            '${dotenv.env['API_URL']}/cart/get_order_details.php?cartId=$cartId'),
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
            status = orderDetails['status'];
            createdDate = orderDetails['created_date'];
            salesOrderId = 'SO${cartId.toString().padLeft(7, '0')}';
            total = double.tryParse(orderDetails['final_total']) ?? 0.0;
            subtotal = double.tryParse(orderDetails['total']) ?? 0.0;
            discountRate = widget.discountRate ??
                (double.tryParse(
                        orderDetails['discount_rate']?.toString() ?? '0') ??
                    0.0);
            orderItems = [];
          });

          // Fetch all product photos concurrently
          final photoPaths = await Future.wait(cartItems.map((item) async {
            final productId = item['product_id'];
            return fetchProductPhoto(productId);
          }));

          // Process each item and add to orderItems list
          setState(() {
            for (int i = 0; i < cartItems.length; i++) {
              final item = cartItems[i];
              final photoPath = photoPaths[i];

              orderItems.add(OrderItem(
                productId: item['product_id'],
                productName: item['product_name'],
                oriUnitPrice: (item['ori_unit_price'] != null
                    ? double.parse(item['ori_unit_price']).toStringAsFixed(2)
                    : '0.00'),
                unitPrice: (item['unit_price'] != null
                    ? double.parse(item['unit_price']).toStringAsFixed(2)
                    : '0.00'),
                qty: item['qty']?.toString() ?? '0',
                status: item['status'] ?? '',
                total: (item['total'] != null
                    ? double.parse(item['total']).toStringAsFixed(2)
                    : '0.00'),
                photoPath: photoPath,
                uom: item['uom'] ?? '',
                cancel: item['cancel']?.toString(),
              ));
            }
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
        Uri.parse(
            '${dotenv.env['API_URL']}/product/get_prod_photo_by_prod_id.php?productId=$productId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final photos = List<Map<String, dynamic>>.from(data['photos']);
          if (photos.isNotEmpty && photos[0]['photo1'] != null) {
            String photoPath = photos[0]['photo1'];
            if (photoPath.startsWith('photo/')) {
              photoPath = '${dotenv.env['IMG_URL']}/$photoPath';
            }
            return photoPath;
          }
        }
      }
      return 'asset/no_image.jpg';
    } catch (e) {
      developer.log('Error fetching product photo: $e', error: e);
      return 'asset/no_image.jpg';
    }
  }

  Future<void> voidOrder() async {
    String url = '${dotenv.env['API_URL']}/order_details/void_order.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cart_id': widget.cartID}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          // Notify the provider that the order status has changed
          Provider.of<OrderStatusProvider>(context, listen: false)
              .triggerRefresh();
          // Successfully voided the order
          developer.log('Order voided successfully');
        } else {
          developer.log('Error voiding order: ${responseData['message']}');
        }
      } else {
        developer
            .log('Failed to void order. Status code: ${response.statusCode}');
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
    }
  }

  Future<void> getTax() async {
    gst = await UtilityFunction.retrieveTax('GST');
    sst = await UtilityFunction.retrieveTax('SST');
  }

  double calculateTotalDiscount(List<CartItem> items) {
    double totalDiscount = 0.0;

    for (var item in items) {
      // Original price of the item
      double originalPrice = item.originalUnitPrice;
      // Current unit price of the item
      double currentPrice = item.unitPrice;

      // Check if the original price is different from the current unit price
      if (originalPrice != currentPrice) {
        // Calculate the discount amount per item
        double discountAmount = (originalPrice - currentPrice) * item.quantity;

        // Add the discount amount to the total discount
        totalDiscount += discountAmount;
      }
    }

    return totalDiscount;
  }

  Future<void> insertItemIntoCart(CartItem cartItem) async {
    int itemId = cartItem.productId;
    String uom = cartItem.uom;

    try {
      const tableName = 'cart_item';
      final condition =
          "product_id = $itemId AND uom = '$uom' AND status = 'in progress'";
      const order = '';
      const field = '*';

      final db = await DatabaseHelper.database;
      final result = await DatabaseHelper.readData(
        db,
        tableName,
        condition,
        order,
        field,
      );

      if (result.isNotEmpty) {
        final existingItem = result.first;
        final updatedQuantity = existingItem['qty'] + cartItem.quantity;
        final data = {
          'id': existingItem['id'],
          'qty': updatedQuantity,
          'modified': UtilityFunction.getCurrentDateTime(),
        };

        await DatabaseHelper.updateData(data, tableName);
        developer.log('Cart item quantity updated successfully');
      } else {
        final cartItemMap = cartItem.toMap(excludeId: true);
        await DatabaseHelper.insertData(cartItemMap, tableName);
        developer.log('New cart item inserted successfully');
      }
    } catch (e) {
      developer.log('Error inserting or updating cart item: $e', error: e);
    }
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
            if (widget.fromOrderConfirmation) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartPage(),
                ),
              );
            } else if (widget.fromSalesOrder) {
              Navigator.pop(context, true);
            } else {
              Navigator.pop(context, true);
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'viewDocument') {
                final pdfData = await pdfGenerator.generateInvoicePdf(
                  companyName: companyName,
                  address: address,
                  salesmanName: salesmanName,
                  salesOrderId: salesOrderId,
                  createdDate: createdDate,
                  status: status,
                  orderItems: orderItems,
                  gst: gst,
                  sst: sst,
                  customerRate: discountRate,
                );

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PDFViewerPage(
                      pdfData: pdfData,
                      salesOrderId: salesOrderId,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'viewDocument',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined),
                    SizedBox(width: 8),
                    Text('View / Download Order'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: FutureBuilder<void>(
          future: _orderDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                        height: 16.0), // Space between the indicator and text
                    Text(
                      'Fetching order details',
                      style: TextStyle(fontSize: 16.0, color: Colors.grey),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return const Center(child: Text('Failed to fetch order details'));
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExpandableOrderInfo(),
                  // const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Bubble
                      getStatusLabel(status),

                      // Copy Order Button
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _showItemSelectionDialog(orderItems);
                        },
                        icon: const Icon(
                          Icons.shopping_cart,
                          size: 18,
                        ),
                        label: const Text(
                          'Copy Order',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xff0175FF),
                          elevation: 6,
                          shadowColor: Colors.grey.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          minimumSize: const Size(98, 32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // const SizedBox(height: 4),

                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton.icon(
                  //     onPressed: () async {
                  //       final pdfData = await pdfGenerator.generateInvoicePdf(
                  //         companyName: companyName,
                  //         address: address,
                  //         salesmanName: salesmanName,
                  //         salesOrderId: salesOrderId,
                  //         createdDate: createdDate,
                  //         status: status,
                  //         orderItems: orderItems,
                  //         gst: gst,
                  //         sst: sst,
                  //         customerRate: discountRate,
                  //       );

                  //       if (!mounted) return;

                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => PDFViewerPage(
                  //             pdfData: pdfData,
                  //             salesOrderId: salesOrderId,
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //     icon: const Icon(
                  //       Icons.description_outlined,
                  //       size: 20,
                  //       color: Colors.white,
                  //     ),
                  //     label: const Text(
                  //       'View / Download Invoice',
                  //       style: TextStyle(
                  //         color: Colors.white,
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color(0xff0175FF),
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 16,
                  //         vertical: 8,
                  //       ),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(5),
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  // const SizedBox(height: 4),
                  // Order Items List
                  Expanded(
                    child: Column(
                      children: [
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
                        _buildOrderSummary(),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Color getStatusColor(String displayStatus) {
    switch (displayStatus) {
      case 'Confirm':
        return const Color(0xFF33B44F);
      case 'Pending':
        return const Color.fromARGB(255, 255, 194, 82);
      case 'Void':
        return const Color(0xFFE81717);
      default:
        return Colors.grey;
    }
  }

  String getDisplayStatus(String status) {
    if (status == 'in progress') {
      return 'Pending';
    }
    return status;
  }

  Widget getStatusLabel(String status) {
    String displayStatus = getDisplayStatus(status);

    return Container(
      alignment: Alignment.center,
      height: 32,
      width: 98,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: getStatusColor(displayStatus),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayStatus,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Color getExpiryDateColor(String createdDate) {
    DateTime currentDate = DateTime.now();
    DateTime createdDateTime = DateTime.parse(createdDate);
    DateTime expiryDate = createdDateTime.add(Duration(days: 7));

    // Check if the expiry date is within 3 days from the current date
    if (expiryDate.isBefore(currentDate)) {
      // If expired, return red color
      return Colors.red;
    } else if (expiryDate.isBefore(currentDate.add(Duration(days: 3)))) {
      // If within 3 days of expiration, return orange color
      return Colors.orange;
    } else {
      // Default color (black) if not expired or within 3 days
      return Colors.black;
    }
  }

  Widget _buildExpandableOrderInfo() {
    return Card(
      margin: EdgeInsets.zero,
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
                _buildInfoRow(
                  'Created Date:',
                  DateFormat("dd-MM-yyyy HH:mm:ss")
                      .format(DateTime.parse(createdDate)),
                ),
                _buildInfoRow(
                  'Expiry Date:',
                  DateFormat("dd-MM-yyyy HH:mm:ss").format(
                      DateTime.parse(createdDate).add(Duration(days: 7))),
                  style: TextStyle(
                    color: getExpiryDateColor(createdDate)
                  ),
                ),
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

  Future<void> _showItemSelectionDialog(List<OrderItem> items) async {
    List<bool> checkedItems = List<bool>.filled(items.length, true);
    bool selectAll = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            var mediaQuery = MediaQuery.of(context);
            var screenHeight = mediaQuery.size.height;
            var screenWidth = mediaQuery.size.width;

            int selectedCount = checkedItems.where((item) => item).length;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(15),
                ),
                width: screenWidth * 0.95,
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Copy Items To Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: Colors.grey, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '   Select Items: $selectedCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF004072),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            selectAll ? 'Unselect All' : 'Select All',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              selectAll = !selectAll;
                              for (int i = 0; i < checkedItems.length; i++) {
                                checkedItems[i] = selectAll;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (items.length == 1)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[0].productName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.045,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'UOM: ${items[0].uom}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'Qty: ${items[0].qty}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        leading: Checkbox(
                          value: checkedItems[0],
                          onChanged: (bool? value) {
                            if (mounted) {
                              setState(() {
                                checkedItems[0] = value!;
                                if (!value) selectAll = false;
                              });
                            }
                          },
                        ),
                      ),
                    if (items.length > 1)
                      Flexible(
                        child: SizedBox(
                          height: items.length <= 3 ? null : screenHeight * 0.5,
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  children: items.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    var item = entry.value;
                                    return Column(
                                      children: [
                                        CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          title: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.productName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        screenWidth * 0.045,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height:
                                                        screenHeight * 0.005),
                                                Text(
                                                  'UOM: ${item.uom}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height:
                                                        screenHeight * 0.005),
                                                Text(
                                                  'Qty: ${item.qty}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          value: checkedItems[index],
                                          onChanged: (bool? value) {
                                            if (mounted) {
                                              setState(() {
                                                checkedItems[index] = value!;
                                                if (!value) selectAll = false;
                                              });
                                            }
                                          },
                                        ),
                                        if (index != items.length - 1)
                                          const Divider(color: Colors.grey),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: const Color(0xFF33B44F),
                          ),
                          child: const Text(
                            'Copy to cart',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: () async {
                            for (int i = 0; i < items.length; i++) {
                              if (checkedItems[i]) {
                                final item = items[i];
                                final oriUnitPrice = double.tryParse(
                                        item.unitPrice.toString()) ??
                                    0.0;
                                final qty =
                                    int.tryParse(item.qty.toString()) ?? 0;
                                final total = oriUnitPrice * qty;

                                final cartItem = CartItem(
                                  buyerId: await UtilityFunction.getUserId(),
                                  productId: item.productId,
                                  productName: item.productName,
                                  uom: item.uom,
                                  quantity: qty,
                                  discount: 0,
                                  originalUnitPrice: oriUnitPrice,
                                  unitPrice: oriUnitPrice,
                                  total: total,
                                  cancel: null,
                                  remark: null,
                                  status: 'in progress',
                                  created: DateTime.now(),
                                  modified: DateTime.now(),
                                );
                                await insertItemIntoCart(cartItem);
                              }
                            }

                            Provider.of<CartModel>(context, listen: false)
                                .initializeCartCount();

                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Selected items copied to cart',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                duration: Duration(seconds: 3),
                                backgroundColor: Color(0xFF487C08),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: style ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateFilteredSubtotal() {
    double filteredSubtotal = 0.0;
    for (var item in orderItems) {
      if (item.cancel == null ||
          item.cancel == '0' ||
          item.cancel == 'Uncancel') {
        // Only add to subtotal if the item's status is "In Progress"
        filteredSubtotal +=
            double.parse(item.unitPrice) * double.parse(item.qty);
      }
    }
    return filteredSubtotal;
  }

  Widget _buildOrderSummary() {
    final filteredSubtotal = _calculateFilteredSubtotal();
    final gstAmount = gst * filteredSubtotal;
    final sstAmount = sst * filteredSubtotal;
    final customerDiscountAmount = filteredSubtotal * (discountRate / 100);
    final finalTotal =
        filteredSubtotal + gstAmount + sstAmount - customerDiscountAmount;

    final formatter =
        NumberFormat.currency(locale: 'en_US', symbol: 'RM', decimalDigits: 3);

    final formattedSubtotal = formatter.format(filteredSubtotal);
    final formattedGST = formatter.format(gstAmount);
    final formattedSST = formatter.format(sstAmount);
    final formattedCustomerDiscount = formatter.format(customerDiscountAmount);
    final formattedTotal = formatter.format(finalTotal);

    final gstPercentage = (gst * 100).toStringAsFixed(1);
    final sstPercentage = (sst * 100).toStringAsFixed(1);

    return StatefulBuilder(builder: (context, setState) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.only(top: 2),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8,
            right: 8,
            top: 12,
            bottom: 8,
          ),
          child: Column(
            children: [
              if (_isSummaryExpanded) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal (${orderItems.length} items)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formattedSubtotal,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          const TextSpan(text: 'GST '),
                          TextSpan(text: '($gstPercentage%)'),
                        ],
                      ),
                    ),
                    Text(
                      formattedGST,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          const TextSpan(text: 'SST '),
                          TextSpan(text: '($sstPercentage%)'),
                        ],
                      ),
                    ),
                    Text(
                      formattedSST,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          const TextSpan(text: 'Customer Discount '),
                          TextSpan(
                            text: '(${discountRate.toStringAsFixed(1)}%)',
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '- $formattedCustomerDiscount',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                      IconButton(
                        icon: Icon(
                          _isSummaryExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: Colors.blue[700],
                        ),
                        onPressed: () {
                          setState(() {
                            _isSummaryExpanded = !_isSummaryExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    formattedTotal,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xff0175FF),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      '*This is not an invoice & prices are not finalised',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: (isVoidButtonDisabled || shouldHideVoidButton())
                        ? 0.0
                        : 1.0,
                    child: ElevatedButton(
                      onPressed: shouldHideVoidButton()
                          ? null
                          : () => showVoidConfirmationDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: shouldHideVoidButton()
                            ? Colors.transparent
                            : Colors.red,
                        foregroundColor: Colors.white,
                        elevation: shouldHideVoidButton() ? 0 : 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        minimumSize: const Size(120, 40),
                      ),
                      child: shouldHideVoidButton()
                          ? const SizedBox.shrink()
                          : const Text(
                              'Void',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  String _getStatusText(String? cancelStatus) {
    if (cancelStatus == null ||
        cancelStatus == '0' ||
        cancelStatus == 'Uncancel') {
      return 'In Progress';
    } else {
      return cancelStatus;
    }
  }

  Color _getStatusColor(String? cancelStatus) {
    if (cancelStatus == null ||
        cancelStatus == '0' ||
        cancelStatus == 'Uncancel') {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  Widget _buildOrderItem(OrderItem item) {
    double oriUnitPriceConverted = double.parse(item.oriUnitPrice);
    double unitPriceConverted = double.parse(item.unitPrice);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              (item.photoPath.isNotEmpty &&
                      Uri.parse(item.photoPath).isAbsolute)
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
                    Text(
                      item.uom,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unit Price: RM${oriUnitPriceConverted.toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 16),
                      maxLines: null,
                      overflow: TextOverflow.visible,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Disc. Price: RM${unitPriceConverted.toStringAsFixed(3)}',
                            style: const TextStyle(fontSize: 16),
                            maxLines: null,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            'Qty: ${item.qty}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: null,
                            overflow: TextOverflow.visible,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _getStatusText(item.cancel),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(item.cancel),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: item.cancel != null &&
                        item.cancel != '0' &&
                        item.cancel != 'Uncancel'
                    ? Text.rich(
                        TextSpan(
                          text: 'Total: ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'RM${double.parse(item.total).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        'Total: RM${double.parse(item.total).toStringAsFixed(3)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  bool shouldHideVoidButton() {
    return orderItems.isNotEmpty &&
        orderItems
            .every((item) => item.status == 'Void' || item.status == 'Confirm');
  }
}

class OrderItem {
  final int productId;
  final String productName;
  final String oriUnitPrice;
  final String unitPrice;
  final String qty;
  final String status;
  final String total;
  final String photoPath;
  final String uom;
  final String? cancel;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.oriUnitPrice,
    required this.qty,
    required this.status,
    required this.total,
    required this.photoPath,
    required this.uom,
    this.cancel,
  });
}
