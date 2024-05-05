import 'package:flutter/material.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/edit_item_page.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/login_page.dart';
import 'package:sales_navigator/order_submitted_page.dart';
import 'package:sales_navigator/profile_page.dart';
import 'package:sales_navigator/sales_order.dart';
import 'db_sqlite.dart';
import 'products_screen.dart';
import 'item_variations_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  await DatabaseHelper.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      routes: {
        '/home': (context) => HomePage(),
        '/sales': (context) => SalesOrderPage(),
        '/product': (context) => ProductsScreen(),
        '/cart': (context) => CartPage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}