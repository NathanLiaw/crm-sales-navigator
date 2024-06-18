import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/services.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/customer_details_page.dart';
import 'package:sales_navigator/db_connection.dart';
import 'dart:developer' as developer;

class CreateLeadPage extends StatefulWidget {
  final Function(String, String, String) onCreateLead;
  final int salesmanId;

  const CreateLeadPage({super.key, required this.onCreateLead, required this.salesmanId});

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
        backgroundColor: const Color(0xff004c87),
        title: const Text(
          'Create Lead',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customer Details',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    IconButton(
                      icon: const Icon(Icons.contacts, color: Color(0xff0069BA)),
                      onPressed: _selectCustomer,
                    ),
                  ],
                ),
                TextFormField(
                  controller: customerNameController,
                  decoration: const InputDecoration(
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
                  decoration: const InputDecoration(
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
                    if (value.length > 11) {
                      return 'Contact number cannot exceed 11 digits';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailAddressController,
                  decoration: const InputDecoration(
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
                  decoration: const InputDecoration(
                    labelText: 'Enter address',
                    prefixIcon:
                        Icon(Icons.location_on, color: Color(0xff0069BA)),
                  ),
                  maxLength: 200,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    List<String> words = value.split(' ');
                    if (words.length > 200) {
                      return 'Address cannot exceed 200 words';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                const Text(
                  'Others',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
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
                        decoration: const InputDecoration(
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
                const SizedBox(height: 24.0),
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
                          side: const BorderSide(color: Colors.red, width: 2),
                        ),
                        minimumSize: const Size(120, 40),
                      ),
                      child: const Text(
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
                          _saveLeadToDatabase();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0069BA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        minimumSize: const Size(120, 40),
                      ),
                      child: const Text(
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

  Future<void> _selectCustomer() async {
    final selectedCustomer = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerDetails()),
    );
    if (selectedCustomer != null) {
      setState(() {
        customerNameController.text = selectedCustomer.companyName;
        contactNumberController.text = selectedCustomer.contactNumber;
        emailAddressController.text = selectedCustomer.email;
        addressController.text = selectedCustomer.addressLine1;
      });
    }
  }

  Future<void> _saveLeadToDatabase() async {
    MySqlConnection conn = await connectToDatabase();

    Map<String, dynamic> leadData = {
      'salesman_id': widget.salesmanId,
      'customer_name': customerNameController.text,
      'contact_number': contactNumberController.text,
      'email_address': emailAddressController.text,
      'address': addressController.text,
      'description': descriptionController.text,
      'predicted_sales': amountController.text,
      'stage': 'Opportunities', // Add the default stage for new leads
      'previous_stage': 'Opportunities',
      'so_id': null,
      'created_date':
          DateTime.now().toString(), // Add the current date as created_date
    };

    // Validate description length
    if (leadData['description'].length > 255) {
      developer.log('Description cannot exceed 255 characters.');
      return;
    }

    // Save data to database
    bool success = await saveData(conn, 'sales_lead', leadData);
    if (success) {
      developer.log('Lead data saved successfully.');
    } else {
      developer.log('Failed to save lead data.');
    }

    await conn.close();
  }
}