import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:crypto/crypto.dart';
import 'home_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_connection.dart';
import 'dart:developer' as developer;

class LoginPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

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
        prefs.setInt('area', row['area']);
        prefs.setString('salesmanName', row['salesman_name']);
        prefs.setString('username', row['username']);
        prefs.setString('contactNumber', row['contact_number']);
        prefs.setString('email', row['email']);
        prefs.setString('repriceAuthority', row['reprice_authority']);
        prefs.setString('discountAuthority', row['discount_authority']);
        prefs.setInt('status', row['status']);

        // Navigate to HomePage and pass salesmanName
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password. Please try again.'),
          ),
        );
      }
    } catch (e) {
      developer.log('Error signing in: $e', error: e);
    } finally {
      await conn.close();
    }
  }

  void showContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Information'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please contact our support team for assistance:'),
                SizedBox(height: 10),
                Text('Phone: +60-82362333, 362666, 362999'),
                Text('Email: FYHKCH@hotmail.com'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
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
                padding: const EdgeInsets.only(top: 30),
                margin: const EdgeInsets.only(bottom: 10),
                child: Image.asset(
                  'asset/logo/logo_fyh.png',
                  width: 300,
                  height: 250,
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(
                  left: 20,
                ),
                child: const Text(
                  'Salesman',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),

              // Email input field
              const SizedBox(height: 10),
              Container(
                margin:
                    const EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                child: TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    // hintText: 'fyh@mail.com',
                  ),
                ),
              ),

              // Password input field
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
                child: TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              ),

              // Sign in button
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Call the sign in method
                    signIn(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0069BA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Forgot password button
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Show pop up window
                  showContactInfoDialog(context);
                },
                child: const Text(
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
