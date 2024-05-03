import 'package:flutter/material.dart';
import 'db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Top Selling Products',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TopSellingProductsPage(),
    );
  }
}

class TopSellingProductsPage extends StatefulWidget {
  const TopSellingProductsPage({Key? key}) : super(key: key);

  @override
  _TopSellingProductsPageState createState() => _TopSellingProductsPageState();
}

class _TopSellingProductsPageState extends State<TopSellingProductsPage> {
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
LEFT JOIN 
    fyh.cart c ON ci.session = c.session OR ci.cart_id = c.id
JOIN 
    fyh.salesman s ON c.buyer_id = s.id
WHERE 
    c.status != 'void' AND
    s.username = '$loggedInUsername'
GROUP BY 
    ci.product_name, 
    s.salesman_name
ORDER BY 
    total_qty_sold DESC
LIMIT 5;
  ''';

    try {
      final results = await executeQuery(query);
      final List<Product> fetchedProducts = results.map((row) => Product(
            row['product_name'] as String,
            (row['total_qty_sold'] as num).toInt(),
            (row['total_sales'] as num).toDouble(),
          )).toList();

      setState(() {
        products = fetchedProducts;
      });
    } catch (e) {
      print('Error fetching top products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQuantity = products.fold<int>(
        0, (max, p) => p.quantity > max ? p.quantity : max);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Top Selling Products',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: products.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text('Product Name',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16))),
                            Expanded(
                                child: Text('Quantity',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16))),
                            Expanded(
                                child: Text('Sales Order',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
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
                                          horizontal: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              product.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${product.quantity}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              _formatSalesOrder(product.salesOrder),
                                              textAlign: TextAlign.end,
                                              style: TextStyle(fontWeight: FontWeight.w600),
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
          : const Center(child: CircularProgressIndicator()),
    );
  }

  String _formatSalesOrder(double salesOrder) {
    if (salesOrder >= 1000) {
      return 'RM ${(salesOrder / 1000).toStringAsFixed(1)}K';
    } else {
      return 'RM ${salesOrder.toStringAsFixed(0)}';
    }
  }
}

class Product {
  String name;
  int quantity;
  double salesOrder;

  Product(this.name, this.quantity, this.salesOrder);
}
