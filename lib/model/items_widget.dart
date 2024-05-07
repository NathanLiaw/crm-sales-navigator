import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/item_screen.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ItemsWidget extends StatefulWidget {
  final int? brandId; // Brand ID to filter products
  final int? subCategoryId;
  final List<int>? subCategoryIds;
  final List<int>? brandIds;
  final String sortOrder;
  final bool isFeatured;

  ItemsWidget({
    this.brandId,
    this.subCategoryId,
    this.subCategoryIds,
    this.brandIds,
    required this.sortOrder,
    required this.isFeatured,
  });

  @override
  _ItemsWidgetState createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<ItemsWidget> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _products = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final totalProducts = await getTotalProductsCount();
    _totalPages = (totalProducts / 50).ceil();

    final products = await getProductData(
      offset: (_currentPage - 1) * 50,
      limit: 50,
    );
    setState(() {
      _products = products;
    });
  }

  Future<int> getTotalProductsCount() async {
    try {
      final conn = await connectToDatabase();
      final results = await conn
          .query('SELECT COUNT(*) as total FROM product WHERE status = 1');
      await conn.close();

      return results.first['total'] as int;
    } catch (e) {
      print('Error fetching total products count: $e');
      return 0;
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_currentPage < _totalPages) {
      setState(() {
        _isLoadingMore = true;
      });

      final products = await getProductData(
        offset: _currentPage * 50,
        limit: 50,
      );

      setState(() {
        _products.addAll(products);
        _currentPage++;
        _isLoadingMore = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> getProductData(
      {int offset = 0, int limit = 50}) async {
    try {
      final conn = await connectToDatabase();
      String query =
          'SELECT id, product_name, photo1, photo2, photo3, description, sub_category, brand, price_by_uom, featured, created, viewed FROM product WHERE status = 1';
      List<dynamic> parameters = [];

      if (widget.brandId != null) {
        query += ' AND brand = ?';
        parameters.add(widget.brandId);
      } else if (widget.subCategoryId != null) {
        query += ' AND sub_category = ?';
        parameters.add(widget.subCategoryId);
      }

      if (widget.brandIds?.isNotEmpty ?? false) {
        query += ' AND brand IN (${widget.brandIds!.join(", ")})';
      }

      if (widget.subCategoryIds?.isNotEmpty ?? false) {
        query += ' AND sub_category IN (${widget.subCategoryIds!.join(", ")})';
      }

      if (widget.isFeatured) {
        query += ' AND featured = "Yes"';
      }

      if (widget.sortOrder == 'By Name (A to Z)') {
        query += ' ORDER BY product_name ASC';
      } else if (widget.sortOrder == 'By Name (Z to A)') {
        query += ' ORDER BY product_name DESC';
      } else if (widget.sortOrder == 'Uploaded Date (New to Old)') {
        query += ' ORDER BY created ASC';
      } else if (widget.sortOrder == 'Uploaded Date (Old to New)') {
        query += ' ORDER BY created DESC';
      } else if (widget.sortOrder == 'Most Popular in 3 Months') {
        query += ' ORDER BY viewed DESC';
      }

      query += ' LIMIT ? OFFSET ?';
      parameters.addAll([limit, offset]);

      final results = await conn.query(query, parameters);
      await conn.close();

      return results
          .map((row) => {
                'id': row['id'],
                'product_name': row['product_name'],
                'photo1': row['photo1'],
                'photo2': row['photo2'],
                'photo3': row['photo3'],
                'description': row['description'],
                'sub_category': row['sub_category'],
                'brand': row['brand'],
                'price_by_uom': row['price_by_uom'],
                'featured': row['featured'],
                'created': row['created'],
                'viewed': row['viewed'],
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

        final products = _products;
        final screenWidth = MediaQuery.of(context).size.width;
        final childAspectRatio = screenWidth < 2000 ? 0.60 : 0.64;

        return Expanded(
          child: GridView.count(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            childAspectRatio: childAspectRatio,
            crossAxisCount: 2,
            shrinkWrap: true,
            children: products.map((product) {
              final productId = product['id'] as int;
              final productName = product['product_name'] as String;
              final localPath = product['photo1'] as String;
              final localPath2 = product['photo2'] as String?;
              final localPath3 = product['photo3'] as String?;
              final itemDescription = product['description'] as Blob;

              final photoUrl1 = "https://haluansama.com/crm-sales/$localPath";
              final photoUrl2 = "https://haluansama.com/crm-sales/$localPath2";
              final photoUrl3 = "https://haluansama.com/crm-sales/$localPath3";

              final containerSize = (screenWidth - 40) / 2;

              return Container(
                padding: const EdgeInsets.only(
                    left: 12, right: 12, top: 10, bottom: 2),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        blurStyle: BlurStyle.normal,
                        color: const Color.fromARGB(75, 117, 117, 117),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 5),
                      ),
                    ]),
                child: Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemScreen(
                                productId: productId,
                                itemAssetNames: [
                                  photoUrl1,
                                  photoUrl2,
                                  photoUrl3
                                ],
                                productName: productName,
                                itemDescription: itemDescription,
                                priceByUom: product['price_by_uom'].toString(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: containerSize,
                          width: containerSize,
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 1,
                              color: Color.fromARGB(255, 0, 76, 135),
                            ),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: photoUrl1,
                            height: containerSize,
                            width: containerSize,
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error_outline),
                          ),
                        ),
                      ),
                      Container(
                        width: containerSize,
                        padding: EdgeInsets.only(top: 16),
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
                                      color:
                                          const Color.fromARGB(255, 25, 23, 49),
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
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
