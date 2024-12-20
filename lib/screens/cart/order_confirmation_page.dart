import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_navigator/model/cart_item.dart';
import 'package:sales_navigator/screens/cart/order_submitted_page.dart';
import 'package:flutter/material.dart';
import 'package:sales_navigator/data/db_sqlite.dart';
import 'package:sales_navigator/model/cart_model.dart';
import 'package:sales_navigator/screens/profile/terms_and_conditions_page.dart';
import 'package:sales_navigator/utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_navigator/model/customer.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  int? salesOrderId;
  late int salesmanId;

  Future<List<String>> fetchOrderOptions() async {
    List<String> fetchedOrderOptions = [];
    String apiUrl =
        '${dotenv.env['API_URL']}/order_option/get_order_options.php';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          fetchedOrderOptions = List<String>.from(data['data']);
        } else {
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
    try {
      // Retrieve shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String name = prefs.getString('salesmanName') ?? '';
      int areaId = prefs.getInt('areaId') ?? 1;
      int id = prefs.getInt('id') ?? 0;

      // Fetch tax values and area name concurrently
      final taxFutures = Future.wait([
        UtilityFunction.retrieveTax('GST'),
        UtilityFunction.retrieveTax('SST'),
        UtilityFunction.getAreaNameById(areaId),
      ]);

      double gst;
      double sst;
      String areaName;

      var results = await taxFutures;
      gst = results[0] as double;
      sst = results[1] as double;
      areaName = results[2] as String;
      developer.log(name);
      developer.log(areaName);
      List<String> selectedOrderOptions =
          selectedIndices.map((index) => orderOptions[index]).toList();
      String stringOrderOptions = selectedOrderOptions.isNotEmpty
          ? '["${selectedOrderOptions.join('","')}"]'
          : 'null';

      Map<String, dynamic> cartData = {
        'order_type': 'SO',
        'expiration_date': UtilityFunction.calculateExpirationDate(),
        'gst': widget.subtotal * gst,
        'sst': widget.subtotal * sst,
        'final_total': widget.total,
        'total': widget.subtotal,
        'remark': remark.toString(),
        'order_option': stringOrderOptions,
        'buyer_user_group': 'salesman',
        'buyer_area_id': areaId,
        'buyer_area_name': areaName,
        'buyer_id': id,
        'buyer_name': name,
        'customer_id': widget.customer.id,
        'customer_company_name': widget.customer.companyName,
        'customer_discount': double.parse(
            ((widget.customer.discountRate / 100) * widget.subtotal)
                .toStringAsFixed(3)),
        'status': 'Pending',
        'last_checked_status': 'Pending',
        'created': UtilityFunction.getCurrentDateTime(),
        'modified': UtilityFunction.getCurrentDateTime(),
      };

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/cart/create_cart.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cartData),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          developer.log('Cart created successfully');
        } else {
          developer.log('Failed to create cart: ${result['message']}');
        }
      } else {
        developer.log('Failed to create cart: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error creating cart: $e');
    }
  }

  Future<void> completeCart() async {
    try {
      salesOrderId = await fetchSalesOrderId();
      int cartId = await fetchSalesOrderId();
      List<Map<String, dynamic>> cartItemsData = [];

      for (CartItem item in widget.cartItems) {
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
          'created': item.created.toUtc().toIso8601String(),
          'modified': item.modified.toUtc().toIso8601String(),
        };
        cartItemsData.add(data);
      }

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/cart/complete_cart.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cartItemsData),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody is List) {
          for (int i = 0; i < responseBody.length; i++) {
            var itemResponse = responseBody[i];
            CartItem item = widget.cartItems[i];

            if (itemResponse['status'] == 'success') {
              developer.log(
                  'Item inserted successfully: ${itemResponse['message']}');

              Map<String, dynamic> updateData = {
                'id': item.id,
                'status': 'Confirm',
              };

              final cartModel = Provider.of<CartModel>(context, listen: false);
              cartModel.initializeCartCount();
              int rowsAffected =
                  await DatabaseHelper.updateData(updateData, 'cart_item');
              if (rowsAffected > 0) {
                developer
                    .log('Item status updated successfully for ID: ${item.id}');
              }
            } else {
              developer
                  .log('Failed to insert item: ${itemResponse['message']}');
            }
          }
        } else {
          if (responseBody['status'] == 'success') {
            developer.log(
                'All items inserted successfully: ${responseBody['message']}');
          } else {
            developer.log('Failed to insert items: ${responseBody['message']}');
          }
        }
      } else {
        developer.log(
            'Failed to complete cart. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error inserting item: $e', error: e);
    }
  }

  Future<int> fetchSalesOrderId() async {
    int salesOrderId = 0;

    try {
      final response = await http.post(
        Uri.parse(
            '${dotenv.env['API_URL']}/cart/get_sales_order_id.php?salesman_id=$salesmanId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          salesOrderId = responseData['sales_order_id'] as int;
        } else {
          developer.log('Error: ${responseData['message']}');
        }
      } else {
        developer.log(
            'Failed to fetch sales order ID. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error retrieving sales order ID: $e');
    }

    return salesOrderId;
  }

  double calculateTotalDiscount(List<CartItem> items) {
    double totalDiscount = 0.0;

    for (var item in items) {
      double originalPrice = item.originalUnitPrice;
      double currentPrice = item.unitPrice;

      if (originalPrice != currentPrice) {
        double discountAmount = (originalPrice - currentPrice) * item.quantity;

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
    final formatter =
        NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 3);
    final orderSummaryFormatter =
        NumberFormat.currency(locale: 'en_US', symbol: 'RM', decimalDigits: 3);
    final formattedTotal = orderSummaryFormatter.format(widget.total);
    final formattedSubtotal = orderSummaryFormatter.format(widget.subtotal);
    final formattedDiscount = orderSummaryFormatter.format(totalDiscount);
    final formattedGST =
        orderSummaryFormatter.format(widget.gst * widget.subtotal);
    final formattedSST =
        orderSummaryFormatter.format(widget.sst * widget.subtotal);
    final customerRate = orderSummaryFormatter
        .format(widget.customer.discountRate / 100 * widget.subtotal)
        .toString();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Order Confirmation',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.4),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Table(
                            border: TableBorder(
                              horizontalInside:
                                  BorderSide(color: Colors.grey.shade300),
                              verticalInside:
                                  BorderSide(color: Colors.grey.shade300),
                              bottom: const BorderSide(
                                  color: Colors.black, width: 2.0),
                            ),
                            columnWidths: const {
                              0: FixedColumnWidth(130),
                              1: FixedColumnWidth(50),
                              2: FixedColumnWidth(70),
                              3: FixedColumnWidth(70),
                              4: FixedColumnWidth(80),
                            },
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(
                                  color: Color(0xFF007ACC),
                                ),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Product',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Qty',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Orig (RM)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Disc (RM)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Total (RM)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                              for (var item in widget.cartItems.asMap().entries)
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: item.key.isEven
                                        ? Colors.grey.shade100
                                        : Colors.white,
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        item.value.productName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        '${item.value.quantity}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.black),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        formatter
                                            .format(
                                                item.value.originalUnitPrice)
                                            .replaceAll('RM', ''),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: item.value.originalUnitPrice !=
                                                  item.value.unitPrice
                                              ? Colors.red[700]
                                              : Colors.black,
                                          decoration:
                                              item.value.originalUnitPrice !=
                                                      item.value.unitPrice
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        item.value.originalUnitPrice !=
                                                item.value.unitPrice
                                            ? formatter
                                                .format(item.value.unitPrice)
                                                .replaceAll('RM', '')
                                            : '-',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        formatter
                                            .format(item.value.unitPrice *
                                                item.value.quantity)
                                            .replaceAll('RM', ''),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 20.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.withOpacity(0.1)
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                        const Text(
                          'Order Summary',
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
                              const Text('Subtotal:',
                                  style: TextStyle(fontSize: 16)),
                              Text(formattedSubtotal,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GST:',
                                  style: TextStyle(fontSize: 16)),
                              Text(formattedGST,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('SST:',
                                  style: TextStyle(fontSize: 16)),
                              Text(formattedSST,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount:',
                                  style: TextStyle(fontSize: 16)),
                              Text(formattedDiscount,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Customer Rate:',
                                  style: TextStyle(fontSize: 16)),
                              Text(customerRate,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                formattedTotal,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
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
          const Text(
              '*This is not an invoice & price not finalised in this order.'),
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
              backgroundColor:
                  WidgetStateProperty.all<Color>(const Color(0xff0069BA)),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              minimumSize: WidgetStateProperty.all<Size>(
                const Size(120, 40),
              ),
            ),
            onPressed: isProcessing
                ? null
                : () async {
                    if (!agreedToTerms) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'You must agree to the terms and conditions'),
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

                    if (salesOrderId != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderSubmittedPage(salesOrderId: salesOrderId!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Failed to create order. Please try again.'),
                        ),
                      );
                    }
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
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
