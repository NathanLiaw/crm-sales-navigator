import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:sales_navigator/cart_item.dart';
import 'package:sales_navigator/db_sqlite.dart';
import 'package:sales_navigator/utility_function.dart';
import 'dart:developer' as developer;

class ItemVariationsScreen extends StatefulWidget {
  const ItemVariationsScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.itemAssetName,
    required this.priceByUom,
  });

  final int productId;
  final String productName;
  final String itemAssetName;
  final String priceByUom;

  @override
  State<ItemVariationsScreen> createState() => _ItemVariationsScreenState();
}

class _ItemVariationsScreenState extends State<ItemVariationsScreen> {
  late Map<String, dynamic> priceData;
  late Map<String, int> quantityMap = {};
  late CartItem? cartItem;

  @override
  void initState() {
    super.initState();
    priceData = jsonDecode(widget.priceByUom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Item Variations',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 76, 135),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: ListView.builder(
        itemCount: priceData.length,
        itemBuilder: (context, idx) {
          final uom = priceData.keys.elementAt(idx);
          final price = priceData[uom];
          final currentQuantity = quantityMap[uom] ?? 1;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 1,
                              color: const Color.fromARGB(255, 0, 76, 135),
                            ),
                          ),
                          child: Image.network(
                            widget.itemAssetName,
                            height: 115,
                            width: 115,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      widget.productName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      uom,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    iconSize: 28,
                                    onPressed: () {
                                      // Decrement quantity when minus button is pressed
                                      if (currentQuantity > 1) {
                                        setState(() {
                                          quantityMap[uom] = currentQuantity - 1;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(text: currentQuantity.toString()),
                                      onChanged: (value) {
                                        final newValue = int.tryParse(value);
                                        if (newValue != null) {
                                          setState(() {
                                            quantityMap[uom] = newValue;
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
                                        quantityMap[uom] = currentQuantity + 1;
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.only(left: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RM ${(price! * currentQuantity).toStringAsFixed(3)}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Create CartItem with current quantity and uom
                              final cartItem = CartItem(
                                buyerId: await UtilityFunction.getUserId(),
                                productId: widget.productId,
                                productName: widget.productName,
                                uom: uom,
                                quantity: currentQuantity,
                                discount: 0,
                                originalUnitPrice: price,
                                unitPrice: price,
                                total: price * currentQuantity,
                                cancel: null,
                                remark: null,
                                status: 'in progress',
                                created: DateTime.now(),
                                modified: DateTime.now(),
                              );

                              // Insert CartItem into database
                              await insertItemIntoCart(cartItem);

                              // Show success dialog
                              showDialog(
                                context: context,
                                builder: (context) => const AlertDialog(
                                  backgroundColor: Colors.green,
                                  title: Row(
                                    children: [
                                      SizedBox(width: 20),
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Item added to cart',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              // Automatically close dialog after 1 second
                              Future.delayed(const Duration(seconds: 1), () {
                                Navigator.pop(context);
                              });
                                                        },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              backgroundColor: const Color.fromARGB(255, 4, 124, 189),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            child: Text(
                              'Add To Cart',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> insertItemIntoCart(CartItem cartItem) async {
    int itemId = cartItem.productId;
    String uom = cartItem.uom;

    try {
      const tableName = 'cart_item';
      final condition = "product_id = $itemId AND uom = '$uom' AND status = 'in progress'";
      const order = '';
      const field = '*';

      final db = await DatabaseHelper.database;

      // Read data from the database based on the provided condition
      final result = await DatabaseHelper.readData(
        db,
        tableName,
        condition,
        order,
        field,
      );

      // Check if the result contains any existing items
      if (result.isNotEmpty) {
        // Item already exists, update the quantity
        final existingItem = result.first;
        final updatedQuantity = existingItem['qty'] + cartItem.quantity;

        // Prepare the data map for update
        final data = {
          'id': existingItem['id'],
          'qty': updatedQuantity,
          'modified': UtilityFunction.getCurrentDateTime(),
        };

        // Call the updateData function to perform the update operation
        await DatabaseHelper.updateData(data, tableName);

        developer.log('Cart item quantity updated successfully');
      } else {
        // Item does not exist, insert it as a new item
        final cartItemMap = cartItem.toMap(excludeId: true);
        await DatabaseHelper.insertData(cartItemMap, tableName);
        developer.log('New cart item inserted successfully');
      }
    } catch (e) {
      developer.log('Error inserting or updating cart item: $e', error: e);
    }
  }
}