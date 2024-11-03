import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sales_navigator/api/firebase_api.dart';
import 'package:sales_navigator/background_tasks.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/components/navigation_provider.dart';
import 'package:sales_navigator/firebase_options.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/model/notification_state.dart';
import 'package:sales_navigator/notification_page.dart';
import 'package:sales_navigator/login_page.dart';
import 'package:sales_navigator/profile_page.dart';
import 'package:sales_navigator/sales_order_page.dart';
import 'package:sales_navigator/starting_page.dart';
import 'db_sqlite.dart';
import 'products_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:sales_navigator/model/order_status_provider.dart';
import 'package:sales_navigator/model/cart_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotifications();

  // Request storage permission at startup
  await requestStoragePermission();

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

  // // Initialize Workmanager
  // await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // // Register periodic tasks
  // await Workmanager().registerPeriodicTask(
  //   "1",
  //   "fetchSalesOrderStatus",
  //   frequency: const Duration(minutes: 15),
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   ),
  // );

  // await Workmanager().registerPeriodicTask(
  //   "2",
  //   "checkTaskDueDates",
  //   frequency: const Duration(days: 1),
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   ),
  // );

  // await Workmanager().registerPeriodicTask(
  //   "3",
  //   "checkNewSalesLeads",
  //   frequency: const Duration(days: 1),
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   ),
  // );

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
        ChangeNotifierProvider(create: (_) => NotificationState()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => OrderStatusProvider()),
        // Add other providers here
      ],
      child: const MyApp(),
    ),
  );
}

// Permission handling for storage permission
Future<void> requestStoragePermission() async {
  final status = await Permission.storage.status;
  if (status.isDenied || status.isPermanentlyDenied) {
    await Permission.storage.request();
  }
  if (await Permission.storage.isGranted) {
    developer.log("Storage permission granted.");
  } else {
    developer.log("Storage permission denied.");
  }
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  void _checkConnectivity() async {
    final ConnectivityResult result =
        (await Connectivity().checkConnectivity()) as ConnectivityResult;
    setState(() {
      isOffline = result == ConnectivityResult.none;
    });

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
          setState(() {
            isOffline = result == ConnectivityResult.none;
          });
        } as void Function(List<ConnectivityResult> event)?);
  }

  @override
  Widget build(BuildContext context) {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    cartModel.initializeCartCount();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        primaryColor: const Color(0xFF0175FF),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          headlineSmall: TextStyle(color: Colors.black),
        ),
      ),
      home: isOffline ? NoInternetScreen() : const StartingPage(),
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

class NoInternetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("No Internet Connection"),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No internet connection available.',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
