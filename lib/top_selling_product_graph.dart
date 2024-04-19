import 'package:flutter/material.dart';
import 'db_connection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const TopSellingProductsPage({super.key});

  @override
  _TopSellingProductsPageState createState() => _TopSellingProductsPageState();
}

class _TopSellingProductsPageState extends State<TopSellingProductsPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadTopProducts();
  }

  Future<void> _loadTopProducts() async {
    const String query = '''
      SELECT 
        product_name, 
        SUM(qty) AS total_qty_sold,
        SUM(total) AS total_sales
      FROM fyh.cart_item
      GROUP BY product_name
      ORDER BY total_qty_sold DESC
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
    final maxSales = products.fold<double>(0, (max, p) => p.salesOrder > max ? p.salesOrder : max);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Top Selling Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false, // Align the title to the left
      ),
body: products.isNotEmpty
    ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0), // Added padding
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9, // Adjusted height to take 90% of available height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 2), // changes position of shadow
              ),
            ],
          ),
          child: Center( // Center aligning the graph container
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(child: Text('Quantity', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(child: Text('Sales Order', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final barWidth = MediaQuery.of(context).size.width * (product.salesOrder / maxSales);

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5), // Adjusted padding
                        child: Stack(
                          children: <Widget>[
                            Container(
                              alignment: Alignment.centerLeft,
                              color: Colors.blue.withOpacity(0.2),
                              height: 55, // Adjusted height
                              width:barWidth,
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${product.quantity}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'RM${(product.salesOrder / 1000).toStringAsFixed(0)}K',
                                        textAlign: TextAlign.end,
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
}

class Product {
  String name;
  int quantity;
  double salesOrder;

  Product(this.name, this.quantity, this.salesOrder);
}
