import 'package:flutter/material.dart';
import 'package:sales_navigator/Cart.dart';
import 'package:sales_navigator/HomePage.dart';
import 'package:sales_navigator/LoginPage.dart';
import 'package:sales_navigator/ProductPage.dart';
import 'package:sales_navigator/ProfilePage.dart';
import 'package:sales_navigator/SalesPage.dart';
// import 'package:sales_navigator/cart_item_sqlite.dart';

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await DatabaseHelper.importCartItemData();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      routes: {
        '/home': (context) => HomePage(),
        '/sales': (context) => SalesPage(),
        '/product': (context) => ProductPage(),
        '/cart': (context) => CartPage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
