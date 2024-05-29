import 'package:flutter/material.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Forecast',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PredictedProductsTarget(),
    );
  }
}

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
    String query = '''
    SELECT 
      ci.product_name, 
      SUM(ci.qty) AS total_qty_sold,
      SUM(ci.qty * ci.unit_price) AS total_sales,
      s.salesman_name
    FROM 
      cart_item ci
    JOIN 
      cart c ON ci.session = c.session OR c.id = ci.cart_id
    JOIN 
      salesman s ON c.buyer_id = s.id
    WHERE 
      c.status != 'void' AND
      s.username = '$loggedInUsername' AND
      ci.created >= DATE_SUB(NOW(), INTERVAL 2 MONTH)
    GROUP BY 
      ci.product_name, 
      s.salesman_name
    ORDER BY 
      total_qty_sold DESC
    LIMIT 5;
  ''';

    try {
      final results = await executeQuery(query);
      final List<Product> fetchedProducts = results
          .map((row) => Product(
        row['product_name'] as String,
        (row['total_qty_sold'] as num).toInt(),
        (row['total_sales'] as num).toDouble(),
        0,
        0,
      ))
          .toList();

      setState(() {
        products = fetchedProducts;
        predictSalesAndStock();
      });
    } catch (e) {
      print('Error fetching top products: $e');
    }
  }

  void predictSalesAndStock() {
    int period = 2;

    for (var product in products) {
      double avgMonthlySales = product.salesOrder / period;
      double avgMonthlyQuantity = product.quantity / period;
      double predictedSales = avgMonthlySales;
      double predictedStock = avgMonthlyQuantity;

      if (product.salesOrder > avgMonthlySales) {
        double growthRate = product.salesOrder / avgMonthlySales;
        predictedSales = avgMonthlySales * growthRate;
        predictedStock = avgMonthlyQuantity * growthRate * 1.2;
      } else if (product.salesOrder < avgMonthlySales) {
        double lossRate = avgMonthlySales / product.salesOrder;
        predictedSales = avgMonthlySales / lossRate;
        predictedStock = avgMonthlyQuantity / lossRate * 1.2;
      }

      product.predictedSales = predictedSales.round();
      product.predictedStock = predictedStock.round();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQuantity =
    products.fold<int>(0, (max, p) => p.quantity > max ? p.quantity : max);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Product Forecast',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: products.isNotEmpty
          ? Padding(
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
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final double maxBarWidth =
                              MediaQuery.of(context).size.width * 0.8;
                          final double normalizedQuantity =
                              product.quantity / maxQuantity;
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
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class Product {
  String name;
  int quantity;
  double salesOrder;
  int predictedSales;
  int predictedStock;

  Product(this.name, this.quantity, this.salesOrder, this.predictedSales, this.predictedStock);

  String getFormattedSales() {
    final formatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 0);
    return formatter.format(predictedSales);
  }
}