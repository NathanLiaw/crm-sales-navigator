import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_navigator/db_connection.dart';

class AccountSetting extends StatefulWidget {
  @override
  _AccountSettingState createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  int salesmanId = 0;

  @override
  void initState() {
    super.initState();
    getSalesmanInfo();
  }

  // Get salesman information from sharedpreferences at initialization time and set it to the appropriate text editor control.
  void getSalesmanInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('salesmanName') ?? '';
    String phoneNumber = prefs.getString('contactNumber') ?? '';
    String email = prefs.getString('email') ?? '';

    // Retrieve salesman ID from SharedPreferences
    int id = prefs.getInt('id') ?? 0;

    setState(() {
      nameController.text = name;
      phoneNumberController.text = phoneNumber;
      emailController.text = email;
      salesmanId = id; // Set the salesman ID
    });
  }

  // The function used to update salesman info in database
  Future<void> updateSalesmanDetailsInDatabase() async {
    // Getthe updated value from a text edit control
    String newName = nameController.text;
    String newPhoneNumber = phoneNumberController.text;
    String newEmail = emailController.text;

    // Connect to database
    MySqlConnection conn = await connectToDatabase();

    try {
      // Execute the update statement
      await conn.query('''
        UPDATE salesman
        SET salesman_name = ?, contact_number = ?, email = ?
        WHERE id = ?;
      ''', [newName, newPhoneNumber, newEmail, salesmanId]);

      // After successful update, save the new value to the SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('salesmanName', newName);
      prefs.setString('contactNumber', newPhoneNumber);
      prefs.setString('email', newEmail);

      // show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salesman details updated successfully.'),
        ),
      );
    } catch (e) {
      print('Error updating salesman details: $e');
      // show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update salesman details. Please try again.'),
        ),
      );
    } finally {
      // Close the database connection
      await conn.close();
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0069BA),
        title: Text(
          'Account Setting',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salesman Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel button
                Container(
                  margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle cancel button press
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(color: Colors.red, width: 2),
                        ),
                        minimumSize: Size(120, 40)),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Apply button
                Container(
                  margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      // Call the update database function
                      updateSalesmanDetailsInDatabase();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff0069BA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        minimumSize: Size(120, 40)),
                    child: Text(
                      'Apply',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
