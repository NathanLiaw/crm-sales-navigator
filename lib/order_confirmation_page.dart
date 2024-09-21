import 'package:intl/intl.dart';
import 'package:sales_navigator/cart_item.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_sqlite.dart';
import 'package:sales_navigator/order_submitted_page.dart';
import 'package:sales_navigator/terms_and_conditions_page.dart';
import 'utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customer.dart';
import 'dart:developer' as developer;

class OrderConfirmationPage extends StatefulWidget {
  final Customer customer;
  final double total;
  final double subtotal;
  final List<CartItem> cartItems;

  const OrderConfirmationPage({
    super.key,
    required this.customer,
    required this.total,
    required this.subtotal,
    required this.cartItems,
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

  Future<List<String>> fetchOrderOptions() async {
    List<String> fetchedOrderOptions = [];
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readData(
        conn,
        'order_option',
        "order_type='Sales Order' AND status=1",
        '',
        '*',
      );
      await conn.close();

      for (var row in results) {
        fetchedOrderOptions.add(row['order_option'] as String);
      }
    } catch (e) {
      developer.log('Error fetching order options: $e', error: e);
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
    selectedIndices.forEach((index) {
      selectedOrderOptions.add(orderOptions[index]);
    });
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
        'final_total': widget.subtotal,
        'total': finalTotal,
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

  @override
  void initState() {
    super.initState();
    fetchOrderOptions().then((value) {
      setState(() {
        orderOptions = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'en_US', symbol: 'RM', decimalDigits: 3);
    final formattedTotal = formatter.format(widget.total);
    final formattedSubtotal = formatter.format(widget.subtotal);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
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
            children: orderOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Row(
                children: [
                  Checkbox(
                    value: selectedIndices.contains(index),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked ?? false) {
                          selectedIndices.add(index);
                        } else {
                          selectedIndices.remove(index);
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 4.0),
                  Text(option),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 24.0),
          const Text(
            'Remark',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: remarkController,
              decoration: const InputDecoration(
                hintText: 'Write your remark here...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  borderSide: BorderSide.none,
                ),
              ),
              minLines: 2,
              maxLines: null,
            ),
          ),
          const SizedBox(height: 30.0),
          Row(
            children: [
              Checkbox(
                value: agreedToTerms,
                onChanged: (bool? value) {
                  setState(() {
                    agreedToTerms = value ?? false;
                  });
                },
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text:
                        'By clicking Confirm Order, I confirm that I have read '
                        'and agree to the ',
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: const TextStyle(
                            color: Colors.purple,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TermsandConditions(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            '*This is not an invoice & prices are not finalized in this order.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 50),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: $formattedTotal',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    'Subtotal: $formattedSubtotal',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (agreedToTerms) {
                          setState(() {
                            isProcessing = true;
                          });

                          // Show loading animation
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const AlertDialog(
                                backgroundColor: Colors.green,
                                content: SizedBox(
                                  height: 80,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'Processing order...',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          // Perform the operations
                          await createCart();
                          await completeCart();
                          remarkController.clear();

                          // Close the loading animation
                          Navigator.pop(context);

                          // Show order submitted dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Colors.green,
                                title: const Text(
                                  'Order Submitted',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Your order has been successfully submitted.',
                                  style: TextStyle(color: Colors.white),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const OrderSubmittedPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          setState(() {
                            isProcessing = false;
                          });
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Terms and Conditions'),
                                content: const Text(
                                    'Please agree to the terms and conditions before proceeding.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(const Color(0xff0175FF)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
