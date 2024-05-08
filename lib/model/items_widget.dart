import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/item_screen.dart';
import 'dart:developer' as developer;

class ItemsWidget extends StatelessWidget {
  final int? brandId;
  final int? subCategoryId;
  final String sortOrder;

  const ItemsWidget({super.key, this.brandId, this.subCategoryId, required this.sortOrder});

  Future<List<Map<String, dynamic>>> getProductData() async {
    try {
      final conn = await connectToDatabase();
      String query =
          'SELECT id, product_name, photo1, description, sub_category, brand, price_by_uom, created, viewed FROM product WHERE status = 1';
      List<dynamic> parameters = [];

      if (brandId != null) {
        query += ' AND brand = ?';
        parameters.add(brandId);
      }
      // Else, if subCategoryId is not null, filter by subCategoryId
      else if (subCategoryId != null) {
        query += ' AND sub_category = ?';
        parameters.add(subCategoryId);
      }

      // Add sorting logic based on sortOrder
      if (sortOrder == 'By Name (A to Z)') {
        query += ' ORDER BY product_name ASC';
      } else if (sortOrder == 'By Name (Z to A)') {
        query += ' ORDER BY product_name DESC';
      } else if (sortOrder == 'Uploaded Date (New to Old)') {
        query += ' ORDER BY created ASC';
      } else if (sortOrder == 'Uploaded Date (Old to New)') {
        query += ' ORDER BY created DESC';
      } else if (sortOrder == 'Most Popular in 3 Months') {
        query += ' ORDER BY viewed DESC';
      }

      query += ' LIMIT 100';
      final results = await conn.query(query, parameters);
      await conn.close();

      return results
          .map((row) => {
                'id': row['id'],
                'product_name': row['product_name'],
                'photo1': row['photo1'],
                'description': row['description'],
                'sub_category': row['sub_category'],
                'brand': row['brand'],
                'price_by_uom': row['price_by_uom'],
                'created': row['created'],
                'viewed': row['viewed'],
              })
          .toList();
    } catch (e) {
      developer.log('Error fetching product: $e', error: e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getProductData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];

        return SingleChildScrollView(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.68,
            crossAxisCount: 2,
            shrinkWrap: true,
            children: products.map((product) {
              final productId = product['id'] as int;
              final productName = product['product_name'] as String;
              final localPath = product['photo1'] as String;
              final itemDescription = product['description'] as Blob;
              final assetName = localPath;
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemScreen(
                              productId: productId,
                              itemAssetName: assetName,
                              productName: productName,
                              itemDescription: itemDescription,
                              priceByUom: product['price_by_uom'].toString(),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 1,
                            color: const Color.fromARGB(255, 0, 76, 135),
                          ),
                        ),
                        child: Image.asset(
                          'asset/$assetName',
                          height: 166,
                          width: 166,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              children: [
                                Text(
                                  productName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 25, 23, 49),
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
