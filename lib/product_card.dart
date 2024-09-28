import 'package:flutter/material.dart';
import 'package:sales_navigator/item_screen.dart';
import 'package:sales_navigator/order_details_page.dart';
// ignore: depend_on_referenced_packages
import 'package:cached_network_image/cached_network_image.dart';
import 'db_connection.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int? areaId;

  const ProductCard({super.key, required this.product, required this.areaId});

  Future<Map<String, dynamic>> _fetchProductDetails(
      int productId, int areaId) async {
    final conn = await connectToDatabase();
    try {
      var results = await conn.query(
        'SELECT description, uom, price_by_uom FROM product WHERE id = ?',
        [productId],
      );

      if (results.isNotEmpty) {
        var row = results.first;
        return {
          'description': row['description'],
          'uom': row['uom'],
          'price_by_uom': row['price_by_uom'],
        };
      } else {
        return {
          'description': 'No description available.',
          'uom': '',
          'price_by_uom': '',
        };
      }
    } catch (e) {
      return {
        'description': 'Error fetching details.',
        'uom': '',
        'price_by_uom': '',
      };
    } finally {
      await conn.close();
    }
  }

  String _formatImageUrl(String? url) {
    if (url != null && url.isNotEmpty && url.startsWith('photo/')) {
      return 'https://haluansama.com/crm-sales/$url';
    }
    return url ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final photoUrl1 = _formatImageUrl(product['photo1']);
    final photoUrl2 = _formatImageUrl(product['photo2']);
    final photoUrl3 = _formatImageUrl(product['photo3']);

    // Filter out any null or empty URLs
    final List<String> photoUrls = [photoUrl1, photoUrl2, photoUrl3]
        .where((url) => url.isNotEmpty)
        .toList();

    return GestureDetector(
      onTap: () async {
        int productId = product['id'];
        Map<String, dynamic> productDetails =
            await _fetchProductDetails(productId, areaId ?? -1);

        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => ItemScreen(
              productId: productId,
              productName: product['product_name'],
              itemAssetNames: photoUrls,
              itemDescription: productDetails['description'],
              priceByUom: productDetails['price_by_uom'].toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: mediaQuery.size.height * 0.01,
          horizontal: mediaQuery.size.width * 0.02,
        ),
        padding: EdgeInsets.all(mediaQuery.size.width * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // ignore: deprecated_member_use
            double fontSize = mediaQuery.textScaleFactor * 18;
            // ignore: deprecated_member_use
            while (fontSize > mediaQuery.textScaleFactor * 16) {
              final textPainter = TextPainter(
                text: TextSpan(
                  text: product['product_name'],
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              if (textPainter.didExceedMaxLines) {
                fontSize -= 1;
              } else {
                break;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photoUrl1.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl1,
                      height: mediaQuery.size.height * 0.2,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'asset/no_image.jpg',
                        height: mediaQuery.size.height * 0.2,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(height: mediaQuery.size.height * 0.01),
                Text(
                  product['product_name'],
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product['price_by_uom'] != null) ...[
                  SizedBox(height: mediaQuery.size.height * 0.01),
                  Text(
                    product['price_by_uom'],
                    style: TextStyle(
                      // ignore: deprecated_member_use
                      fontSize: mediaQuery.textScaleFactor * 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class SalesOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const SalesOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(cartID: order['order_id']),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(13.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                        text: 'Sales Order Id: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: '${order['order_id']}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                        text: 'Customer Name: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: '${order['company_name']}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                        text: 'Created on: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: '${order['created_date']}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                        text: 'Order Status: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: '${order['status']}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                        text: 'Total: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: 'RM ${order['total']}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(),
                  columnWidths: {
                    0: FixedColumnWidth(mediaQuery.size.width * 0.4),
                    1: FixedColumnWidth(mediaQuery.size.width * 0.2),
                    2: FixedColumnWidth(mediaQuery.size.width * 0.2),
                    3: FixedColumnWidth(mediaQuery.size.width * 0.2),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Colors.white),
                      children: [
                        _buildTableCell('Product', isHeader: true),
                        _buildTableCell('Qty', isHeader: true),
                        _buildTableCell('Unit Price', isHeader: true),
                      ],
                    ),
                    ...order['items'].map<TableRow>((item) {
                      return TableRow(
                        decoration: const BoxDecoration(color: Colors.white),
                        children: [
                          _buildTableCell(item['product_name']),
                          _buildTableCell('${item['qty']} pcs'),
                          _buildTableCell('RM ${item['unit_price']}'),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String content, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}