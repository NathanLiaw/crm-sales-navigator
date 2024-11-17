import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  _AccountSettingState createState() {
    return _AccountSettingState();
  }
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

  void getSalesmanInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('salesmanName') ?? '';
    String phoneNumber = prefs.getString('contactNumber') ?? '';
    String email = prefs.getString('email') ?? '';
    int id = prefs.getInt('id') ?? 0;

    setState(() {
      nameController.text = name;
      phoneNumberController.text = phoneNumber;
      emailController.text = email;
      salesmanId = id;
    });
  }

  Future<void> updateSalesmanDetailsInDatabase() async {
    String newName = nameController.text;
    String newPhoneNumber = phoneNumberController.text;
    String newEmail = emailController.text;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('salesmanName', newName);
    prefs.setString('contactNumber', newPhoneNumber);
    prefs.setString('email', newEmail);

    try {
      final url = Uri.parse('${dotenv.env['API_URL']}/salesman/update_salesman_details.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'salesmanId': salesmanId,
          'newName': newName,
          'newPhoneNumber': newPhoneNumber,
          'newEmail': newEmail,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('salesmanName', newName);
        prefs.setString('contactNumber', newPhoneNumber);
        prefs.setString('email', newEmail);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salesman details updated successfully.')),
        );
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error updating salesman details: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update salesman details. Please try again.')),
      );
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text('Account Setting', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Salesman Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xff0175FF)),
              ),
              const SizedBox(height: 20),
              _buildTextField(nameController, 'Name'),
              const SizedBox(height: 16),
              _buildTextField(phoneNumberController, 'Phone Number'),
              const SizedBox(height: 16),
              _buildTextField(emailController, 'Email'),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xff0175FF), width: 2.0),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
              side: const BorderSide(color: Colors.red, width: 2),
            ),
            minimumSize: const Size(120, 40),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            updateSalesmanDetailsInDatabase();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff0175FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            minimumSize: const Size(120, 40),
          ),
          child: const Text(
            'Apply',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
