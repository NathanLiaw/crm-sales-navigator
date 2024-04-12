import 'package:flutter/material.dart';
import 'db_connection.dart';
import 'package:mysql1/mysql1.dart';
import 'customer.dart';
import 'Components/radio_button.dart';

class CustomerDetails extends StatefulWidget {
  final ValueChanged<Customer>? onSelectionChanged;

  const CustomerDetails({super.key, this.onSelectionChanged});

  @override
  _CustomerDetails createState() => _CustomerDetails();
}

class _CustomerDetails extends State<CustomerDetails> {
  List<Customer> customers = [];
  static int? selectedIndex;
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
        child: ListView(
          children: customers.asMap().entries.map((entry) {
            final index = entry.key;
            final customer = entry.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = selectedIndex == index ? null : index;
                  selectedCustomer = selectedIndex == index ? customer : Customer();

                  // Call the callback with the updated selected customer
                  widget.onSelectionChanged?.call(selectedCustomer);
                });
                Navigator.of(context).pop(customer);
              },
              child: Card(
                color: selectedIndex == index ? const Color(0xfff8f9fa) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RoundRadioButton(
                            selected: selectedIndex == index,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.username,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff191731),
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  customer.addressLine1,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Color(0xff191731),
                                  ),
                                ),
                                Text(
                                  customer.addressLine2,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Color(0xff191731),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 32.0),
                              child: Text(
                                customer.contactNumber,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff191731),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              customer.email,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff191731),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
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
    print('Error fetching customers: $e');
  }
  return fetchedCustomers;
}
