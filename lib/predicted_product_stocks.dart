import 'package:flutter/material.dart';
import 'db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const PredictedProductsTarget({Key? key}) : super(key: key);

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
  fyh.cart_item ci
JOIN 
  fyh.cart c ON ci.session = c.session OR c.id = ci.cart_id
JOIN 
  fyh.salesman s ON c.buyer_id = s.id
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
        predictSalesAndStock();  // Calculate predictions
      });
    } catch (e) {
      print('Error fetching top products: $e');
    }
  }

  void predictSalesAndStock() {
  int period = 2;  // We have 2 months of historical data
  
  for (var product in products) {
    // Calculate average monthly sales and quantity
    double avgMonthlySales = product.salesOrder / period;
    double avgMonthlyQuantity = product.quantity / period;

    // Assuming a growth rate based on some business logic or previous trend analysis; here a placeholder of 5% growth
    double growthRate = 1.05; // 5% growth

    // Project next month's sales and quantity based on the average and assumed growth
    product.predictedSales = (avgMonthlySales * growthRate).round();
    product.predictedStock = (avgMonthlyQuantity * growthRate * 1.2).round();  // 20% buffer on top of the predicted sales
  }
}


  @override
  @override
Widget build(BuildContext context) {
  final maxQuantity =
      products.fold<int>(0, (max, p) => p.quantity > max ? p.quantity : max);

  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      title: Padding(
        padding: const EdgeInsets.only(
          left: 0.0,
          top: 28.0,
          bottom: 16.0,
        ),
        child: const Text(
          'Product Forecast',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
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
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Product Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                                fontSize: 16,
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
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
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
                                  height: 55,
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
                                            style: TextStyle(
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
                                            style:
                                                TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'RM ${product.predictedSales}',
                                            textAlign: TextAlign.center,
                                            style:
                                                TextStyle(fontWeight: FontWeight.w600),
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
                    ),
                  ],
                ),
              ),
            ),
          )
        : Center(child: CircularProgressIndicator()),
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
}
