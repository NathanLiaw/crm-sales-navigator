import 'package:flutter/material.dart';
import 'package:sales_navigator/Components/CustomNavigationBar.dart';
import 'package:sales_navigator/notification_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // // pass salesman name to profile page
  // final String salesmanName;
  // HomePage({required this.salesmanName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0069BA),
        title: const Text(
          'HomePage',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notifications
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to homepage'), // show salesman name for testing
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
