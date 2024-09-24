import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';

class EventLogger {
  static Future<void> logEvent(
      int salesmanId, String activityDescription, String activityType,
      {int? leadId}) async {
    MySqlConnection conn = await connectToDatabase();
    try {
      var result = await conn.query(
          'INSERT INTO event_log (salesman_id, activity_description, activity_type, datetime, lead_id) VALUES (?, ?, ?, NOW(), ?)',
          [salesmanId, activityDescription, activityType, leadId]);
      print('Event logged successfully. Inserted ID: ${result.insertId}');
    } catch (e) {
      print('Error logging event: $e');
      print('Attempted to log event with:');
      print('Salesman ID: $salesmanId');
      print('Activity Description: $activityDescription');
      print('Activity Type: $activityType');
      print('Lead ID: $leadId');
    } finally {
      await conn.close();
    }
  }
}
