import 'package:flutter/material.dart';
import 'package:sales_navigator/login_page.dart';

class StartingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top right illustration
          Positioned(
            top: 0,
            right: -40,
            child: Image.asset(
              'asset/top_start.png',
              width: 300,
              height: 300,
            ),
          ),
          // Bottom left illustration
          Positioned(
            bottom: -40,
            left: 0,
            child: Image.asset(
              'asset/bttm_start.png',
              width: 250,
              height: 250,
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'asset/logo/logo_fyh.png',
                  width: 300,
                  height: 100,
                ),
                SizedBox(height: 50),
                Text(
                  "Let's get started.",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to LoginPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
