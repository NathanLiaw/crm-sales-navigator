import 'dart:core';
import 'package:sales_navigator/db_connection.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UtilityFunction{
  static String calculateExpirationDate() {
    // Get today's date
    DateTime now = DateTime.now();

    // Calculate expiration date by adding 7 days
    DateTime expirationDate = now.add(Duration(days: 7));

    // Format expiration date in 'yyyy-mm-dd' format
    String formattedExpirationDate = '${expirationDate.year.toString().padLeft(4, '0')}-'
        '${expirationDate.month.toString().padLeft(2, '0')}-'
        '${expirationDate.day.toString().padLeft(2, '0')}';

    return formattedExpirationDate;
  }

  static Future<double> retrieveTax(String taxType) async {
    double defaultTaxInPercent = 0.0; // Default tax percentage (0.0 = 0%)

    try {
      MySqlConnection conn = await connectToDatabase();

      // Query tax table to retrieve tax_in_percent based on taxType and status=1
      final results = await readData(
        conn,
        'tax',
        '$taxType AND status = 1', // Use parameterized query to avoid SQL injection
        '', // Pass taxType as a parameter
        'tax_in_percent',
      );

      await conn.close();

      if (results.isNotEmpty) {
        // Retrieve tax_in_percent from the first row (assuming only one result expected)
        double taxInPercent = results[0]['tax_in_percent'] as double;

        // Calculate final tax percentage (divide taxInPercent by 100)
        double finalTaxPercent = taxInPercent / 100.0;

        return finalTaxPercent;
      } else {
        // If no tax data found, return the default tax percentage
        return defaultTaxInPercent;
      }
    } catch (e) {
      print('Error retrieving tax: $e');
      // Return default tax percentage or handle error as needed
      return defaultTaxInPercent;
    }
  }

  static String getCurrentDateTime() {
    DateTime now = DateTime.now();

    // Format date and time components
    String formattedDateTime = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    return formattedDateTime;
  }

  static Future<String> getAreaNameById(int id) async{
    String areaName = '';
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readData(
        conn,
        'area',
        'id="$id" AND status = 1',
        '',
        'area',
      );
      await conn.close();

      for (var row in results){
        areaName = row['area'];
      }

    } catch (e) {
      print('Error retrieving tax: $e');
    }

    return areaName;
  }

  static Future<int?> getUserId() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    int? userId = pref.getInt('id');
    return userId;
  }
}
