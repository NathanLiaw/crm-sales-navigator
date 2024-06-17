import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/order_details_page.dart';

class SelectOrderIDPage extends StatefulWidget {
  final String customerName;

  const SelectOrderIDPage({super.key, required this.customerName});

  @override
  _SelectOrderIDPageState createState() => _SelectOrderIDPageState();
}

class _SelectOrderIDPageState extends State<SelectOrderIDPage> {
  late Future<List<Map<String, dynamic>>> salesOrdersFuture;

  @override
  void initState() {
    super.initState();
    salesOrdersFuture = fetchSalesOrders();
  }

  Future<List<Map<String, dynamic>>> fetchSalesOrders() async {
    final conn = await connectToDatabase();

    try {
      final condition =
          "customer_company_name = '${widget.customerName}' AND status = 'Pending' AND CURDATE() <= expiration_date";
      return await readData(conn, 'cart', condition, '', '*');
    } catch (e) {
      print('Error fetching sales orders: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
        title: const Text(
          'Sales Order ID',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: salesOrdersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final salesOrders = snapshot.data ?? [];
            return buildOrderList(salesOrders);
          }
        },
      ),
    );
  }

  Widget buildOrderList(List<Map<String, dynamic>> salesOrders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            top: 16.0,
            right: 16.0,
            left: 16.0,
          ),
          child: Text(
            'Select a Sales Order ID',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Color(0xff191731),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: salesOrders.length,
            itemBuilder: (context, index) {
              final order = salesOrders[index];
              final cartID = order['id'];
              final formattedOrderID = 'SO${cartID.toString().padLeft(7, '0')}';
              final customer = order['customer_company_name'];
              final createdDate = order['created'];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsPage(cartID: cartID),
                    ),
                  ).then((selectedOrderID) {
                    if (selectedOrderID != null) {
                      Navigator.pop(context, selectedOrderID);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 4.0,
                    right: 4.0,
                    bottom: 2.0,
                  ),
                  child: Card(
                    elevation: 2.0,
                    color: const Color(0xffcde5f2),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff191731),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            formattedOrderID,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff191731),
                            ),
                          ),
                          Row(
                            children: [
                              const SizedBox(height: 8.0),
                              Text(
                                'Created: ${_formatDate(createdDate)}',
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Color(0xff191731),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, cartID);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff0069BA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  minimumSize: const Size(40, 40),
                                ),
                                child: const Text(
                                  'Select',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) {
      return '';
    }
    DateTime parsedDate = DateTime.parse(dateString);
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(parsedDate);
  }
}
