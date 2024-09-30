import 'package:sales_navigator/home_page.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "fetchSalesOrderStatus":
        await checkOrderStatusAndNotify();
        break;
      case "checkTaskDueDates":
        await checkTaskDueDatesAndNotify();
        break;
      case "checkNewSalesLeads":
        await checkNewSalesLeadsAndNotify();
        break;
    }
    return Future.value(true);
  });
}

Future<void> checkOrderStatusAndNotify() async {
  developer.log('Starting checkOrderStatusAndNotify');

  try {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/background_tasks/get_order_status.php');
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        for (var row in jsonData['data']) {
          var orderId = row['id'];
          var customerName = row['customer_company_name'];
          var salesmanId = row['buyer_id'];
          var currentStatus = row['status'];
          var lastCheckedStatus = row['last_checked_status'];

          if (orderId == null ||
              customerName == null ||
              currentStatus == null ||
              lastCheckedStatus == null) {
            developer.log('Skipping row due to null values');
            continue;
          }

          if (currentStatus != lastCheckedStatus) {
            developer.log(
                'Status changed from $lastCheckedStatus to $currentStatus for order $orderId');
            await _generateNotification(
                LeadItem(
                  id: orderId,
                  salesmanId: salesmanId,
                  customerName: customerName,
                  description: '',
                  createdDate: DateTime.now().toString(),
                  amount: '',
                  contactNumber: '',
                  emailAddress: '',
                  stage: '',
                  addressLine1: '',
                  status: currentStatus,
                ),
                currentStatus, // newStatus
                lastCheckedStatus // oldStatus
                );
          } else {
            developer.log('No status change for order $orderId');
          }
        }
      } else {
        developer.log('Error: ${jsonData['message']}');
      }
    } else {
      developer.log('Failed to load order status');
    }
  } catch (e) {
    developer.log('Error in checkOrderStatusAndNotify: $e');
  }
  developer.log('Finished checkOrderStatusAndNotify');
}

Future<void> checkTaskDueDatesAndNotify() async {
  developer.log('Starting checkTaskDueDatesAndNotify');

  try {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/background_tasks/get_task_due_dates.php');
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        for (var row in jsonData['data']) {
          var taskTitle = row['title'];
          var dueDate = DateTime.parse(row['due_date']);
          var leadId = row['lead_id'];
          var salesmanId = row['salesman_id'];
          var customerName = row['customer_name'];

          var notificationTitle = 'Task Due Soon';
          var notificationBody =
              'Task "$taskTitle" for $customerName is due on ${dueDate.toString().split(' ')[0]}';

          await _generateTaskandSalesLeadNotification(
              salesmanId,
              'Task Due Soon',
              'Task "$taskTitle" for $customerName is due on ${dueDate.toString().split(' ')[0]}',
              leadId,
              'TASK_DUE_SOON');
        }
      } else {
        developer.log('Error: ${jsonData['message']}');
      }
    } else {
      developer.log('Failed to load task due dates');
    }
  } catch (e) {
    developer.log('Error in checkTaskDueDatesAndNotify: $e');
  }
  developer.log('Finished checkTaskDueDatesAndNotify');
}

Future<void> checkNewSalesLeadsAndNotify() async {
  developer.log('Starting checkNewSalesLeadsAndNotify');

  try {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/background_tasks/get_new_sales_leads.php');
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        for (var row in jsonData['data']) {
          var leadId = row['id'];
          var customerName = row['customer_name'];
          var salesmanId = row['salesman_id'];

          var notificationTitle = 'New Sales Lead';
          var notificationBody =
              'A new sales lead for $customerName has been created today.';

          await _generateTaskandSalesLeadNotification(salesmanId,
              notificationTitle, notificationBody, leadId, 'NEW_SALES_LEAD');
        }
      } else {
        developer.log('Error: ${jsonData['message']}');
      }
    } else {
      developer.log('Failed to load new sales leads');
    }
  } catch (e) {
    developer.log('Error in checkNewSalesLeadsAndNotify: $e');
  }
  developer.log('Finished checkNewSalesLeadsAndNotify');
}

// Generate status change notification
Future<void> _generateNotification(
    LeadItem leadItem, String newStatus, String oldStatus) async {
  try {
    // API URL for generating notifications
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/background_tasks/update_notification.php');

    // Prepare the POST request
    final response = await http.post(apiUrl, body: {
      'salesmanId': leadItem.salesmanId.toString(),
      'title': 'Order Status Changed',
      'description':
          'Order for ${leadItem.customerName} has changed from $oldStatus to $newStatus.',
      'relatedLeadId': leadItem.id.toString(),
      'type': 'ORDER_STATUS_CHANGED',
    });

    // Handle the response
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        await showLocalNotification(
          'Order Status Changed',
          'Order for ${leadItem.customerName} has changed from $oldStatus to $newStatus.',
        );
        developer.log('Notification sent: ${jsonData['message']}');
      } else {
        developer.log('Error generating notification: ${jsonData['message']}');
      }
    } else {
      developer.log('Failed to generate notification');
    }
  } catch (e) {
    developer.log('Error generating notification: $e');
  }
}

Future<void> _generateTaskandSalesLeadNotification(int salesmanId, String title,
    String description, int leadId, String type) async {
  try {
    // API URL for generating task/lead notifications
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/background_tasks/update_task_lead_notification.php');

    // Prepare the POST request
    final response = await http.post(apiUrl, body: {
      'salesmanId': salesmanId.toString(),
      'title': title,
      'description': description,
      'leadId': leadId.toString(),
      'type': type,
    });

    // Handle the response
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        await showLocalNotification(title, description);
        developer.log('Notification sent: ${jsonData['message']}');
      } else {
        developer.log('Error generating notification: ${jsonData['message']}');
      }
    } else {
      developer.log('Failed to generate notification');
    }
  } catch (e) {
    developer.log('Error generating task/lead notification: $e');
  }
}

Future<void> showLocalNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
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
}
