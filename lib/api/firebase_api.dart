import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sales_navigator/main.dart';
import 'package:sales_navigator/notification_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    developer.log('FCM Token: $fCMToken');
    await initPushNotifications();
    await initLocalNotifications();
  }

  Future<void> initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@drawable/sales_navigator',
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
      // Display a dialog box that lets the user choose whether or not to view the notification
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (_) => AlertDialog(
          title: Text(notification.title ?? 'New Notification'),
          content: Text(notification.body ?? ''),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
            ),
            TextButton(
              child: Text('View'),
              onPressed: () {
                Navigator.of(navigatorKey.currentContext!).pop();
                handleMessage(message);
              },
            ),
          ],
        ),
      );
      // handleMessage(message);
    });
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    developer.log("Handling message: ${message.messageId}");

    // Use Future.delayed to ensure a valid navigation context
    Future.delayed(Duration.zero, () {
      developer.log("Attempting to navigate to NotificationsPage");
      navigatorKey.currentState?.pushNamed(
        NotificationsPage.route,
        arguments: message,
      );
    });
  }

  Future<void> initLocalNotifications() async {
    const iOS = IOSInitializationSettings();
    const android = AndroidInitializationSettings('@drawable/sales_navigator');
    const settings = InitializationSettings(android: android, iOS: iOS);

    await _localNotifications.initialize(
      settings,
      onSelectNotification: (payload) {
        print("Local notification selected: $payload");
        if (payload != null) {
          final data = jsonDecode(payload);
          handleMessage(RemoteMessage(
            notification: RemoteNotification(
              title: data['title'],
              body: data['body'],
            ),
            data: data,
          ));
        }
      },
    );

    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  // void handleMessage(RemoteMessage? message) {
  //   if (message == null) return;
  //   navigatorkey.currentState?.pushNamed(
  //     NotificationsPage.route,
  //     arguments: message,
  //   );
  // }

  // void handleMessage(RemoteMessage? message) {
  //   if (message == null) return;

  //   Future.delayed(Duration.zero, () {
  //     navigatorKey.currentState?.pushNamed(
  //       NotificationsPage.route,
  //       arguments: message,
  //     );
  //   });
  // }

  Future<void> sendPushNotification(
      String salesmanId, String title, String body) async {
    // Get FCM token
    final fcmToken = await _getFCMTokenForSalesman(salesmanId);
    developer.log('Sending push notification to token: $fcmToken');

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
            'key=AIzaSyCScCknaXQpG_apftYmhGtODr_a11YgtoY', // Firebase server key
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title,
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done'
          },
          'to': fcmToken,
        },
      ),
    );

    if (response.statusCode == 200) {
      developer.log("Push notification sent successfully");
    } else {
      developer.log("Error sending push notification: ${response.body}");
    }
  }

  // Function to get FCM token
  Future<String> _getFCMTokenForSalesman(String salesmanId) async {
    // May need to change in the future
    return "salesmanFCMToken";
  }

  Future<void> showLocalNotification(String title, String body) async {
    await _localNotifications.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/sales_navigator',
        ),
      ),
      payload: jsonEncode({
        'title': title,
        'body': body,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      }),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log("Handling a background message: ${message.messageId}");
  // can process the message here if needed
}