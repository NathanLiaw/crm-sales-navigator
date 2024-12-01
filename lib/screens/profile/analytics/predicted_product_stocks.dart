// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PredictedProductsTarget extends StatefulWidget {
  const PredictedProductsTarget({super.key});

  @override
  _PredictedProductsTargetState createState() =>
      _PredictedProductsTargetState();
}

class _PredictedProductsTargetState extends State<PredictedProductsTarget> {
  List<Product> products = [];
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails().then((_) {
      _loadTopProducts();
    });
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? '';
    });
  }

  Future<void> _loadTopProducts() async {
    if (loggedInUsername.isEmpty) {
      return;
    }

    final apiUrl = Uri.parse(
        '${dotenv.env['API_URL']}/predict_product_stock/get_predict_product.php?username=$loggedInUsername');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> productData = jsonData['data'];

          final List<Product> fetchedProducts = productData.map((row) {
            return Product(
              row['product_name'] as String,
              (row['total_qty_sold'] as num).toInt(),
              (row['total_sales'] as num).toDouble(),
              0,
              0,
            );
          }).toList();

          setState(() {
            products = fetchedProducts;
            predictSalesAndStockEMA(products, 3);
          });
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      developer.log('Error fetching top products: $e');
    }
  }

  void predictSalesAndStockEMA(List<Product> data, int windowSize) {
    if (data.isEmpty || windowSize <= 1) return;

    double alpha = 2 / (windowSize + 1);

    for (var product in data) {
      double emaSales = product.salesOrder;
      double emaStock = product.quantity.toDouble();

      for (int i = 1; i < windowSize; i++) {
        emaSales = (product.salesOrder * alpha) + (emaSales * (1 - alpha));
        emaStock = (product.quantity * alpha) + (emaStock * (1 - alpha));
      }

      product.predictedSales = emaSales.round();
      product.predictedStock = emaStock > 0 ? emaStock.round() : 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQuantity =
        products.fold<int>(0, (max, p) => p.quantity > max ? p.quantity : max);

    final displayedProducts = products.isNotEmpty
        ? products
        : List.generate(5, (index) => Product('No Product', 0, 0.0, 0, 0));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Product Forecast',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Product Name',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Predicted Stocks',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Predicted Sales',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: displayedProducts.length,
                        itemBuilder: (context, index) {
                          final product = displayedProducts[index];
                          final double maxBarWidth =
                              MediaQuery.of(context).size.width * 0.8;
                          final double normalizedQuantity = maxQuantity != 0
                              ? product.quantity / maxQuantity
                              : 0.0;
                          final double barWidth =
                              normalizedQuantity * maxBarWidth;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 5),
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  alignment: Alignment.centerLeft,
                                  color: Colors.blue.withOpacity(0.2),
                                  height: 53,
                                  width: barWidth,
                                ),
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            product.name,
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '${product.predictedStock}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            product.getFormattedSales(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.shade300,
                          height: 1,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Product {
  String name;
  int quantity;
  double salesOrder;
  int predictedSales;
  int predictedStock;

  Product(this.name, this.quantity, this.salesOrder, this.predictedSales,
      this.predictedStock);

  String getFormattedSales() {
    final formatter =
        NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 0);
    return formatter.format(predictedSales);
  }
}
