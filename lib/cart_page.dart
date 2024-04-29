import 'package:sales_navigator/Components/customer_navigation_bar.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/edit_item_page.dart';
import 'package:sales_navigator/order_confirmation_page.dart';
import 'package:flutter/material.dart';
import 'package:sales_navigator/order_confirmation_page.dart';
import 'package:sales_navigator/utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'customer.dart';
import 'customer_details_page.dart';
import 'cart_item.dart';
import 'db_sqlite.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPage();
}

class _CartPage extends State<CartPage> {
  // Customer Details Section
  Customer? customer;
  bool customerSelected = false;

  // Cart Section
  List<CartItem> cartItems = [];
  List<CartItem> selectedCartItems = [];
  List<Map<int?, double>> updatedCartItemPrice = [];
  late List<List<String>> productPhotos = [];
  double total = 0;
  double subtotal = 0;

  // Tax Section
  double gst = 0;
  double sst = 0;

  // Edit Cart
  bool editCart = false;
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    initializeUpdatedCartItemPrice(); // Initialize the updatedCartItemPrice list
    loadCartItemsAndPhotos(); // Load cart items and photos
    getTax(); // Fetch tax values
  }

  void initializeUpdatedCartItemPrice() {
    for (CartItem item in cartItems) {
      int id = item.id ?? 0;
      double price = item.unitPrice * (item.quantity ?? 1);
      updatedCartItemPrice.add({id: price});
    }
  }

  Future<void> getTax() async {
    gst = await UtilityFunction.retrieveTax('GST');
    sst = await UtilityFunction.retrieveTax('SST');
  }

  Future<void> loadCartItemsAndPhotos() async {
    try {
      List<CartItem> items = await readCartItems();
      setState(() {
        cartItems = items;
      });
      await fetchProductPhotos();
      calculateTotalAndSubTotal();
    } catch (e) {
      print('Error loading cart items and photos: $e');
      // Handle error here, e.g., show error message to user
    }
  }

  Future<List<CartItem>> readCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id = prefs.getInt('id') ?? 0;

    Database database = await DatabaseHelper.database;
    String cartItemTableName = DatabaseHelper.cartItemTableName;
    String condition = 'buyer_id = $id';
    String order = 'created DESC';
    String field = '*';

    List<Map<String, dynamic>> queryResults =
    await DatabaseHelper.readData(database, cartItemTableName, condition, order, field);

    List<CartItem> cartItems = queryResults.map((map) => CartItem.fromMap(map)).toList();
    return cartItems;
  }

  Future<void> fetchProductPhotos() async {
    List<List<String>> photosList = [];

    for (CartItem item in cartItems) {
      List<Map<String, dynamic>> photos = await getProductPhoto(item.productName);
      List<String> imagePaths =
      photos.map((photo) => photo['photo1'].toString()).toList(); // Ensure photo1 is string

      photosList.add(imagePaths);
    }

    setState(() {
      productPhotos = photosList;
    });
  }

  Future<List<Map<String, dynamic>>> getProductPhoto(String productName) async {
    try {
      final conn = await connectToDatabase();
      final results = await conn.query(
        'SELECT photo1 FROM product WHERE status = 1 AND product_name LIKE ?',
        ['%$productName%'],
      );
      await conn.close();

      return results.map((row) => {'photo1': row['photo1']}).toList();
    } catch (e) {
      print('Error fetching product photo: $e');
      return [];
    }
  }

  Future<void> calculateTotalAndSubTotal() async {
    double calculatedSubtotal = 0;

    // Calculate total and subtotal based on cart items
    for (CartItem item in cartItems) {
      calculatedSubtotal += item.unitPrice * item.quantity;
    }

    // Calculate final total using fetched tax values
    double finalTotal = calculatedSubtotal * (1 + gst + sst);

    // Update state with calculated values
    setState(() {
      total = finalTotal;
      subtotal = calculatedSubtotal;
    });
  }

  Future<void> deleteSelectedCartItems() async {
    try {
      // Get the list of cart item IDs to be deleted
      List<int?> cartItemIds = selectedCartItems.map((item) => item.id).toList();

      // Open the database connection
      Database database = await DatabaseHelper.database;

      // Delete the selected cart items from the database
      for (int? cartItemId in cartItemIds) {
        await DatabaseHelper.deleteData(cartItemId, DatabaseHelper.cartItemTableName);
      }

      // Reload the cart items after deletion
      await loadCartItemsAndPhotos();

      // Clear the selected cart items list after successful deletion
      setState(() {
        selectedCartItems.clear();
      });

      // Show a success message or perform any other necessary actions
      print('Selected cart items deleted successfully');
    } catch (e) {
      print('Error deleting selected cart items: $e');
      // Handle error here, e.g., show error message to user
    }
  }

  Future<void> updateItemQuantity(int? id, int quantity) async {
    try {
      int? itemId = id ?? 0; // Assuming itemId is not null, otherwise handle accordingly

      Map<String, dynamic> updateData = {
        'id': itemId,
        'qty': quantity,
      };

      int rowsAffected = await DatabaseHelper.updateData(updateData, 'cart_item');
      if (rowsAffected > 0) {
        // Database update successful
        print('Item quantity updated successfully');
      } else {
        // Handle database update failure
        print('Failed to update item quantity');
      }
    } catch (e) {
      print('Error updating item quantity: $e');
    }
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
            automaticallyImplyLeading: false,
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
                    editCart = !editCart; // Toggle editCart state
                  });
                },
                child: Text(
                  editCart ? 'Done' : 'Edit', // Display 'Done' or 'Edit' based on editCart state
                  style: const TextStyle(
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              customerSelected
                  ? CustomerInfo(initialCustomer: customer!)
                  : _buildSelectCustomerCard(context),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.only(

                ),
                child: Text(
                  'Cart',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Display cart items dynamically
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
                  children: List.generate(cartItems.length, (index) {
                    CartItem item = cartItems[index];
                    List<String> itemPhotos = productPhotos.isNotEmpty ? productPhotos[index] : [];
                    bool isSelected = selectedCartItems.contains(item);
                    final currentQuantity = item.quantity ?? 1;
                    double itemPrice = 0; // Last stopped here
                    if (updatedCartItemPrice.isNotEmpty) {
                      // Find the map corresponding to the item.id
                      Map<int?, double>? itemPriceMap = updatedCartItemPrice.firstWhere(
                            (map) => map.containsKey(item.id),
                        orElse: () => Map<int, double>(), // Return an empty map if not found
                      );

                      if (itemPriceMap != null && itemPriceMap.containsKey(item.id)) {
                        // Access the price using item.id as the key
                        itemPrice = itemPriceMap[item.id]!;
                      } else {
                        print('Price not found for item ${item.id}');
                      }
                    } else {
                      print('No price updates available');
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Card(
                        elevation: 2,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            bottom: 8.0,
                            left: 6.0,
                            right: 2.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (editCart)  // Conditionally render checkbox if editCart is true
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value != null && value) {
                                        // Add the item to selectedCartItems when checkbox is checked
                                        selectedCartItems.add(item);
                                      } else {
                                        // Remove the item from selectedCartItems when checkbox is unchecked
                                        selectedCartItems.remove(item);
                                      }
                                    });
                                  },
                                ),
                              SizedBox(
                                width: 90,
                                child: itemPhotos.isNotEmpty
                                    ? Image.asset(
                                  itemPhotos[0],
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                )
                                    : Image.asset(
                                  'asset/no_image.jpg',
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: 160,
                                          child: Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis, // Overflow handling
                                            maxLines: 3, // Allow up to 2 lines of text
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () async {
                                            final updatedPrice = await Navigator.push<double?>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EditItemPage(
                                                  itemId: item.id,
                                                  itemName: item.productName,
                                                  itemUom: item.uom,
                                                  itemPhoto: itemPhotos.isNotEmpty ? itemPhotos[0] : '',
                                                  itemPrice: item.unitPrice,
                                                ),
                                              ),
                                            );

                                            if (updatedPrice != null) {
                                              setState(() {
                                                int itemIndex = cartItems.indexWhere((element) => element.id == item.id);
                                                if (itemIndex != -1) {
                                                  updatedCartItemPrice[itemIndex][item.id] = updatedPrice;
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Variant: ${item.uom}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Display the item price
                                        Container(
                                          width: 100,
                                          child: Text(
                                            'RM${(itemPrice * (item.quantity ?? 1)).toStringAsFixed(3)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Group for quantity controls (IconButton and TextField)
                                        Row(
                                          children: [
                                            IconButton(
                                              iconSize: 28,
                                              onPressed: () {
                                                // Decrement quantity when minus button is pressed
                                                if (currentQuantity > 1) {
                                                  setState(() {
                                                    item.quantity = currentQuantity - 1;
                                                    updateItemQuantity(item.id, item.quantity);
                                                    calculateTotalAndSubTotal();
                                                  });
                                                }
                                              },
                                              icon: const Icon(Icons.remove),
                                            ),
                                            Container(
                                              width: 20, // Adjust the width of the TextField container
                                              child: TextField(
                                                textAlign: TextAlign.center,
                                                keyboardType: TextInputType.number,
                                                controller: TextEditingController(text: currentQuantity.toString()),
                                                onChanged: (value) {
                                                  final newValue = int.tryParse(value);
                                                  if (newValue != null) {
                                                    setState(() {
                                                      item.quantity = newValue;
                                                      updateItemQuantity(item.id, item.quantity);
                                                      calculateTotalAndSubTotal();
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              iconSize: 28,
                                              onPressed: () {
                                                // Increment quantity when plus button is pressed
                                                setState(() {
                                                  item.quantity = currentQuantity + 1;
                                                  updateItemQuantity(item.id, item.quantity);
                                                  calculateTotalAndSubTotal();
                                                });
                                              },
                                              icon: const Icon(Icons.add),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
      persistentFooterButtons: [
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: Container(
            padding: const EdgeInsets.only(
              left: 8.0,
              top: 4.0,
            ),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: editCart
                          ? Text(
                        '${selectedCartItems.length} item(s) selected',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total: RM${total.toStringAsFixed(3)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Subtotal: RM${subtotal.toStringAsFixed(3)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (editCart)
                      ElevatedButton(
                        onPressed: () {
                          if (selectedCartItems.isNotEmpty) {
                            deleteSelectedCartItems();
                          } else {
                            // Handle case where no items are selected
                            print('No items selected for deletion');
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    if (!editCart)
                      ElevatedButton(
                        onPressed: () {
                          if (customer != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderConfirmationPage(
                                  customer: customer!,
                                  total: total,
                                  subtotal: subtotal,
                                ),
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Customer Not Selected'),
                                  content: const Text('Please select a customer before proceeding.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context); // Close the dialog
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
                          backgroundColor: MaterialStateProperty.all<Color>(const Color(0xff0069BA)),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          minimumSize: MaterialStateProperty.all<Size>(
                            const Size(120, 40), // Adjust the minimum width and height of the button
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
        elevation: 4,
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