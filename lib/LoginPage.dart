import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:crypto/crypto.dart';
import 'package:sales_navigator/HomePage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_navigator/db_connection.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void signIn(BuildContext context) async {
    String username = usernameController.text;
    String password = passwordController.text;

    // Hash the password using MD5
    String hashedPassword = md5.convert(utf8.encode(password)).toString();

    // Connect to the MySQL database
    MySqlConnection conn = await connectToDatabase();

    try {
      // Query to fetch salesman data from the database based on email and password
      Results results = await conn.query(
          'SELECT * FROM salesman WHERE username = ? AND password = ?',
          [username, hashedPassword]);

      // If there is a matching salesman, navigate to the home page
      if (results.isNotEmpty) {
        // Fetch the first row (should be only one)
        var row = results.first;

        // Save salesman data to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setInt('id', row['id']);
        // prefs.setString('area', row['area']);
        prefs.setString('salesmanName', row['salesman_name']);
        prefs.setString('username', row['username']);
        // prefs.setString('password', row['password']);
        prefs.setString('contactNumber', row['contact_number']);
        prefs.setString('email', row['email']);
        // prefs.setString('tempPassword', row['temp_password']);
        // prefs.setString('repriceAuthority', row['reprice_authority']);
        // prefs.setString('discountAuthority', row['discount_authority']);
        // prefs.setString('status', row['status']);
        // prefs.setString('created', row['created']);
        // prefs.setString('modified', row['modified']);

        // Navigate to HomePage and pass salesmanName
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ));
      } else {
        // If no matching salesman found, display an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid username or password. Please try again.'),
          ),
        );
      }
    } catch (e) {
      print('Error signing in: $e');
    } finally {
      await conn.close();
    }
  }

  void showContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please contact our support team for assistance:'),
                SizedBox(height: 10),
                Text('Phone: +60-82362333, 362666, 362999'),
                Text('Email: FYHKCH@hotmail.com'),
                // Add more contact information here if needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 50),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(top: 30),
                margin: EdgeInsets.only(bottom: 20),
                child: Image.asset(
                  'asset/logo/logo_fyh.png',
                  width: 300,
                  height: 250,
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(
                  left: 20,
                ),
                child: Text(
                  'Salesman',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),

              // Email input field
              SizedBox(height: 10),
              Container(
                margin:
                    EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                child: TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    // hintText: 'fyh@mail.com',
                  ),
                ),
              ),

              // Password input field
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                child: TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              ),

              // Sign in button
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Implement sign-in logic here
                    signIn(context); // Call the sign in method
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff0069BA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Forgot password button
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Implement forgot password logic here
                  showContactInfoDialog(context);
                },
                child: Text(
                  'Forgot Password',
                  style: TextStyle(
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}