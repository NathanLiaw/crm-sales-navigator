import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mysql1/mysql1.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/item_screen.dart';
import 'package:sales_navigator/data/product.dart';
import 'package:sales_navigator/item_variations_screen.dart';
import 'dart:convert';

class ItemsWidget extends StatelessWidget {
  final String searchQuery;

  ItemsWidget({required this.searchQuery});

  Future<List<Map<String, dynamic>>> getProductData() async {
    try {
      final conn = await connectToDatabase();
      final results = await conn.query(
          'SELECT id, product_name, photo1, description,sub_category, price_by_uom FROM product WHERE status = 1 AND product_name LIKE ? LIMIT 100',
          ['%$searchQuery%']);
      await conn.close();

      return results
          .map((row) => {
                'id': row['id'],
                'product_name': row['product_name'],
                'photo1': row['photo1'],
                'description': row['description'],
                'sub_category': row['sub_category'],
                'price_by_uom': row['price_by_uom'],
              })
          .toList();
    } catch (e) {
      print('Error fetching product: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getProductData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];

        return SingleChildScrollView(
          child: GridView.count(
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: 0.68,
            crossAxisCount: 2,
            shrinkWrap: true,
            children: products.map((product) {
              final productId = product['id'] as int;
              final productName = product['product_name'] as String;
              final localPath = product['photo1'] as String;
              final itemDescription = product['description'] as Blob;
              final assetName =
                  '$localPath'; // Assuming localPath is the file name, e.g., "photo1.jpg"
              return Container(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // Navigate to the item_screen.dart page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemScreen(
                              productId: productId,
                              itemAssetName: assetName,
                              productName: productName,
                              itemDescription: itemDescription,
                              priceByUom: product['price_by_uom']
                                  .toString(),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 1,
                            color: Color.fromARGB(255, 0, 76, 135),
                          ),
                        ),
                        child: Image.asset(
                          assetName,
                          height: 166,
                          width: 166,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 8),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              children: [
                                Text(
                                  productName, // Display product name
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color.fromARGB(255, 25, 23, 49),
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                              ],
                            ),
                          ),
                          /*IconButton(
                            iconSize: 28,
                            onPressed: () {},
                            icon: const Icon(Icons.thumb_up_alt_outlined),
                          ), */
                        ],
                      ),
                    ),
                    /* Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Product Sub", // You can update this as needed
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color.fromARGB(255, 25, 23, 49),
                        ),
                      ),
                    ), */
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
