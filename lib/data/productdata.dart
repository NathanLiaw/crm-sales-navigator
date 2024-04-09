import 'package:sales_navigator/db_connection.dart';
import 'package:mysql1/mysql1.dart';

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double price;

  Product(
      {required this.id,
      required this.name,
      required this.imageUrl,
      required this.price});
}
