import 'package:sales_navigator/screens/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Get the logged-in salesman_id
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? salesmanId = prefs.getInt('id');

    if (salesmanId == null) {
      return Future.value(true);
    }

    switch (task) {
      case "fetchSalesOrderStatus":
        await checkOrderStatusAndNotify(salesmanId);
        break;
      case "checkTaskDueDates":
        await checkTaskDueDatesAndNotify(salesmanId);
        break;
      case "checkNewSalesLeads":
        await checkNewSalesLeadsAndNotify(salesmanId);
        break;
    }
    return Future.value(true);
  });
}

Future<void> checkOrderStatusAndNotify(int salesmanId) async {
  final String baseUrl =
      '${dotenv.env['API_URL']}/background_tasks/get_order_status.php?salesman_id=$salesmanId';

  try {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        final notifications = responseData['notifications'] as List;
        for (var notification in notifications) {
          await showLocalNotification(
            'Order Status Changed',
            'Order ${notification['order_id']} for ${notification['customer_name']} has changed from ${notification['old_status']} to ${notification['new_status']}.',
          );
        }
        developer.log('Notifications processed: ${notifications.length}');
      } else {
        throw Exception(responseData['message']);
      }
    } else {
      throw Exception('Failed to check order status: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error checking order status and notifying: $e');
  }
}

Future<void> checkTaskDueDatesAndNotify(int salesmanId) async {
  developer.log('Starting checkTaskDueDatesAndNotify');

  try {
    final apiUrl = Uri.parse(
        '${dotenv.env['API_URL']}/background_tasks/get_task_due_dates.php?salesman_id=$salesmanId');
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        for (var row in jsonData['data']) {
          var taskTitle = row['title'];
          var dueDate = DateTime.parse(row['due_date']);
          var leadId = row['lead_id'].toString();
          var salesmanId = row['salesman_id'].toString();
          var customerName = row['customer_name'];

          var notificationTitle = 'Task Due Soon';
          var notificationBody =
              'Task "$taskTitle" for $customerName is due on ${dueDate.toString().split(' ')[0]}';

          await _generateTaskandSalesLeadNotification(
              int.parse(salesmanId),
              notificationTitle,
              notificationBody,
              int.parse(leadId),
              'TASK_DUE_SOON');
        }
      } else {
        developer.log('Error: ${jsonData['message']}');
      }
    } else {
      throw Exception('Failed to load task due dates: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error in checkTaskDueDatesAndNotify: $e');
  }
  developer.log('Finished checkTaskDueDatesAndNotify');
}

Future<void> checkNewSalesLeadsAndNotify(int salesmanId) async {
  developer
      .log('Starting checkNewSalesLeadsAndNotify for salesman_id: $salesmanId');

  try {
    final apiUrl = Uri.parse(
        '${dotenv.env['API_URL']}/background_tasks/get_new_sales_leads.php?salesman_id=$salesmanId');
    developer.log("Calling API with URL: $apiUrl");
    final response = await http.get(apiUrl);

    developer.log("API Response Status Code: ${response.statusCode}");
    developer.log("API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        developer.log('Found ${jsonData['data'].length} new sales leads today');

        for (var lead in jsonData['data']) {
          var leadId = lead['id'].toString();
          var customerName = lead['customer_name'];
          var salesmanId = lead['salesman_id'].toString();

          var notificationTitle = 'New Sales Lead';
          var notificationBody =
              'A new sales lead for $customerName has been created today.';

          await _generateTaskandSalesLeadNotification(
              int.parse(salesmanId),
              notificationTitle,
              notificationBody,
              int.parse(leadId),
              'NEW_SALES_LEAD');
        }
      } else {
        developer.log('Error: ${jsonData['message']}');
      }
    } else {
      throw Exception('Failed to load new sales leads: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error in checkNewSalesLeadsAndNotify: $e');
  }
  developer.log('Finished checkNewSalesLeadsAndNotify');
}

// Generate status change notification
Future<void> _generateNotification(
    LeadItem leadItem, String newStatus, String oldStatus) async {
  String baseUrl =
      '${dotenv.env['API_URL']}/background_tasks/update_notification.php';

  if (leadItem.salesOrderId == null) {
    return;
  }

  final Map<String, String> queryParameters = {
    'order_id': leadItem.salesOrderId!,
    'salesman_id': leadItem.salesmanId.toString(),
    'customer_name': leadItem.customerName,
    'new_status': newStatus,
    'old_status': oldStatus,
  };

  final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        developer.log('Notification generated successfully');

        String notificationMessage = leadItem.salesOrderId != null
            ? 'Order #${leadItem.salesOrderId} for ${leadItem.customerName} has changed from $oldStatus to $newStatus.'
            : 'Order for ${leadItem.customerName} has changed from $oldStatus to $newStatus.';

        await showLocalNotification(
            'Order Status Changed', notificationMessage);
      } else {
        throw Exception(responseData['message']);
      }
    } else {
      throw Exception(
          'Failed to generate notification: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error generating notification: $e');
  }
}

Future<void> _generateTaskandSalesLeadNotification(int salesmanId, String title,
    String description, int leadId, String type) async {
  String baseUrl =
      '${dotenv.env['API_URL']}/background_tasks/update_task_lead_notification.php';

  final Map<String, String> queryParameters = {
    'salesman_id': salesmanId.toString(),
    'title': title,
    'description': description,
    'lead_id': leadId.toString(),
    'type': type,
  };

  final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        developer.log('Notification generated successfully');

        await showLocalNotification(title, description);
      } else {
        throw Exception(responseData['message']);
      }
    } else {
      throw Exception(
          'Failed to generate notification: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error generating task notification: $e');
  }
}

Future<void> showLocalNotification(String title, String body) async {
  if (await Permission.notification.isGranted) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sales_navigator_notifications',
      'Sales Navigator Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'notification',
    );
  } else {
    await Permission.notification.request();
    developer.log('Notification permission was requested.');
  }
}
