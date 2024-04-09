import 'package:flutter/material.dart';
import 'package:sales_navigator/AboutUs.dart';
import 'package:sales_navigator/AccountSetting.dart';
import 'package:sales_navigator/ContactUs.dart';
import 'package:sales_navigator/RecentOrder.dart';
import 'package:sales_navigator/TermsandConditions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_navigator/CustomNavigationBar.dart';

class ProfilePage extends StatefulWidget {
  // final String salesmanName; // Define salesmanName variable

  // ProfilePage(
  //     {required this.salesmanName}); // Constructor to receive salesmanName
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

  // 使用didChangeDependencies方法来重新获取销售人员姓名
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getSalesmanName();
  }

  Future<void> _getSalesmanName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      salesmanName = prefs.getString('salesmanName') ??
          ''; // Use default value if 'salesmanName' is null
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
            icon: Icon(Icons.notifications),
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
      bottomNavigationBar: CustomNavigationBar(), // 保留底部导航栏
    );
  }

  Widget buildProfileOption(String title, IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == 'Account Setting') {
          // check button title
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
          // implement logout logic
          // 清除 SharedPreferences 中的数据
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // 导航到登录页面
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
