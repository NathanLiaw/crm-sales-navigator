import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sales_navigator/api/firebase_api.dart';
import 'package:sales_navigator/background_tasks.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/firebase_options.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/notification_page.dart';
import 'package:sales_navigator/starting_page.dart';
import 'package:sales_navigator/login_page.dart';
import 'package:sales_navigator/profile_page.dart';
import 'package:sales_navigator/sales_order_page.dart';
import 'package:workmanager/workmanager.dart';
import 'db_sqlite.dart';
import 'products_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:sales_navigator/model/cart_model.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission handler

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotifications();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@drawable/sales_navigator');
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Check and request the SCHEDULE_EXACT_ALARM permission for Android 14+
  if (await shouldRequestExactAlarmPermission()) {
    await requestExactAlarmPermission();
  }

  // Initialize Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Register periodic tasks
  await Workmanager().registerPeriodicTask(
    "1",
    "fetchSalesOrderStatus",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  await Workmanager().registerPeriodicTask(
    "2",
    "checkTaskDueDates",
    frequency: const Duration(days: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  await Workmanager().registerPeriodicTask(
    "3",
    "checkNewSalesLeads",
    frequency: const Duration(days: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  // Handling notifications received when the app is completely closed
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      Future.delayed(Duration.zero, () {
        navigatorKey.currentState?.pushNamed(
          NotificationsPage.route,
          arguments: message,
        );
      });
    }
  });

  // Handling notifications received when the app is open
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    developer.log("onMessageOpenedApp: $message");
    Future.delayed(Duration.zero, () {
      navigatorKey.currentState?.pushNamed(
        NotificationsPage.route,
        arguments: message,
      );
    });
  });

  // Initialize the SQLite database
  await DatabaseHelper.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
        // Add other providers here
      ],
      child: MyApp(),
    ),
  );
}

// Permission handling functions for Android 14+
Future<bool> shouldRequestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    return true;
  }
  return false;
}

Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.request().isGranted) {
    developer.log('SCHEDULE_EXACT_ALARM permission granted');
  } else {
    developer.log('SCHEDULE_EXACT_ALARM permission denied');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    cartModel.initializeCartCount();
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: StartingPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/sales': (context) => const SalesOrderPage(),
        '/product': (context) => const ProductsScreen(),
        '/cart': (context) => const CartPage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => const ProfilePage(),
        NotificationsPage.route: (context) => const NotificationsPage(),
      },
    );
  }
}
