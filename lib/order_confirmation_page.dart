import 'package:crm/db_connection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class OrderConfirmationPage extends StatefulWidget {
  const OrderConfirmationPage({super.key});

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  List<String> orderOptions = [];
  Set<int> selectedIndices = {};
  TextEditingController remarkController = TextEditingController();
  bool agreedToTerms = false;

  // Assume this method is implemented to fetch order options
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
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Order Confirmation',
          style: TextStyle(color: Color(0xffF8F9FA)),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Payment Term',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                    decoration: InputDecoration(
                      hintText: 'Write your remark here...',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 16.0),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                    Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      padding: const EdgeInsets.all(4.0),
                      child: RichText(
                        text: TextSpan(
                          text:
                              'By clicking Confirm Order, I confirm that I have read and agree to the ',
                          style: const TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: const TextStyle(
                                color: Colors.purple,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacementNamed(
                                      context, 'terms_and_conditions_page');
                                },
                            ),
                            const TextSpan(
                              text: '.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Text(
                  '*This is not an invoice & prices are not finalised in this order.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 80,
                ),
                Container(
                  height: 1,
                  color: Colors.black.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total: RM89.000',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Sub Total: RM89.000',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, 'order_submitted_page');
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color(0xff004c87)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
