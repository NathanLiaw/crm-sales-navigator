import 'package:flutter/material.dart';
import 'package:sales_navigator/Components/CustomNavigationBar.dart';
import 'package:sales_navigator/account_setting_page.dart';
import 'package:sales_navigator/contact_us_page.dart';
import 'package:sales_navigator/recent_order_page.dart';
import 'package:sales_navigator/terms_and_conditions_page.dart';
import 'package:sales_navigator/about_us_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? salesmanName;

  @override
  void initState() {
    super.initState();
    _getSalesmanName();
  }

  // Use the didChangeDependencies function to recapture salesperson names
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getSalesmanName();
  }

  Future<void> _getSalesmanName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      salesmanName = prefs.getString('salesmanName') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0069BA),
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Container(
                alignment: Alignment.center,
                child: Text(
                  'Welcome,',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              // Display salesman name
              Container(
                  alignment: Alignment.center,
                  child: Text(
                    '$salesmanName',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  )),
              SizedBox(height: 20),
              buildProfileOption('Account Setting', Icons.settings, context),
              buildProfileOption('Reports', Icons.favorite, context),
              buildProfileOption('Recent Order', Icons.shopping_bag, context),
              buildProfileOption(
                  'Terms & Condition', Icons.description, context),
              buildProfileOption('Contact Us', Icons.phone, context),
              buildProfileOption('About Us', Icons.info, context),
              SizedBox(height: 20),
              buildLogoutButton(), // add Logout button
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(),
    );
  }

  Widget buildProfileOption(String title, IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // check button title
        if (title == 'Account Setting') {
          Navigator.push(
            // Navigate to account setting page
            context,
            MaterialPageRoute(builder: (context) => AccountSetting()),
          )..then((value) {
              if (value == true) {
                _getSalesmanName();
              }
            });
        }
        if (title == 'Terms & Condition') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TermsandConditions()),
          );
        }
        if (title == 'Contact Us') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ContactUs()),
          );
        }
        if (title == 'About Us') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AboutUs()),
          );
        }
        if (title == 'Recent Order') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecentOrder()),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(5),
        ),
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
        ),
      ),
    );
  }

  Widget buildLogoutButton() {
    return Container(
      margin: EdgeInsets.only(left: 100, right: 100),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // Clearing data in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // Navigate to the login page
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(color: Colors.red, width: 2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Text(
            'Log Out',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
