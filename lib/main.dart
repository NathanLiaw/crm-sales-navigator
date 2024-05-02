import 'package:flutter/material.dart';
import 'db_sqlite.dart';
import 'products_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  /* await DatabaseHelper.database; */

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ProductsScreen(),
    );
  }
}
