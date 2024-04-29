import 'package:sales_navigator/db_connection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customer.dart';

class OrderConfirmationPage extends StatefulWidget {
  final Customer customer;
  final double total;
  final double subtotal;

  const OrderConfirmationPage({
    Key? key,
    required this.customer,
    required this.total,
    required this.subtotal,
  }) : super(key: key);

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  List<String> orderOptions = [];
  Set<int> selectedIndices = {};
  static TextEditingController remarkController = TextEditingController();
  bool agreedToTerms = false;
  String remark = remarkController.text;

  Future<List<String>> fetchOrderOptions() async {
    List<String> fetchedOrderOptions = [];
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readData(
        conn,
        'order_option',
        'order_type="Sales Order" AND status=1',
        '',
        '*',
      );
      await conn.close();

      for (var row in results) {
        fetchedOrderOptions.add(row['order_option'] as String);
        print(row['order_option']);
      }
    } catch (e) {
      print('Error fetching order options: $e');
    }
    return fetchedOrderOptions;
  }

  Future<void> createCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('salesmanName') ?? '';
    int areaId = prefs.getInt('area') ?? 0;
    int id = prefs.getInt('id') ?? 0;

    try {
      MySqlConnection conn = await connectToDatabase();

      // Retrieve tax values asynchronously
      double gst = await UtilityFunction.retrieveTax('GST');
      double sst = await UtilityFunction.retrieveTax('SST');

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
        'order_option': orderOptions,
        'buyer_user_group': 'salesman',
        'buyer_area_id': areaId,
        'buyer_area_name': UtilityFunction.getAreaNameById(areaId),
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
        print('Cart created successfully!');
        // Additional logic upon successful cart creation
      } else {
        print('Failed to create cart.');
        // Handle failure case
      }

      await conn.close();
    } catch (e) {
      print('Error creating cart: $e');
    }
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Order Confirmation', style: TextStyle(color: Colors.white)),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                    text: 'By clicking Confirm Order, I confirm that I have read and agree to the ',
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: const TextStyle(color: Colors.purple, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacementNamed(context, 'terms_and_conditions_page');
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
                    'Total: RM${widget.total.toStringAsFixed(3)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    'Subtotal: RM${widget.subtotal.toStringAsFixed(3)}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: createCart,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(const Color(0xff004c87)),
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
