import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'dart:developer' as developer;

class EventLogger {
  static Future<void> logEvent(
      int salesmanId, String activityDescription, String activityType,
      {int? leadId}) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      var result = await conn.query(
          'INSERT INTO event_log (salesman_id, activity_description, activity_type, datetime, lead_id) VALUES (?, ?, ?, NOW(), ?)',
          [salesmanId, activityDescription, activityType, leadId]);
      // developer.log('Event logged successfully. Inserted ID: ${result.insertId}');
    } catch (e) {
      developer.log('Error logging event: $e');
      developer.log('Attempted to log event with:');
      developer.log('Salesman ID: $salesmanId');
      developer.log('Activity Description: $activityDescription');
      developer.log('Activity Type: $activityType');
      developer.log('Lead ID: $leadId');
    } finally {
      await conn.close();
    }
  }
}
