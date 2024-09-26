import 'package:intl/intl.dart';
import 'package:sales_navigator/cart_item.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_sqlite.dart';
import 'package:sales_navigator/order_submitted_page.dart';
import 'package:sales_navigator/terms_and_conditions_page.dart';
import 'utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customer.dart';
import 'package:sales_navigator/event_logger.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderConfirmationPage extends StatefulWidget {
  final Customer customer;
  final double total;
  final double subtotal;
  final List<CartItem> cartItems;
  final double gst;
  final double sst;

  const OrderConfirmationPage({
    super.key,
    required this.customer,
    required this.total,
    required this.subtotal,
    required this.cartItems,
    required this.gst,
    required this.sst,
  });

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  List<String> orderOptions = [];
  Set<int> selectedIndices = {};
  static TextEditingController remarkController = TextEditingController();
  bool agreedToTerms = false;
  String remark = remarkController.text;
  bool isProcessing = false;
  double totalDiscount = 0;

  late int salesmanId;

  Future<List<String>> fetchOrderOptions() async {
    List<String> fetchedOrderOptions = [];
    const String apiUrl = 'https://haluansama.com/crm-sales/api/order_option/get_order_options.php'; 

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Add each order option to the list
          fetchedOrderOptions = List<String>.from(data['data']);
        } else {
          // Handle error case
          developer.log('Error: ${data['message']}');
        }
      } else {
        developer.log('Failed to load order options: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching order options: $e');
    }

    return fetchedOrderOptions;
  }

  Future<void> createCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('salesmanName') ?? '';
    int areaId = prefs.getInt('areaId') ?? 0;
    int id = prefs.getInt('id') ?? 0;

    // Filter selected order options
    List<String> selectedOrderOptions = [];
    for (var index in selectedIndices) {
      selectedOrderOptions.add(orderOptions[index]);
    }
    String stringOrderOptions = 'null';
    if (selectedOrderOptions.isNotEmpty) {
      stringOrderOptions = '["${selectedOrderOptions.join('","')}"]';
    }

    try {
      MySqlConnection conn = await connectToDatabase();

      // Retrieve tax values asynchronously
      double gst = await UtilityFunction.retrieveTax('GST');
      double sst = await UtilityFunction.retrieveTax('SST');
      String areaName = await UtilityFunction.getAreaNameById(areaId);

      // Calculate final total using fetched tax values
      double finalTotal = widget.subtotal * (1 + gst + sst);
      double gstAmount = widget.subtotal * gst;
      double sstAmount = widget.subtotal * sst;

      // Prepare cart data
      Map<String, dynamic> cartData = {
        'order_type': 'SO',
        'expiration_date': UtilityFunction.calculateExpirationDate(),
        'gst': gstAmount,
        'sst': sstAmount,
        'final_total': widget.total,
        'total': widget.subtotal,
        'remark': remark,
        'order_option': stringOrderOptions,
        'buyer_user_group': 'salesman',
        'buyer_area_id': areaId,
        'buyer_area_name': areaName,
        'buyer_id': id,
        'buyer_name': name,
        'customer_id': widget.customer.id,
        'customer_company_name': widget.customer.companyName,
        'customer_discount': widget.customer.customerRate,
        'status': 'Pending',
        'last_checked_status': 'Pending',
        'created': UtilityFunction.getCurrentDateTime(),
        'modified': UtilityFunction.getCurrentDateTime(),
      };

      // Save cart data
      bool saved = await saveData(conn, 'cart', cartData);

      if (saved) {
        developer.log('Cart created successfully');
      } else {
        developer.log('Failed to create cart');
      }

      await conn.close();
    } catch (e) {
      developer.log('Error creating cart: $e', error: e);
    }
  }

  Future<void> completeCart() async {
    try {
      MySqlConnection conn = await connectToDatabase();
      int cartId = await fetchSalesOrderId();
      for (CartItem item in widget.cartItems) {
        // Prepare data to insert into the cart_item table
        Map<String, dynamic> data = {
          'cart_id': cartId,
          'buyer_id': item.buyerId,
          'customer_id': widget.customer.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'uom': item.uom,
          'qty': item.quantity,
          'discount': item.discount,
          'ori_unit_price': item.originalUnitPrice,
          'unit_price': item.unitPrice,
          'total': item.total,
          'cancel': item.cancel,
          'remark': item.remark,
          'status': 'in progress',
          'created': item.created.toUtc(),
          'modified': item.modified.toUtc(),
        };

        // Save the data into the database
        bool saved = await saveData(conn, 'cart_item', data);

        Map<String, dynamic> updateData = {
          'id': item.id,
          'status': 'Confirm',
        };

        int rowsAffected =
            await DatabaseHelper.updateData(updateData, 'cart_item');
        if (rowsAffected > 0) {
          developer.log('Item status updated successfully');
        }

        if (saved) {
          developer.log('Item inserted successfully');
        } else {
          developer.log('Failed to insert item');
        }
      }
    } catch (e) {
      developer.log('Error inserting item: $e', error: e);
    }
  }

  Future<int> fetchSalesOrderId() async {
    int salesOrderId = 0;

    try {
      MySqlConnection conn = await connectToDatabase();
      final result = await readFirst(conn, 'cart', '', 'id DESC');

      if (result.isNotEmpty) {
        salesOrderId = result['id'] as int;
      } else {
        developer.log('No sales order ID found in the cart table');
      }

      await conn.close();
    } catch (e) {
      developer.log('Error retrieving sales order ID: $e', error: e);
    }

    return salesOrderId;
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

  @override
  void initState() {
    super.initState();
    fetchOrderOptions().then((value) {
      setState(() {
        orderOptions = value;
        totalDiscount = calculateTotalDiscount(widget.cartItems);
      });
    });
    _initializeSalesmanId();
  }

  void _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    setState(() {
      salesmanId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: 'RM', decimalDigits: 2);
    final formattedTotal = formatter.format(widget.total);
    final formattedSubtotal = formatter.format(widget.subtotal);
    final formattedDiscount = formatter.format(totalDiscount);
    final formattedGST = formatter.format(widget.gst * widget.subtotal);
    final formattedSST = formatter.format(widget.sst * widget.subtotal);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Order Confirmation',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CartPage(),
              ),
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Payment Term',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(orderOptions.length, (index) {
              return CheckboxListTile(
                title: Text(orderOptions[index]),
                value: selectedIndices.contains(index),
                onChanged: (bool? value) {
                  setState(() {
                    if (value != null) {
                      if (value) {
                        selectedIndices.add(index);
                      } else {
                        selectedIndices.remove(index);
                      }
                    }
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Order Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6.0),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Displaying order details
                SizedBox(
                  height: 250.0,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey.shade300),
                            verticalInside: BorderSide(color: Colors.grey.shade300),
                            bottom: const BorderSide(color: Colors.black, width: 2.0),
                          ),
                          columnWidths: const {
                            0: FixedColumnWidth(130), // Width for product name
                            1: FixedColumnWidth(50),  // Width for quantity
                            2: FixedColumnWidth(70),  // Width for original price
                            3: FixedColumnWidth(70),  // Width for discounted price
                            4: FixedColumnWidth(70),  // Width for total price
                          },
                          children: [
                            // Header Row
                            const TableRow(
                              children: [
                                Text('Product', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Orig', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Disc', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            // Data Rows
                            for (var item in widget.cartItems)
                              TableRow(
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                  Text(
                                    formatter.format(item.originalUnitPrice),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.originalUnitPrice != item.unitPrice ? Colors.red[700] : Colors.black,
                                      decoration: item.originalUnitPrice != item.unitPrice ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Text(
                                    item.originalUnitPrice != item.unitPrice
                                        ? formatter.format(item.unitPrice)
                                        : '-', // Display '-' if prices are the same
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    formatter.format(item.unitPrice * item.quantity),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Order summary
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4.0,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Divider(color: Colors.black54),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                            Text(formattedSubtotal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GST:', style: TextStyle(fontSize: 16)),
                            Text(formattedGST, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('SST:', style: TextStyle(fontSize: 16)),
                            Text(formattedSST, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount:', style: TextStyle(fontSize: 16)),
                            Text(formattedDiscount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(formattedTotal, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),
          TextField(
            controller: remarkController,
            decoration: const InputDecoration(
              labelText: 'Remark',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                remark = value;
              });
            },
          ),
          const SizedBox(height: 16.0),
          const Text('*This is not an invoice & price not finalised in this order.'),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: agreedToTerms,
                onChanged: (value) {
                  setState(() {
                    agreedToTerms = value ?? false;
                  });
                },
              ),
              const Text('I agree to the '),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsandConditions(),
                    ),
                  );
                },
                child: const Text(
                  'Terms and Conditions',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(const Color(0xff0069BA)),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              minimumSize: WidgetStateProperty.all<Size>(
                const Size(120, 40),
              ),
            ),
            onPressed: () async {
              if (!agreedToTerms) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You must agree to the terms and conditions'),
                  ),
                );
                return;
              }

              setState(() {
                isProcessing = true;
              });

              await createCart();
              await completeCart();

              setState(() {
                isProcessing = false;
              });

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderSubmittedPage(),
                ),
              );
            },
            child: isProcessing
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white),
            )
                : const Text(
              'Submit Order',
              style: TextStyle(
                color: Colors.white, // Set text color
                fontSize: 20, // Set text size
              ),
            ),
          ),
        ],
      ),
    );
  }
}
