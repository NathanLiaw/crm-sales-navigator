import 'package:sales_navigator/db_connection.dart';
import 'package:mysql1/mysql1.dart';

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  static Future<List<Product>> fetchProducts() async {
    List<Product> products = [];
    MySqlConnection conn = await connectToDatabase();

    try {
      Results result = await conn.query('SELECT * FROM products');
      for (var row in result) {
        products.add(Product(
          id: row['id'] ?? '',
          name: row['name'] ?? '',
          imageUrl: row['image_url'] ?? '',
          price: row['price'] ?? 0.0,
        ));
      }
    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      await conn.close();
    }

    return products;
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, imageUrl: $imageUrl, price: $price}';
  }
}

void main() async {
  List<Product> products = await Product.fetchProducts();
  for (Product product in products) {
    print(product);
  }
}
