import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

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
  MySqlConnection? conn;
  developer.log('Starting checkOrderStatusAndNotify');
  try {
    conn = await connectToDatabase();
    var results = await conn.query('''
  SELECT id, customer_company_name, buyer_id, status, last_checked_status 
  FROM cart 
  WHERE id IS NOT NULL 
    AND customer_company_name IS NOT NULL 
    AND status IS NOT NULL 
    AND last_checked_status IS NOT NULL
''');
    developer.log('Found ${results.length} cart items');

    for (var row in results) {
      // developer.log('Raw row data: $row');
      var orderId = row['id'];
      var customerName = row['customer_company_name'] as String?;
      var salesmanId = row['buyer_id'] as int?;
      var currentStatus = row['status'];
      var lastCheckedStatus = row['last_checked_status'];

      // developer.log(
      //     'Processing order: $orderId, Current status: $currentStatus, Last checked status: $lastCheckedStatus');
      // developer.log('orderId: $orderId, type: ${orderId.runtimeType}');
      // developer.log('salesmanId: $salesmanId, type: ${salesmanId.runtimeType}');

      if (orderId == null ||
          customerName == null ||
          currentStatus == null ||
          lastCheckedStatus == null) {
        developer.log('Skipping row due to null values');
        continue;
      }

      developer.log(
          'Processing order: $orderId, Current status: $currentStatus, Last checked status: $lastCheckedStatus');

      if (currentStatus != lastCheckedStatus) {
        developer.log(
            'Status changed from $lastCheckedStatus to $currentStatus for order $orderId');
        await _generateNotification(
            conn,
            LeadItem(
              id: orderId as int,
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
            currentStatus,
            lastCheckedStatus);

        // Update last_checked_status
        await conn.query('UPDATE cart SET last_checked_status = ? WHERE id = ?',
            [currentStatus, orderId]);
        developer.log('Updated last_checked_status in database for order $orderId');
      } else {
        developer.log('No status change for order $orderId');
      }
    }
  } catch (e) {
    developer.log('Error in checkOrderStatusAndNotify: $e');
  } finally {
    if (conn != null) {
      await conn.close();
    }
  }
  developer.log('Finished checkOrderStatusAndNotify');
}

Future<void> checkTaskDueDatesAndNotify() async {
  MySqlConnection? conn;
  developer.log('Starting checkTaskDueDatesAndNotify');
  try {
    conn = await connectToDatabase();
    developer.log('Connected to database');

    var results = await conn.query('''
      SELECT t.id, t.title, t.due_date, t.lead_id, sl.salesman_id, sl.customer_name
      FROM tasks t
      JOIN sales_lead sl ON t.lead_id = sl.id
      WHERE t.creation_date >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        AND t.due_date <= DATE_ADD(NOW(), INTERVAL 24 HOUR)
        AND t.due_date > NOW()
    ''');

    developer.log('Found ${results.length} tasks with upcoming due dates');

    for (var row in results) {
      var taskTitle = row['title'] as String;
      var dueDate = row['due_date'] as DateTime;
      var leadId = row['lead_id'] as int;
      var salesmanId = row['salesman_id'] as int;
      var customerName = row['customer_name'] as String;

      var notificationTitle = 'Task Due Soon';
      var notificationBody =
          'Task "$taskTitle" for $customerName is due on ${dueDate.toString().split(' ')[0]}';

      await _generateTaskandSalesLeadNotification(conn, salesmanId,
          notificationTitle, notificationBody, leadId, 'TASK_DUE_SOON');
    }
  } catch (e) {
    developer.log('Error in checkTaskDueDatesAndNotify: $e');
  } finally {
    if (conn != null) {
      await conn.close();
    }
  }
  developer.log('Finished checkTaskDueDatesAndNotify');
}

Future<void> checkNewSalesLeadsAndNotify() async {
  MySqlConnection? conn;
  developer.log('Starting checkNewSalesLeadsAndNotify');
  try {
    conn = await connectToDatabase();
    developer.log('Connected to database');

    var results = await conn.query('''
      SELECT id, customer_name, salesman_id
      FROM sales_lead
      WHERE DATE(created_date) = CURDATE()
    ''');

    developer.log('Found ${results.length} new sales leads today');

    for (var row in results) {
      var leadId = row['id'] as int;
      var customerName = row['customer_name'] as String;
      var salesmanId = row['salesman_id'] as int;

      var notificationTitle = 'New Sales Lead';
      var notificationBody =
          'A new sales lead for $customerName has been created today.';

      await _generateTaskandSalesLeadNotification(conn, salesmanId,
          notificationTitle, notificationBody, leadId, 'NEW_SALES_LEAD');
    }
  } catch (e) {
    developer.log('Error in checkNewSalesLeadsAndNotify: $e');
  } finally {
    if (conn != null) {
      await conn.close();
    }
  }
  developer.log('Finished checkNewSalesLeadsAndNotify');
}

// Generate status change notification
Future<void> _generateNotification(MySqlConnection conn, LeadItem leadItem,
    String newStatus, String oldStatus) async {
  try {
    // Find the corresponding record in the sales_lead table
    var salesLeadResults = await conn.query(
      'SELECT id FROM sales_lead WHERE so_id = ?',
      [leadItem.id], // Use orderId (leadItem.id) to find
    );

    int? salesLeadId;
    if (salesLeadResults.isNotEmpty) {
      salesLeadId = salesLeadResults.first['id'] as int;
    } else {
      // If it is not found, an error is reported,
      throw Exception('No sales_lead record found for order ${leadItem.id}');
    }

    // Insert data into notifications table
    var result = await conn.query(
      'INSERT INTO notifications (salesman_id, title, description, related_lead_id, type) VALUES (?, ?, ?, ?, ?)',
      [
        leadItem.salesmanId ?? 0,
        'Order Status Changed',
        'Order for ${leadItem.customerName} has changed from $oldStatus to $newStatus.',
        salesLeadId,
        'ORDER_STATUS_CHANGED',
      ],
    );
    developer.log(
        'Inserted notification into database. Affected rows: ${result.affectedRows}');

    await showLocalNotification(
      'Order Status Changed',
      'Order for ${leadItem.customerName} has changed from $oldStatus to $newStatus.',
    );
    developer.log('Local notification sent');
  } catch (e) {
    developer.log('Error generating notification: $e');
  }
}

// Generate task due date and new sales lead notification
Future<void> _generateTaskandSalesLeadNotification(
    MySqlConnection conn,
    int salesmanId,
    String title,
    String description,
    int leadId,
    String type) async {
  try {
    // Insert data into notifications table
    var result = await conn.query(
      'INSERT INTO notifications (salesman_id, title, description, related_lead_id, type) VALUES (?, ?, ?, ?, ?)',
      [salesmanId, title, description, leadId, type],
    );
    developer.log(
        'Inserted notification into database. Affected rows: ${result.affectedRows}');

    await showLocalNotification(title, description);
    developer.log('Local notification sent');
  } catch (e) {
    developer.log('Error generating task notification: $e');
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
