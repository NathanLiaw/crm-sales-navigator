import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EventLogger {
  static Future<void> logEvent(
      int salesmanId, String activityDescription, String activityType,
      {int? leadId}) async {
    final apiUrl =
        Uri.parse('${dotenv.env['API_URL']}/event_logger/update_log_event.php');

    try {
      final Map<String, String> requestBody = {
        'salesmanId': salesmanId.toString(),
        'activityDescription': activityDescription,
        'activityType': activityType,
      };

      if (leadId != null) {
        requestBody['leadId'] = leadId.toString();
      }

      developer.log('Sending event log request: $requestBody');

      final response = await http.post(apiUrl, body: requestBody);

      if (response.body.isEmpty) {
        developer.log('Empty response received from server');
        return;
      }

      try {
        final responseData = json.decode(response.body);
        developer.log('Event log response: $responseData');

        if (response.statusCode == 200) {
          if (responseData['status'] == 'success') {
            developer.log('Event logged successfully');
          } else {
            developer.log('Error logging event: ${responseData['message']}');
          }
        } else {
          developer
              .log('Failed to log event. Server error: ${response.statusCode}');
        }
      } catch (e) {
        developer.log('Error parsing response: ${response.body}', error: e);
      }
    } catch (e) {
      developer.log('Error logging event', error: e);
    }
  }
}
