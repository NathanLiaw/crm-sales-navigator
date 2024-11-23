import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'package:sales_navigator/screens/notification/background_tasks.dart';
import 'package:sales_navigator/components/navigation_provider.dart';
import 'package:workmanager/workmanager.dart';
import '../home/home_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

  void signIn(BuildContext context) async {
    String username = usernameController.text;
    String password = passwordController.text;

    // Hash the password using MD5
    String hashedPassword = md5.convert(utf8.encode(password)).toString();

    try {
      var url = Uri.parse(
          '${dotenv.env['API_URL']}/authentication/authenticate_login.php');

      var response = await http.post(
        url,
        body: {
          'username': username,
          'password': hashedPassword,
        },
      );

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        var salesman = jsonResponse['salesman'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setInt('id', salesman['id']);
        developer
            .log("Saved salesman_id to SharedPreferences: ${salesman['id']}");
        prefs.setInt('area', salesman['area']);
        prefs.setString('salesmanName', salesman['salesman_name']);
        prefs.setString('username', salesman['username']);
        prefs.setString('contactNumber', salesman['contact_number']);
        prefs.setString('email', salesman['email']);
        prefs.setString('repriceAuthority', salesman['reprice_authority']);
        prefs.setString('discountAuthority', salesman['discount_authority']);
        prefs.setInt('status', salesman['status']);

        // Save login status and expiration time to shared preferences
        prefs.setBool('isLoggedIn', true);
        prefs.setInt(
            'loginExpirationTime',
            DateTime.now()
                .add(const Duration(days: 31))
                .millisecondsSinceEpoch);

        await _initializeBackgroundTasks();

        Provider.of<NavigationProvider>(context, listen: false)
            .setSelectedIndex(0);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'])),
        );
      }
    } catch (e) {
      developer.log('Error signing in: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please try again.'),
        ),
      );
    }
  }

  Future<void> _initializeBackgroundTasks() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

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
  }

  Future<bool> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    int loginExpirationTime = prefs.getInt('loginExpirationTime') ?? 0;

    if (isLoggedIn &&
        loginExpirationTime > DateTime.now().millisecondsSinceEpoch) {
      return true;
    } else {
      prefs.remove('isLoggedIn');
      prefs.remove('loginExpirationTime');
      return false;
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
    return FutureBuilder<bool>(
      future: checkLoginStatus(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!) {
          return const HomePage();
        } else {
          return Scaffold(
            body: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                            left: 18,
                            top: 50,
                            bottom: 20,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'asset/logo/logo_fyh.png',
                            width: 300,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(
                            left: 20,
                            bottom: 24,
                          ),
                          child: const Text(
                            'Control your Sales\ntoday.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextFormField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Username',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Password',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 80),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => signIn(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 7, 148, 255),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => showContactInfoDialog(context),
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
                    SizedBox(
                      height: 244,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            top: -100,
                            left: 0,
                            right: 0,
                            child: Image.asset(
                              'asset/SN_ELEMENTS_CENTER.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 20,
                            left: 0,
                            right: 0,
                            child: SizedBox(
                              width: 40,
                              child: Image.asset(
                                width: 150,
                                height: 150,
                                'asset/chart_illu.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
