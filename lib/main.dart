import 'package:flutter/material.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/login_page.dart';
import 'package:sales_navigator/profile_page.dart';
import 'package:sales_navigator/sales_order.dart';
import 'db_sqlite.dart';
import 'products_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the SQLite database
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
        '/home': (context) => const HomePage(),
        '/sales': (context) => const SalesOrderPage(),
        '/product': (context) => const ProductsScreen(),
        '/cart': (context) => const CartPage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
