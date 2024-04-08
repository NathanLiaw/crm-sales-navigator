import 'package:flutter/material.dart';
import 'db_connection.dart'; // Make sure to import your database connection function
import 'data_analytics_page.dart';
import 'package:mysql1/mysql1.dart';

void main() {
  runApp(MyApp());
  testDbConnection(); // Call this function to test the DB connection
}

void testDbConnection() async {
  try {
    // Attempt to open a connection to the database.
    var conn = await connectToDatabase();
    print('Connected to the MySQL server successfully!');
    // Close the connection when finished.
    await conn.close();
  } on MySqlException catch (e) {
    print('Failed to connect to the database. Error: ${e.message}');
  } on Exception catch (e) {
    print('An error occurred: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Data Analytics',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DataAnalyticsPage(),
    );
  }
}
