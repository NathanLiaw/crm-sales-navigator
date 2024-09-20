import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/edit_item_page.dart';
import 'package:sales_navigator/item_screen.dart';
import 'package:sales_navigator/order_confirmation_page.dart';
import 'package:flutter/material.dart';
import 'package:sales_navigator/utility_function.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'customer.dart';
import 'customer_details_page.dart';
import 'cart_item.dart';
import 'db_sqlite.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPage();
}

class _CartPage extends State<CartPage> {
  // Customer Details Section
  static Customer? customer;
  static bool customerSelected = false;

  // Cart Section
  List<CartItem> cartItems = [];
  List<CartItem> selectedCartItems = [];
  late int totalCartItems = 0;
  late List<List<String>> productPhotos = [];
  double total = 0;
  double subtotal = 0;

  // Tax Section
  double gst = 0;
  double sst = 0;

  // Edit Cart
  bool editCart = false;
  bool isChecked = false;

  List<TextEditingController> textControllers = [];

  @override
  void initState() {
    super.initState();
    loadCartItemsAndPhotos();
    getTax();
    initializeTextControllers();
  }

  void initializeTextControllers() {
    textControllers = List.generate(
        cartItems.length,
        (index) =>
            TextEditingController(text: cartItems[index].quantity.toString()));
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
        updateCartItemsWithLatestPrices();
      });
      calculateTotalAndSubTotal();
      await fetchProductPhotos();
    } catch (e) {
      developer.log('Error loading cart items and photos: $e', error: e);
    }
  }

  Future<List<CartItem>> readCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id = prefs.getInt('id') ?? 0;

    Database database = await DatabaseHelper.database;
    String cartItemTableName = DatabaseHelper.cartItemTableName;
    String condition = "buyer_id = $id AND status = 'in progress'";
    String order = 'created DESC';
    String field = '*';

    List<Map<String, dynamic>> queryResults = await DatabaseHelper.readData(
        database, cartItemTableName, condition, order, field);

    setState(() {
      totalCartItems = queryResults.length;
    });
    List<CartItem> cartItems =
        queryResults.map((map) => CartItem.fromMap(map)).toList();

    textControllers =
        List.generate(cartItems.length, (index) => TextEditingController());

    return cartItems;
  }

  Future<void> fetchProductPhotos() async {
    List<List<String>> photosList = [];

    for (CartItem item in cartItems) {
      List<Map<String, dynamic>> photos =
          await getProductPhoto(item.productName);
      List<String> imagePaths =
          photos.map((photo) => photo['photo1'].toString()).toList();

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
      developer.log('Error fetching product photo: $e', error: e);
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
      List<int?> cartItemIds =
          selectedCartItems.map((item) => item.id).toList();

      // Delete the selected cart items from the database
      for (int? cartItemId in cartItemIds) {
        await DatabaseHelper.deleteData(
            cartItemId, DatabaseHelper.cartItemTableName);
      }

      // Reload the cart items after deletion
      await loadCartItemsAndPhotos();

      // Clear the selected cart items list after successful deletion
      setState(() {
        selectedCartItems.clear();
      });
    } catch (e) {
      developer.log('Error deleting selected cart items: $e', error: e);
    }
  }

  Future<void> updateItemQuantity(int? id, int quantity) async {
    try {
      int? itemId = id ?? 0;

      Map<String, dynamic> updateData = {
        'id': itemId,
        'qty': quantity,
      };

      int rowsAffected =
          await DatabaseHelper.updateData(updateData, 'cart_item');
      if (rowsAffected > 0) {
        developer.log('Item quantity updated successfully');
      } else {
        developer.log('Failed to update item quantity');
      }
    } catch (e) {
      developer.log('Error updating item quantity: $e', error: e);
    }
  }

  void _navigateToItemScreen(String selectedProductName) async {
    MySqlConnection conn = await connectToDatabase();

    try {
      final productData = await readData(
        conn,
        'product',
        "status = 1 AND product_name = '$selectedProductName'",
        '',
        'id, product_name, photo1, photo2, photo3, description, sub_category, price_by_uom',
      );

      if (productData.isNotEmpty) {
        Map<String, dynamic> product = productData.first;

        int productId = product['id'];
        String productName = product['product_name'];
        List<String> itemAssetName = [
          'https://haluansama.com/crm-sales/${product['photo1'] ?? 'null'}',
          'https://haluansama.com/crm-sales/${product['photo2'] ?? 'null'}',
          'https://haluansama.com/crm-sales/${product['photo3'] ?? 'null'}',
        ];
        Blob description = stringToBlob(product['description']);
        String priceByUom = product['price_by_uom'];

        // Navigate to ItemScreen and pass necessary parameters
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemScreen(
              productId: productId,
              productName: productName,
              itemAssetNames: itemAssetName,
              itemDescription: description,
              priceByUom: priceByUom,
            ),
          ),
        );
      } else {
        developer.log('Product not found for name: $selectedProductName');
      }
    } catch (e) {
      developer.log('Error fetching product details: $e', error: e);
    } finally {
      await conn.close();
    }
  }

  Blob stringToBlob(String data) {
    // Create a Blob instance from the string using Blob.fromString
    Blob blob = Blob.fromString(data);

    return blob;
  }

  // Function to retrieve the latest prices for all products in cartItems
  Future<Map<int, double>> retrieveLatestPrices(List<int> productIds) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      // Construct a query to get the latest price for each product in the list
      var results = await conn.query(
          "SELECT product_id, uom, unit_price FROM cart_item WHERE product_id IN (${productIds.join(',')}) ORDER BY created DESC");

      // Use a map to store the latest price for each product
      Map<int, double> latestPrices = {};
      for (var row in results) {
        int productId = row['product_id'];
        if (!latestPrices.containsKey(productId)) {
          latestPrices[productId] = row['unit_price'];
        }
      }
      return latestPrices;
    } finally {
      await conn.close();
    }
  }

  // Function to update cart items with the latest prices
  Future<void> updateCartItemsWithLatestPrices() async {
    if (cartItems.isEmpty) {
      developer.log('Cart is empty. No products to update.');
      return;
    }

    List<int> productIds = cartItems.map((item) => item.productId).toList();
    Map<int, double> latestPrices = await retrieveLatestPrices(productIds);

    for (var item in cartItems) {
      if (latestPrices.containsKey(item.productId)) {
        item.previousPrice = latestPrices[item.productId]!;
      } else {
        developer
            .log('No previous price found for product ID ${item.productId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'en_US', symbol: 'RM', decimalDigits: 3);
    final formattedTotal = formatter.format(total);
    final formattedSubtotal = formatter.format(subtotal);

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
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
            backgroundColor: const Color(0xff0175FF),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    editCart = !editCart; // Toggle editCart state
                  });
                },
                child: Text(
                  editCart
                      ? 'Done'
                      : 'Edit', // Display 'Done' or 'Edit' based on editCart state
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
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Customer Details',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              customerSelected
                  ? CustomerInfo(initialCustomer: customer!)
                  : Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: _buildSelectCustomerCard(context),
                    ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                ),
                child: Text(
                  'Cart ($totalCartItems)',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Display cart items dynamically
              if (cartItems.isEmpty)
                Container(
                  color: Colors.white,
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
                    List<String> itemPhotos =
                        productPhotos.isNotEmpty ? productPhotos[index] : [];
                    bool isSelected = selectedCartItems.contains(item);
                    final currentQuantity = item.quantity;
                    final formattedPrice =
                        formatter.format(item.unitPrice * item.quantity);
                    // Format previous price only if it's not null
                    String? formattedPreviousPrice;
                    if (item.previousPrice != null) {
                      formattedPreviousPrice =
                          formatter.format(item.previousPrice! * item.quantity);
                    }
                    TextEditingController textController =
                        textControllers[index];
                    textController.text = item.quantity.toString();

                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: 10.0, left: 8, right: 8),
                      child: Dismissible(
                        key: Key(item.id.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          // Remove the item from the list and delete from the database
                          setState(() {
                            cartItems.removeAt(index);
                            selectedCartItems.remove(item);
                          });
                          await DatabaseHelper.deleteData(
                              item.id, DatabaseHelper.cartItemTableName);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${item.productName} removed from cart'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            _navigateToItemScreen(item.productName);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [
                                  BoxShadow(
                                    blurStyle: BlurStyle.normal,
                                    color: Color.fromARGB(75, 117, 117, 117),
                                    spreadRadius: 0.1,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ]),
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
                                  if (editCart) // Conditionally render checkbox if editCart is true
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
                                    child: (itemPhotos.isNotEmpty)
                                        ? Image.network(
                                            'https://haluansama.com/crm-sales/${itemPhotos[0]}',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: SizedBox(
                                                width: 180,
                                                child: Text(
                                                  item.productName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow
                                                      .ellipsis, // Overflow handling
                                                  maxLines:
                                                      3, // Allow up to 3 lines of text
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () async {
                                                final updatedPrice =
                                                    await Navigator.push<
                                                        double?>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditItemPage(
                                                      itemId: item.id,
                                                      itemName:
                                                          item.productName,
                                                      itemUom: item.uom,
                                                      itemPhoto:
                                                          itemPhotos.isNotEmpty
                                                              ? itemPhotos[0]
                                                              : '',
                                                      itemPrice: item.unitPrice,
                                                    ),
                                                  ),
                                                );

                                                if (updatedPrice != null) {
                                                  setState(() {
                                                    item.unitPrice =
                                                        updatedPrice;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 200,
                                          child: item.uom.isNotEmpty
                                              ? Text(
                                                  item.uom,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                  softWrap: true,
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Display the item price
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 220,
                                                      child: Row(
                                                        children: [
                                                          Flexible(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  formattedPrice,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .green,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                if (item.previousPrice !=
                                                                    null) // Check if previousPrice is not null
                                                                  Text(
                                                                    item.unitPrice - item.previousPrice! >
                                                                            0
                                                                        ? ' ▲'
                                                                        : (item.unitPrice - item.previousPrice! <
                                                                                0
                                                                            ? ' ▼'
                                                                            : ''),
                                                                    style:
                                                                        TextStyle(
                                                                      color: (item.unitPrice - item.previousPrice! >
                                                                              0)
                                                                          ? Colors
                                                                              .red
                                                                          : ((item.unitPrice - item.previousPrice! < 0)
                                                                              ? Colors.green
                                                                              : null),
                                                                    ),
                                                                  ),
                                                                if (item.previousPrice !=
                                                                        null &&
                                                                    (item.unitPrice -
                                                                            item.previousPrice!) !=
                                                                        0) // Check if previousPrice is not null and price difference is not 0
                                                                  Text(
                                                                    '${((item.unitPrice - item.previousPrice!) / item.previousPrice! * 100).toStringAsFixed(0)}%',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          12,
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
                                                SizedBox(
                                                  child: (item.previousPrice !=
                                                              null &&
                                                          item.previousPrice !=
                                                              item.unitPrice) // Check if previousPrice is not null and is different from unitPrice
                                                      ? Text(
                                                          formattedPreviousPrice!,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.grey,
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        // Group for quantity controls (IconButton and TextField)
                                        Visibility(
                                          visible:
                                              !editCart, // Set visibility based on the value of editCart
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                iconSize: 28,
                                                onPressed: () {
                                                  // Decrement quantity when minus button is pressed
                                                  if (currentQuantity > 1) {
                                                    setState(() {
                                                      item.quantity =
                                                          currentQuantity - 1;
                                                      textController.text = item
                                                          .quantity
                                                          .toString();
                                                      updateItemQuantity(
                                                          item.id,
                                                          item.quantity);
                                                      calculateTotalAndSubTotal();
                                                    });
                                                  } else {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            'Delete Item?'),
                                                        content: const Text(
                                                            'Are you sure you want to delete this item from the cart?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context); // Close the dialog
                                                            },
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              // Remove the item from the list and delete from the database
                                                              setState(() {
                                                                cartItems
                                                                    .removeAt(
                                                                        index);
                                                                selectedCartItems
                                                                    .remove(
                                                                        item);
                                                                totalCartItems =
                                                                    cartItems
                                                                        .length;
                                                              });
                                                              DatabaseHelper.deleteData(
                                                                  item.id,
                                                                  DatabaseHelper
                                                                      .cartItemTableName); // Assuming this is an asynchronous operation
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                      '${item.productName} removed from cart'),
                                                                  duration:
                                                                      const Duration(
                                                                          seconds:
                                                                              1),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                              );
                                                              Navigator.pop(
                                                                  context); // Close the dialog
                                                            },
                                                            child: const Text(
                                                                'Delete'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(Icons.remove),
                                              ),
                                              SizedBox(
                                                width:
                                                    60, // Adjust the width of the TextField container
                                                child: TextField(
                                                  textAlign: TextAlign.center,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'[0-9]')), // Only allow numeric input
                                                    LengthLimitingTextInputFormatter(
                                                        5), // Limit the length of input to 5 characters
                                                  ],
                                                  controller: textController,
                                                  onChanged: (value) {
                                                    final newValue =
                                                        int.tryParse(value);
                                                    if (newValue != null) {
                                                      setState(() {
                                                        item.quantity =
                                                            newValue;
                                                        updateItemQuantity(
                                                            item.id,
                                                            item.quantity);
                                                        calculateTotalAndSubTotal();
                                                      });
                                                    }
                                                    // Check if the entered value is 0 and show confirmation dialog
                                                    if (newValue == 0 ||
                                                        newValue == null) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            AlertDialog(
                                                          title: const Text(
                                                              'Delete Item?'),
                                                          content: const Text(
                                                              'Are you sure you want to delete this item from the cart?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                // Reset quantity to 1 and close the dialog
                                                                setState(() {
                                                                  item.quantity =
                                                                      1;
                                                                  textController
                                                                          .text =
                                                                      '1'; // Reset text field value
                                                                  totalCartItems =
                                                                      cartItems
                                                                          .length;
                                                                });
                                                                Navigator.pop(
                                                                    context); // Close the dialog
                                                              },
                                                              child: const Text(
                                                                  'Cancel'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                // Remove the item from the list and delete from the database
                                                                setState(() {
                                                                  cartItems
                                                                      .removeAt(
                                                                          index);
                                                                  selectedCartItems
                                                                      .remove(
                                                                          item);
                                                                });
                                                                DatabaseHelper
                                                                    .deleteData(
                                                                        item.id,
                                                                        DatabaseHelper
                                                                            .cartItemTableName); // Assuming this is an asynchronous operation
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                        '${item.productName} removed from cart'),
                                                                    duration: const Duration(
                                                                        seconds:
                                                                            1),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .green,
                                                                  ),
                                                                );
                                                                Navigator.pop(
                                                                    context); // Close the dialog
                                                              },
                                                              child: const Text(
                                                                  'Delete'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                              IconButton(
                                                iconSize: 28,
                                                onPressed: () {
                                                  // Increment quantity when plus button is pressed
                                                  setState(() {
                                                    item.quantity =
                                                        currentQuantity + 1;
                                                    updateItemQuantity(
                                                        item.id, item.quantity);
                                                    calculateTotalAndSubTotal();
                                                  });
                                                },
                                                icon: const Icon(Icons.add),
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
                                Text('Total: $formattedTotal',
                                    style: GoogleFonts.inter(
                                      color: Color(0xff0175FF),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  'Subtotal: $formattedSubtotal',
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
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.red),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
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
                          if (customer == null) {
                            // Show dialog if customer is not selected
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Customer Not Selected'),
                                  content: const Text(
                                      'Please select a customer before proceeding.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                            context); // Close the dialog
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else if (cartItems.isEmpty) {
                            // Show dialog if cart items are empty
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Cart is Empty'),
                                  content: const Text(
                                      'Please add items to the cart before proceeding.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                            context); // Close the dialog
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            // Proceed to the order confirmation page if both customer is selected and cart is not empty
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderConfirmationPage(
                                  customer: customer!,
                                  total: total,
                                  subtotal: subtotal,
                                  cartItems: cartItems,
                                ),
                              ),
                            );
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color(0xff0175FF)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          minimumSize: MaterialStateProperty.all<Size>(
                            const Size(120,
                                40), // Adjust the minimum width and height of the button
                          ),
                        ),
                        child: const Text(
                          'Proceed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      )
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
      child: Container(
        width: 368,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Color.fromARGB(255, 196, 196, 196)),
            boxShadow: const [
              BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Color.fromARGB(75, 117, 117, 117),
                spreadRadius: 0.1,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ]),
        child: ListTile(
          titleAlignment: ListTileTitleAlignment.center,
          title: Text(
            'Select Customer',
            style: GoogleFonts.inter(
              color: Color(0xff0175FF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
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
      child: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Color.fromARGB(75, 117, 117, 117),
                spreadRadius: 0.1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ]),
        child: Stack(
          // Use Stack to position the "Select" text
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _customer.companyName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_customer.addressLine1}${_customer.addressLine2.isNotEmpty ? '\n${_customer.addressLine2}' : ''}',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color(0xff191731),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _customer.contactNumber,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        child: Text(
                          _customer.email,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.visible, // Allow text to wrap
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Card(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(
                    color: Colors.blue,
                    width: 1,
                  ),
                ),
                elevation: 0,
                color: Color(0xffffffff),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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
