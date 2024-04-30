import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sales_navigator/db_sqlite.dart';

class EditItemPage extends StatefulWidget {
  final int? itemId;
  final String itemName;
  final String itemUom;
  final String itemPhoto;
  final double itemPrice;

  const EditItemPage({
    super.key,
    required this.itemName,
    required this.itemId,
    required this.itemUom,
    required this.itemPhoto,
    required this.itemPrice,
  });

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  double originalPrice = 0.0;
  double discountPercentage = 0.0;
  TextEditingController priceController = TextEditingController();
  TextEditingController discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    originalPrice = widget.itemPrice;
  }

  void calculateDiscountedPrice() {
    double discountAmount = originalPrice * (discountPercentage / 100);
    double discountedPrice = originalPrice - discountAmount;
    print(discountedPrice);
    updateItemPrice(discountedPrice);
  }

  Future<void> updateItemPrice(double newPrice) async {
    try {
      int itemId = widget.itemId ?? 0; // Assuming itemId is not null, otherwise handle accordingly

      Map<String, dynamic> updateData = {
        'id': itemId,
        'unit_price': newPrice,
      };

      int rowsAffected = await DatabaseHelper.updateData(updateData, 'cart_item');
      if (rowsAffected > 0) {
        // Database update successful
        print('Item price updated successfully');
        setState(() {
          originalPrice = newPrice;
        });
      } else {
        // Handle database update failure
        print('Failed to update item price');
      }
    } catch (e) {
      print('Error updating item price: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Edit Item',
          style: TextStyle(color: Color(0xffF8F9FA)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, originalPrice);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Color(0xffcde5f2),
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Image
                        Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          // Replace the child with your actual image widget
                          child: SizedBox(
                            width: 90,
                            child: widget.itemPhoto.isNotEmpty
                                ? Image.asset(
                              widget.itemPhoto,
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
                        ),
                        const SizedBox(width: 16.0),
                        // Right side: Name and Description
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 200,
                              child: Text(
                                '${widget.itemName}',
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              '${widget.itemUom}',
                              style: const TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // Text fields for Reprice and Discount
                    Row(
                      children: [
                        // Reprice field
                        const Text(
                          'Unit Price (RM)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0), // Spacer
                        Expanded(
                          child: SizedBox(
                            height: 36.0,
                            child: TextField(
                              controller: priceController,
                              decoration: InputDecoration(
                                hintText: (originalPrice).toStringAsFixed(3),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        // Discount field
                        const Text(
                          'Discount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 50.0), // Spacer
                        Expanded(
                          child: SizedBox(
                            height: 36.0,
                            child: TextField(
                              controller: discountController,
                              decoration: const InputDecoration(
                                hintText: '0%',
                                contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      priceController.clear();
                      discountController.clear();
                    });
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 20.0), // Adjust button padding
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      const Size(120.0, 40.0), // Set the width and height of Button 1
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 46.0), // Adjust the spacing between buttons
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (priceController.text.trim().isNotEmpty) {
                        originalPrice = double.parse(priceController.text);
                      }
                      if (discountController.text.trim().isNotEmpty) {
                        discountPercentage = double.parse(discountController.text);
                      }
                    });

                    if (discountPercentage > 0.0) {
                      calculateDiscountedPrice();
                    }
                    else {
                      updateItemPrice(originalPrice);
                    }

                    showDialog(
                      context: context,
                      builder: (context) => const AlertDialog(
                        backgroundColor: Colors.green,
                        title: Row(
                          children: [
                            SizedBox(width: 40),
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Price updated',
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
                      Navigator.pop(context); // Close dialog
                    });
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 20.0), // Adjust button padding
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      const Size(120.0, 40.0), // Set the width and height of Button 2
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(const Color(0xff0069ba)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0), // Adjust border radius
                      ),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
