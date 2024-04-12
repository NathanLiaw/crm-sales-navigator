import 'package:crm/order_confirmation_page.dart';
import 'package:flutter/material.dart';
import 'customer.dart';
import 'customer_details_page.dart';
import 'cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPage();
}

class _CartPage extends State<CartPage> {
  // Customer Details Section
  late Customer customer;
  bool customerSelected = false;

  // Cart Section
  List<CartItem> cartItems = [];

  // Edit Cart
  bool editCart = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 2),
                Text(
                  'Shopping Cart',
                  style: TextStyle(
                    color: Color(0xffF8F9FA),
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xff004c87),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    editCart = true;
                  });
                },
                child: const Text(
                  'Edit Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                customerSelected
                    ? CustomerInfo(initialCustomer: customer)
                    : _buildSelectCustomerCard(context),
                const SizedBox(height: 32),
                const Text(
                  'Cart',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (cartItems.isEmpty)
                  const Card(
                    elevation: 6,
                    color: Color(0xffffffff),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 16.0,
                        bottom: 16.0,
                        right: 72.0,
                        left: 16.0,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'No products have been selected yet',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cartItems.map((item) {
                      return const Card(
                        elevation: 6,
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side: Placeholder for Image (Commented out for demo)
                              // Container(
                              //   width: 100,
                              //   height: double.infinity,
                              //   color: Colors.grey[300],
                              // ),
                              SizedBox(width: 8), // Spacer between image and text
                              // Right side: Details Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Item name (bold) - Placeholder
                                    Text(
                                      'Demo Product Name',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    // Variant of the product selected - Placeholder
                                    Text(
                                      'Variant: Demo Variant',
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    // Price of the item - Placeholder
                                    Text(
                                      'Price: \$99.99',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 1,
                  color: Colors.black.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                ),
                // Total and Subtotal Row
                Row(
                  children: [
                    // Container for Total and Subtotal
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 160, // Adjust width as needed
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total Text
                          Text(
                            'Total: RM89.000',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Subtotal Text
                          Text(
                            'Subtotal: RM89.000',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderConfirmationPage()),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(const Color(0xff0069BA)),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Proceed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Separator Line
                Container(
                  height: 1,
                  color: Colors.black.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCustomerCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate to the CustomerDetails page and wait for result
        final selectedCustomer = await Navigator.push<Customer?>(
          context,
          MaterialPageRoute(builder: (context) => const CustomerDetails()),
        );

        // Handle the selected customer received from CustomerDetails page
        if (selectedCustomer != null) {
          setState(() {
            customer = selectedCustomer;
            customerSelected = true;
          });
        }
      },
      child: const Card(
        color: Colors.white,
        elevation: 6,
        child: ListTile(
          title: Text('Select Customer'),
        ),
      ),
    );
  }
}

class CustomerInfo extends StatefulWidget {
  final Customer initialCustomer;

  const CustomerInfo({
    super.key,
    required this.initialCustomer,
  });

  @override
  _CustomerInfoState createState() => _CustomerInfoState();
}

class _CustomerInfoState extends State<CustomerInfo> {
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.initialCustomer;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate to the CustomerDetails page and wait for result
        final selectedCustomer = await Navigator.push<Customer?>(
          context,
          MaterialPageRoute(builder: (context) => const CustomerDetails()),
        );

        // Handle the selected customer received from CustomerDetails page
        if (selectedCustomer != null) {
          // Update the state of the selected customer
          setState(() {
            _customer = selectedCustomer;
          });
        }
      },
      child: Card(
        elevation: 6,
        color: Colors.white,
        child: Stack( // Use Stack to position the "Select" text
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _customer.username,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _customer.addressLine1,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    _customer.addressLine2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _customer.contactNumber,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        _customer.email,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 0,
              right: 0,
              child: Card(
                elevation: 0,
                color: Color(0xffffffff),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    'Select',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class CustomerSection extends StatefulWidget {
//   final Customer customer; // Parameter to receive Customer object
//
//   const CustomerSection({
//     Key? key,
//     required this.customer,
//   }) : super(key: key);
//
//   @override
//   State<CustomerSection> createState() => _CustomerSectionState();
// }
//
// class _CustomerSectionState extends State<CustomerSection> {
//   late Customer _customer; // Local variable to store customer data
//
//   @override
//   void initState() {
//     super.initState();
//     _customer = widget.customer; // Initialize local variable with received customer
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Customer Details'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Name: ${_customer.username}',
//               style: TextStyle(fontSize: 18),
//             ),
//             Text(
//               'Address: ${_customer.addressLine1}',
//               style: TextStyle(fontSize: 18),
//             ),
//             Text(
//               'Phone: ${_customer.contactNumber}',
//               style: TextStyle(fontSize: 18),
//             ),
//             Text(
//               'Email: ${_customer.email}',
//               style: TextStyle(fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CartSection extends StatefulWidget {
//   final List<CartItem> cartItems;
//
//   const CartSection({
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   State<CustomerSection> createState() => _CustomerSectionState();
// }