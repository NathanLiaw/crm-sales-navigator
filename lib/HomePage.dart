import 'package:flutter/material.dart';
import 'package:sales_navigator/CustomNavigationBar.dart';
import 'package:sales_navigator/Notification_page.dart'; // 导入底部导航栏

class HomePage extends StatelessWidget {
  // // pass salesman name to profile page
  // final String salesmanName;
  // HomePage({required this.salesmanName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0069BA),
        title: Text(
          'HomePage',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notifications
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome to homepage'), // show salesman name for testing
      ),
      bottomNavigationBar: CustomNavigationBar(),
    );
  }
}
