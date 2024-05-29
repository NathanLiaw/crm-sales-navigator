import 'package:flutter/material.dart';
import 'db_connection.dart';
import 'package:mysql1/mysql1.dart';
import 'customer.dart';
import 'dart:developer' as developer;

class CustomerDetails extends StatefulWidget {
  final ValueChanged<Customer>? onSelectionChanged;

  const CustomerDetails({super.key, this.onSelectionChanged});

  @override
  _CustomerDetailsState createState() => _CustomerDetailsState();
}

class _CustomerDetailsState extends State<CustomerDetails> {
  List<Customer> customers = [];
  int? selectedIndex;
  late Customer selectedCustomer;

  @override
  void initState() {
    super.initState();
    fetchCustomers().then((value) {
      setState(() {
        customers = value;
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
          'Customer Details',
          style: TextStyle(color: Color(0xffF8F9FA)),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(
                top: 16.0,
                right: 16.0,
                left: 16.0,
              ),
              child: Text(
                'Select a customer',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff191731),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = isSelected ? null : index;
                        selectedCustomer = isSelected ? Customer() : customer;

                        // Call the callback with the updated selected customer
                        widget.onSelectionChanged?.call(selectedCustomer);
                      });

                      Navigator.pop(context, selectedCustomer);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 4.0,
                          right: 4.0,
                          bottom: 2.0
                      ),
                      child: Card(
                        elevation: 2.0,
                        color: isSelected ? const Color(0xfff8f9fa) : const Color(0xffcde5f2),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.companyName,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff191731),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '${customer.addressLine1}${customer.addressLine2.isNotEmpty ? '\n${customer.addressLine2}' : ''}',
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Color(0xff191731),
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    customer.contactNumber,
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff191731),
                                    ),
                                  ),
                                  Text(
                                    customer.email,
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff191731),
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
        ),
      ),
    );
  }
}

Future<List<Customer>> fetchCustomers() async {
  List<Customer> fetchedCustomers = [];
  try {
    MySqlConnection conn = await connectToDatabase();
    final results = await readData(
      conn,
      'customer',
      'status=1',
      '',
      '*',
    );
    await conn.close();

    for (var row in results) {
      fetchedCustomers.add(Customer(
        id: row['id'] as int?,
        area: row['area'] as int,
        userGroup: row['user_group'] as String? ?? '',
        companyName: row['company_name'] as String? ?? '',
        customerRate: row['customer_rate'] as int,
        username: row['username'] as String? ?? '',
        addressLine1: row['address_line_1'] as String? ?? '',
        addressLine2: row['address_line_2'] as String? ?? '',
        contactNumber: row['contact_number'] as String? ?? '',
        email: row['email'] as String? ?? '',
      ));
    }
  } catch (e) {
    developer.log('Error fetching customers: $e', error: e);
  }
  return fetchedCustomers;
}