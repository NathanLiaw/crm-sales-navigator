import 'package:flutter/material.dart';
// import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/data_analytics_page.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/login_page.dart';
import 'package:sales_navigator/order_details_page.dart';
// import 'package:sales_navigator/product_page.dart';
import 'package:sales_navigator/profile_page.dart';
// import 'package:sales_navigator/sales_page.dart';
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
        '/sales': (context) => DataAnalyticsPage(),
        // '/product': (context) => ProductPage(),
        // '/cart': (context) => CartPage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}