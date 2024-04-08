import 'package:flutter/material.dart';
import 'db_connection.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Top Selling Products',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TopSellingProductsPage(),
    );
  }
}

class TopSellingProductsPage extends StatefulWidget {
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
        title: Text(
          'Top Selling Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false, // Align the title to the left
      ),
      body: products.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // Added padding
              child: Container(
                height: MediaQuery.of(context).size.height * 0.52, // Adjusted height to fit 5 products
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Expanded(child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Quantity', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Sales Order', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        physics: NeverScrollableScrollPhysics(), // Disable scrolling
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final barWidth = MediaQuery.of(context).size.width * (product.salesOrder / maxSales);

                          return Container(
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), // Adjusted padding
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  alignment: Alignment.centerLeft,
                                  color: Colors.blue.withOpacity(0.2),
                                  height: 55, // Adjusted height
                                  width: barWidth,
                                ),
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            product.name,
                                            style: TextStyle(fontWeight: FontWeight.bold),
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
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class Product {
  String name;
  int quantity;
  double salesOrder;

  Product(this.name, this.quantity, this.salesOrder);
}
