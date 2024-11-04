import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sales_navigator/chatbot_page.dart';
import 'package:sales_navigator/data_analytics_page.dart';
import 'package:sales_navigator/model/notification_state.dart';
import 'package:sales_navigator/notification_page.dart';
import 'package:workmanager/workmanager.dart';
import 'about_us_page.dart';
import 'account_setting_page.dart';
import 'contact_us_page.dart';
import 'package:sales_navigator/recent_order_page.dart';
import 'terms_and_conditions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Components/navigation_bar.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? salesmanName;
  int currentPageIndex = 4;

  @override
  void initState() {
    super.initState();
    _getSalesmanName();
  }

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

  Future<void> _loadUnreadNotifications() async {
    // Logic to load unread notifications (you may need to implement this)
    // Example: setState(() => _unreadNotifications = await fetchUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff0175FF),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        actions: [
          Consumer<NotificationState>(
            builder: (context, notificationState, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 7.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        );
                        _loadUnreadNotifications();
                      },
                    ),
                    if (notificationState.unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notificationState.unreadCount > 99
                                ? '99+'
                                : notificationState.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
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
              const SizedBox(height: 20),
              Container(
                alignment: Alignment.center,
                child: const Text(
                  'Welcome,',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$salesmanName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              buildProfileOption('Account Setting', Icons.settings, context),
              buildProfileOption('Reports', Icons.analytics, context),
              buildProfileOption('Recent Order', Icons.shopping_bag, context),
              buildProfileOption('Terms & Condition', Icons.description, context),
              buildProfileOption('Contact Us', Icons.phone, context),
              buildProfileOption('About Us', Icons.info, context),
              buildProfileOption('Chatbot', Icons.chat, context),
              const SizedBox(height: 20),
              Center(child: buildLogoutButton()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget buildProfileOption(String title, IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (title) {
          case 'Account Setting':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSetting())).then((value) {
              if (value == true) {
                _getSalesmanName();
              }
            });
            break;
          case 'Reports':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DataAnalyticsPage()));
            break;
          case 'Recent Order':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentOrder(customerId: 0)));
            break;
          case 'Terms & Condition':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsandConditions()));
            break;
          case 'Contact Us':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUs()));
            break;
          case 'About Us':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUs()));
            break;
          case 'Chatbot':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
            break;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: const Color(0xff0175FF),
          ),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ),
      ),
    );
  }

  Widget buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Logout'),
                    onPressed: () async {
                      Navigator.of(context).pop();

                      try {
                        await Workmanager().cancelAll();
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        imageCache.clear();
                        imageCache.clearLiveImages();

                        final tempDir = await getTemporaryDirectory();
                        if (await tempDir.exists()) {
                          await tempDir.delete(recursive: true);
                        }

                        Navigator.pushReplacementNamed(context, '/login');
                      } catch (e) {
                        debugPrint('Error during logout: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error occurred during logout. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          minimumSize: const Size(120, 40),
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
