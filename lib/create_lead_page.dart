import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/services.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';

class CreateLeadPage extends StatefulWidget {
  final Function(String, String, String) onCreateLead;

  CreateLeadPage({required this.onCreateLead});

  @override
  _CreateLeadPageState createState() => _CreateLeadPageState();
}

class _CreateLeadPageState extends State<CreateLeadPage> {
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController emailAddressController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0069BA),
        title: Text(
          'Create Lead',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Customer Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                TextFormField(
                  controller: customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Enter customer/company name',
                    prefixIcon: Icon(
                      Icons.person,
                      color: Color(0xff0069BA),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter customer/company name';
                    }
                    if (value.length > 100) {
                      return 'Customer/company name cannot exceed 100 characters';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: contactNumberController,
                  decoration: InputDecoration(
                    labelText: 'Enter contact number',
                    prefixIcon: Icon(Icons.phone, color: Color(0xff0069BA)),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact number';
                    }
                    if (value.length > 10) {
                      return 'Contact number cannot exceed 10 digits';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailAddressController,
                  decoration: InputDecoration(
                    labelText: 'Enter email address',
                    prefixIcon: Icon(Icons.email, color: Color(0xff0069BA)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!EmailValidator.validate(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Enter address',
                    prefixIcon:
                        Icon(Icons.location_on, color: Color(0xff0069BA)),
                  ),
                  maxLength: 100,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    List<String> words = value.split(' ');
                    if (words.length > 100) {
                      return 'Address cannot exceed 100 words';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.0),
                Text(
                  'Others',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                  ),
                  validator: (value) {
                    if (value != null && value.isEmpty) {
                      return 'Please enter description';
                    }
                    if (value != null && value.length > 100) {
                      return 'Description cannot exceed 100 characters';
                    }
                    return null;
                  },
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Predicted sales',
                          hintText: 'RM',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isEmpty) {
                            return 'Please enter predicted sales';
                          }
                          if (value != null && double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (value != null && value.length > 50) {
                            return 'Predicted sales cannot exceed 50 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(color: Colors.red, width: 2),
                        ),
                        minimumSize: Size(120, 40),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Call the onCreateLead function with entered values
                          widget.onCreateLead(
                            customerNameController.text,
                            descriptionController.text,
                            amountController.text,
                          );
                          _saveLeadToDatabase(); // Save lead to database
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff0069BA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        minimumSize: Size(120, 40),
                      ),
                      child: Text(
                        'Create',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveLeadToDatabase() async {
    // Connect to the database
    MySqlConnection conn = await connectToDatabase();

    // Prepare data
    Map<String, dynamic> leadData = {
      'customer_name': customerNameController.text,
      'contact_number': contactNumberController.text,
      'email_address': emailAddressController.text,
      'address': addressController.text,
      'description': descriptionController.text,
      'predicted_sales': amountController.text,
      'stage': 'Opportunities', // Add the default stage for new leads
      'so_id': null, // Set SO ID to null initially
    };

    // Validate description length
    if (leadData['description'].length > 255) {
      print('Description cannot exceed 255 characters.');
      return;
    }

    // Save data to database
    bool success = await saveData(conn, 'create_lead', leadData);
    if (success) {
      print('Lead data saved successfully.');
    } else {
      print('Failed to save lead data.');
    }

    await conn.close();
  }
}
