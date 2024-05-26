import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class CreateTaskPage extends StatefulWidget {
  final String customerName;
  final String contactNumber;
  final String emailAddress;
  final String address;
  final String lastPurchasedAmount;
  final String? existingTitle;
  final String? existingDescription;
  final DateTime? existingDueDate;
  final bool showTaskDetails;

  const CreateTaskPage({
    super.key,
    required this.customerName,
    required this.contactNumber,
    required this.emailAddress,
    required this.address,
    required this.lastPurchasedAmount,
    this.existingTitle,
    this.existingDescription,
    this.existingDueDate,
    this.showTaskDetails = true,
  });

  @override
  _CreateTaskPageState createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  DateTime? selectedDate = DateTime.now();
  String? selectedSalesOrderId;
  String? expirationDate;
  String? createdDate;
  String? total;
  List<String> salesOrderIds = [];
  String? formattedCreatedDate;
  String? quantity;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    selectedDate = widget.existingDueDate ?? DateTime.now();
    titleController.text = widget.existingTitle ?? '';
    descriptionController.text = widget.existingDescription ?? '';
    fetchSalesOrderIds().then((value) {
      setState(() {
        salesOrderIds = value;
      });
    });
    _fetchSalesOrderDetails(selectedSalesOrderId);
  }

  Future<void> _fetchSalesOrderDetails(String? salesOrderId) async {
    if (salesOrderId == null) return;

    try {
      MySqlConnection conn = await connectToDatabase();
      Results results = await conn.query(
        'SELECT created, expiration_date, total, session FROM cart WHERE id = ?',
        [int.parse(salesOrderId)],
      );
      if (results.isNotEmpty) {
        var row = results.first;
        String session = row['session'].toString();

        // get the qty sum in the cart_item table based on session
        Results quantityResults = await conn.query(
          "SELECT CAST(SUM(qty) AS UNSIGNED) AS total_qty FROM cart_item WHERE session = ? OR cart_id = ?",
          [session, int.parse(salesOrderId)],
        );
        String totalQuantity = quantityResults.isEmpty
            ? '0'
            : quantityResults.first['total_qty'].toString();
        setState(() {
          createdDate = row['created'].toString();
          expirationDate = row['expiration_date'].toString();
          total = row['total'].toString();
          quantity = totalQuantity;
          formattedCreatedDate = _formatDate(createdDate!);
        });
      }
      await conn.close();
    } catch (e) {
      developer.log('Error fetching sales order details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSalesOrderDropdown(
      String customerName) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    int buyerId = pref.getInt('id') ?? 1;

    try {
      MySqlConnection conn = await connectToDatabase();

      String condition =
          "buyer_id = $buyerId AND customer_company_name = '$customerName' "
          "AND status = 'Pending' AND CURDATE() >= expiration_date";

      List<Map<String, dynamic>> salesOrders = await readData(
        conn,
        'cart',
        condition,
        '',
        '*',
      );
      await conn.close();

      return salesOrders;
    } catch (e) {
      developer.log('Error fetching sales orders: $e');
      return [];
    }
  }

  Future<List<String>> fetchSalesOrderIds() async {
    try {
      List<Map<String, dynamic>> salesOrders =
      await fetchSalesOrderDropdown(widget.customerName);
      setState(() {
        salesOrderIds = salesOrders.map((order) {
          final orderId = order['id'];
          return orderId.toString();
        }).toList();
      });
    } catch (e) {
      developer.log('Error fetching sales order IDs: $e');
    }
    return salesOrderIds;
  }

  @override
  Widget build(BuildContext context) {
    // Create a NumberFormat instance with the desired format
    final formatter = NumberFormat("#,###.000", "en_US");
    // Validate and preprocess the lastPurchasedAmount
    String formattedLastPurchasedAmount = '';
    if (widget.lastPurchasedAmount != null &&
        widget.lastPurchasedAmount.isNotEmpty) {
      String cleanedAmount =
      widget.lastPurchasedAmount.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleanedAmount.isNotEmpty) {
        double parsedAmount = double.parse(cleanedAmount);
        formattedLastPurchasedAmount = formatter.format(parsedAmount);
      }
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
        title: const Text(
          'Create Task',
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
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff0069BA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Customer Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xff0069BA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              // Use the formatted lastPurchasedAmount
                              'RM $formattedLastPurchasedAmount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xff0069BA)),
                          const SizedBox(width: 10),
                          Text(
                            widget.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Color(0xff0069BA)),
                          const SizedBox(width: 10),
                          Text(
                            widget.contactNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email, color: Color(0xff0069BA)),
                          const SizedBox(width: 10),
                          Text(
                            widget.emailAddress,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              color: Color(0xff0069BA)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.address,
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.showTaskDetails) ...[
                  const SizedBox(height: 40),
                  const Text(
                    'Task Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                    validator: (value) {
                      if (value != null && value.length > 50) {
                        return 'Title cannot exceed 50 digits';
                      }
                      return null;
                    },
                  ),
                  const Text(
                    '*Ignore this part if directly to Order Processing',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                    validator: (value) {
                      if (value != null && value.length > 100) {
                        return 'Description cannot exceed 100 digits';
                      }
                      return null;
                    },
                  ),
                  const Text(
                    '*Ignore this part if directly to Order Processing',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due date',
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IntrinsicWidth(
                              child: Text(
                                selectedDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                    .format(selectedDate!)
                                    : '',
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                const Text(
                  'Sales order ID',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        value: selectedSalesOrderId,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedSalesOrderId = newValue;
                          });
                          _fetchSalesOrderDetails(newValue);
                        },
                        items: salesOrderIds.map((String id) {
                          String formattedId = 'SO${id.padLeft(7, '0')}';
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(formattedId),
                          );
                        }).toList(),
                        // validator: (value) {
                        //   if (value == null) {
                        //     return 'Please select a sales order ID';
                        //   }
                        //   return null;
                        // },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '*Select a sales order ID',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                if (selectedSalesOrderId != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created date: ${formattedCreatedDate ?? ''}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Expiry date: ${expirationDate ?? ''}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Quantity: ',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0069BA)),
                        ),
                        Text(quantity != null ? '$quantity items' : ''),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'Total: ',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0069BA)),
                        ),
                        Text(total != null ? 'RM$total' : ''),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 60),
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
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final result = await _saveTaskToDatabase();
                          Navigator.pop(context, result);
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
                        'Apply',
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<Map<String, Object?>> _saveTaskToDatabase() async {
    MySqlConnection conn = await connectToDatabase();

    String taskTitle = titleController.text;
    String taskDescription = descriptionController.text;
    String taskDueDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    String salesOrderId = selectedSalesOrderId ?? '';
    int? quantityInt = quantity != null ? int.parse(quantity!) : null;

    try {
      await conn.query(
        'UPDATE sales_lead SET task_title = ?, task_description = ?, task_duedate = ?, so_id = ?, quantity = ? WHERE customer_name = ?',
        [
          taskTitle,
          taskDescription,
          taskDueDate,
          salesOrderId.isEmpty ? null : salesOrderId,
          quantityInt,
          widget.customerName
        ],
      );
      developer.log('Task data saved successfully.');
      return {
        'title': titleController.text,
        'description': descriptionController.text,
        'dueDate': selectedDate,
        'salesOrderId': salesOrderId.isEmpty ? null : salesOrderId,
        'quantity': quantity,
      };
    } catch (e) {
      developer.log('Failed to save task data: $e');
      return {
        'error': 'Failed to save task data',
      };
    } finally {
      await conn.close();
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) {
      return '';
    }
    DateTime parsedDate = DateTime.parse(dateString);
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(parsedDate);
  }
}