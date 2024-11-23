import 'dart:core';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/data/db_sqlite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UtilityFunction {
  static String calculateExpirationDate() {
    // Initialize the time zone data
    tzdata.initializeTimeZones();

    // Specify the time zone for Kuala Lumpur
    final kualaLumpur = tz.getLocation('Asia/Kuala_Lumpur');

    // Get today's date in the Kuala Lumpur time zone
    final now = tz.TZDateTime.now(kualaLumpur);

    final expirationDate = now.add(const Duration(days: 7));

    String formattedExpirationDate =
        DateFormat('yyyy-MM-dd').format(expirationDate);

    return formattedExpirationDate;
  }

  static Future<double> retrieveTax(String taxType) async {
    double defaultTaxInPercent = 0.0;
    String apiUrl = '${dotenv.env['API_URL']}/utility_function/get_tax.php';

    try {
      final Uri apiUri = Uri.parse('$apiUrl?tax_type=$taxType');
      final response = await http.get(apiUri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          int taxInPercent = data['tax_in_percent'] ?? 0;

          double finalTaxPercent = taxInPercent / 100.0;

          return finalTaxPercent;
        } else {
          developer.log('Error retrieving tax: ${data['message']}');
          return defaultTaxInPercent;
        }
      } else {
        developer
            .log('Failed to retrieve tax, status code: ${response.statusCode}');
        return defaultTaxInPercent;
      }
    } catch (e, stackTrace) {
      developer.log('Error retrieving tax: $e',
          error: e, stackTrace: stackTrace);
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

    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    return formattedDateTime;
  }

  // Retrieve area name by ID from the API
  static Future<String> getAreaNameById(int id) async {
    String areaName = '';
    String apiUrl = '${dotenv.env['API_URL']}/utility_function/get_area.php';

    try {
      final Uri apiUri = Uri.parse('$apiUrl?id=$id');
      final response = await http.get(apiUri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          areaName = data['area'];
        } else {
          developer.log('Error retrieving area name: ${data['message']}');
        }
      } else {
        developer.log(
            'Failed to retrieve area name, status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log('Error retrieving area name: $e',
          error: e, stackTrace: stackTrace);
    }

    return areaName;
  }

  static Future<int> getUserId() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    int userId = pref.getInt('id') as int;
    return userId;
  }

  static Blob stringToBlob(String data) {
    Blob blob = Blob.fromString(data);

    return blob;
  }

  static Future<int> getNumberOfItemsInCart() async {
    final userId = await UtilityFunction.getUserId();

    try {
      const tableName = 'cart_item';
      final condition = "buyer_id = $userId AND status = 'in progress'";

      final db = await DatabaseHelper.database;

      final itemCount = await DatabaseHelper.countData(
        db,
        tableName,
        condition,
      );

      return itemCount;
    } catch (e) {
      developer.log('Error fetching count of cart items: $e', error: e);
      return 0;
    }
  }
}
