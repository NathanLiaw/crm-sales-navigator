import 'dart:core';
import 'package:sales_navigator/db_connection.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:developer' as developer;

class UtilityFunction{
  static String calculateExpirationDate() {
    // Initialize the time zone data
    tzdata.initializeTimeZones();

    // Specify the time zone for Kuala Lumpur
    final kualaLumpur = tz.getLocation('Asia/Kuala_Lumpur');

    // Get today's date in the Kuala Lumpur time zone
    final now = tz.TZDateTime.now(kualaLumpur);

    // Calculate expiration date by adding 7 days
    final expirationDate = now.add(const Duration(days: 7));

    // Format expiration date in 'yyyy-MM-dd' format
    String formattedExpirationDate = DateFormat('yyyy-MM-dd').format(expirationDate);

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
        "tax_title = '$taxType' AND status = 1",
        '',
        'tax_in_percent',
      );

      await conn.close();

      if (results.isNotEmpty) {
        // Retrieve tax_in_percent from the first row
        int taxInPercent = results[0]['tax_in_percent'];

        // Calculate final tax percentage (divide taxInPercent by 100)
        double finalTaxPercent = taxInPercent / 100.0;

        return finalTaxPercent;
      } else {
        // If no tax data found, return the default tax percentage
        return defaultTaxInPercent;
      }
    } catch (e, stackTrace) {
      developer.log('Error retrieving tax: $e', error: e, stackTrace: stackTrace);
      return defaultTaxInPercent;
    }
  }

  static String getCurrentDateTime() {
    // Initialize the time zone data
    tzdata.initializeTimeZones();

    // Specify the time zone for Kuala Lumpur
    final kualaLumpur = tz.getLocation('Asia/Kuala_Lumpur');

    // Get the current time in the Kuala Lumpur time zone
    final now = tz.TZDateTime.now(kualaLumpur);

    // Format date and time components
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    return formattedDateTime;
  }

  static Future<String> getAreaNameById(int id) async{
    String areaName = '';
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readData(
        conn,
        'area',
        "id='$id' AND status = 1",
        '',
        'area',
      );
      await conn.close();

      for (var row in results){
        areaName = row['area'];
      }

    } catch (e, stackTrace) {
      developer.log('Error retrieving area name: $e', error: e, stackTrace: stackTrace);
    }

    return areaName;
  }

  static Future<int> getUserId() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    int userId = pref.getInt('id') as int;
    return userId;
  }
}
