import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/cart_item.dart';
import 'package:sales_navigator/db_sqlite.dart';
import 'package:sales_navigator/order_details_page.dart';
import 'package:sales_navigator/utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_connection.dart';
import 'customer_details_page.dart';
import 'customer.dart';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Order',
      theme: ThemeData(
        primaryColor: const Color(0xFF004C87),
        hintColor: const Color(0xFF004C87),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const SalesOrderPage(),
    );
  }
}

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

  @override
  _SalesOrderPageState createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  DateTimeRange? dateRange;
  int? selectedDays;
  int selectedButtonIndex = 3;
  bool isSortedAscending = false;
  String loggedInUsername = '';
  Customer? selectedCustomer;

  @override
  void initState() {
    super.initState();
    _loadUserDetails().then((_) {
      _loadSalesOrders();
    });
  }

  Future<void> insertItemIntoCart(CartItem cartItem) async {
    int itemId = cartItem.productId;
    String uom = cartItem.uom;

    try {
      const tableName = 'cart_item';
      final condition =
          "product_id = $itemId AND uom = '$uom' AND status = 'in progress'";
      const order = '';
      const field = '*';

      final db = await DatabaseHelper.database;
      final result = await DatabaseHelper.readData(
        db,
        tableName,
        condition,
        order,
        field,
      );

      if (result.isNotEmpty) {
        final existingItem = result.first;
        final updatedQuantity = existingItem['qty'] + cartItem.quantity;
        final data = {
          'id': existingItem['id'],
          'qty': updatedQuantity,
          'modified': UtilityFunction.getCurrentDateTime(),
        };

        await DatabaseHelper.updateData(data, tableName);
        developer.log('Cart item quantity updated successfully');
      } else {
        final cartItemMap = cartItem.toMap(excludeId: true);
        await DatabaseHelper.insertData(cartItemMap, tableName);
        developer.log('New cart item inserted successfully');
      }
    } catch (e) {
      developer.log('Error inserting or updating cart item: $e', error: e);
    }
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    loggedInUsername = prefs.getString('username') ?? '';
  }

  Future<void> _selectCustomer() async {
    final Customer? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetails(
          onSelectionChanged: _updateSelectedCustomer,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedCustomer = result;
        _loadSalesOrders();
      });
    }
  }

  void _updateSelectedCustomer(Customer customer) {
    setState(() {
      selectedCustomer = customer;
      _loadSalesOrders();
    });
  }

  Future<void> _loadSalesOrders({int? days, DateTimeRange? dateRange}) async {
  setState(() => isLoading = true);
  String orderByClause = 'ORDER BY cart.created ${isSortedAscending ? 'ASC' : 'DESC'}';
  String usernameFilter = "AND salesman.username = '$loggedInUsername'";
  String customerFilter = selectedCustomer != null
      ? "AND cart.customer_id = '${selectedCustomer!.id}'"
      : "";
  String query;

  if (dateRange != null) {
    String startDate = DateFormat('yyyy-MM-dd').format(dateRange.start);
    String endDate = DateFormat('yyyy-MM-dd').format(dateRange.end);
    query = '''
      SELECT 
      cart.*, 
      cart_item.product_id,
      cart_item.product_name, 
      cart_item.qty,
      cart_item.uom,
      cart_item.ori_unit_price,
      salesman.salesman_name,
      DATE_FORMAT(cart.created, '%d/%m/%Y') AS created_date
      FROM 
          cart
      JOIN 
          cart_item ON cart.session = cart_item.session OR cart.id = cart_item.cart_id
      JOIN 
          salesman ON cart.buyer_id = salesman.id
      WHERE 
      cart.created BETWEEN '$startDate' AND '$endDate'
      $usernameFilter
      $customerFilter
      $orderByClause;
    ''';
    developer.log('Query with dateRange: $query');
  } else if (days != null) {
    query = '''
      SELECT 
      cart.*, 
      cart_item.product_id,
      cart_item.product_name, 
      cart_item.qty,
      cart_item.uom,
      cart_item.ori_unit_price,
      salesman.salesman_name,
      DATE_FORMAT(cart.created, '%d/%m/%Y') AS created_date
      FROM 
          cart
      JOIN 
          cart_item ON cart.session = cart_item.session OR cart.id = cart_item.cart_id
      JOIN 
          salesman ON cart.buyer_id = salesman.id
      WHERE 
      cart.created >= DATE_SUB(CURDATE(), INTERVAL $days DAY)
      $usernameFilter
      $customerFilter
      $orderByClause;
    ''';
    developer.log('Query with days: $query');
  } else {
    query = '''
      SELECT 
      cart.*, 
      cart_item.product_id,
      cart_item.product_name, 
      cart_item.qty,
      cart_item.uom,
      cart_item.ori_unit_price,
      salesman.salesman_name,
      DATE_FORMAT(cart.created, '%d/%m/%Y') AS created_date
      FROM 
          cart
      JOIN 
          cart_item ON cart.session = cart_item.session OR cart.id = cart_item.cart_id
      JOIN 
      salesman ON cart.buyer_id = salesman.id
      $usernameFilter
      $customerFilter
      $orderByClause;
    ''';
    developer.log('Default query: $query');
  }

  try {
    orders = await executeQuery(query);
  } catch (e, stackTrace) {
    developer.log('Failed to load orders: $e', error: e, stackTrace: stackTrace);
  } finally {
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Order',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF004C87),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: <Widget>[
          _buildFilterSection(),
          Expanded(child: _buildSalesOrderList()),
        ],
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _buildCustomerPicker(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateRangePicker(),
              _buildSortButton(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildQuickAccessDateButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomerPicker() {
    return InkWell(
      onTap: _selectCustomer,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedCustomer?.companyName ?? 'Select Customer',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessDateButtons() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildDateButton('All', null, 3),
          const SizedBox(width: 10),
          _buildDateButton('Last 7d', 7, 0),
          const SizedBox(width: 10),
          _buildDateButton('Last 30d', 30, 1),
          const SizedBox(width: 10),
          _buildDateButton('Last 90d', 90, 2),
        ],
      ),
    );
  }

  void toggleSortOrder() {
    setState(() {
      isSortedAscending = !isSortedAscending;
      _loadSalesOrders(days: selectedDays, dateRange: dateRange);
    });
  }

  Widget _buildSortButton() {
    return TextButton.icon(
      onPressed: toggleSortOrder,
      icon: Icon(
        isSortedAscending ? Icons.arrow_upward : Icons.arrow_downward,
        color: Colors.black,
      ),
      label: const Text(
        'Sort',
        style: TextStyle(color: Colors.black),
      ),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFD9D9D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    final bool isCustomRangeSelected = dateRange != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          onPressed: () => _selectDateRange(context),
          icon: Icon(
            Icons.calendar_today,
            color: isCustomRangeSelected
                ? Colors.white
                : Theme.of(context).iconTheme.color,
          ),
          label: Text(
            isCustomRangeSelected
                ? '${DateFormat('dd/MM/yyyy').format(dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange!.end)}'
                : 'Filter Date',
            style: TextStyle(
              color: isCustomRangeSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: isCustomRangeSelected
                ? const Color(0xFF047CBD)
                : const Color(0xFFD9D9D9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(String text, int? days, int index) {
  bool isSelected = selectedButtonIndex == index;
  return TextButton(
    onPressed: () {
      setState(() {
        selectedButtonIndex = index;
        selectedDays = days;
        dateRange = null;
        _loadSalesOrders(days: selectedDays);
      });
    },
    style: TextButton.styleFrom(
      backgroundColor: isSelected ? const Color(0xFF047CBD) : const Color(0xFFD9D9D9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : Colors.black,
      ),
    ),
  );
}


  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004C87),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      setState(() {
        dateRange = newDateRange;
        selectedDays = null;
        _loadSalesOrders(dateRange: dateRange);
      });
    }
  }

  Widget _buildSalesOrderList() {
    if (isLoading) {
      return ListView.builder(
        itemCount: 6, // Number of shimmer items to show while loading
        itemBuilder: (context, index) {
          return _buildShimmerSalesOrderItem();
        },
      );
    }

    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No data found',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedOrders = {};
    for (final item in orders) {
      String orderId = item['id'].toString();
      if (!groupedOrders.containsKey(orderId)) {
        groupedOrders[orderId] = [];
      }
      groupedOrders[orderId]!.add(item);
    }

    List<String> orderIds = groupedOrders.keys.toList();

    return ListView.builder(
      itemCount: orderIds.length,
      itemBuilder: (context, index) {
        String orderId = orderIds[index];
        List<Map<String, dynamic>> items = groupedOrders[orderId]!;
        Map<String, dynamic> firstItem = items.first;

        return _buildSalesOrderItem(
          context: context,
          index: index,
          orderNumber: orderId,
          companyName: firstItem['customer_company_name'] ?? 'Unknown Company',
          creationDate: firstItem['created_date'] != null
              ? DateFormat('dd/MM/yyyy').parse(firstItem['created_date'])
              : DateTime.now(),
          amount: '${firstItem['final_total']?.toStringAsFixed(2) ?? '0.00'}',
          status: firstItem['status'] ?? 'Unknown Status',
          items: items,
        );
      },
    );
  }

  Widget _buildShimmerSalesOrderItem() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 20,
                                        width: 150,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 20,
                                        width: 100,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 20,
                                        width: 200,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 20,
                                        width: 100,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 6,
                    child: Container(
                      height: 20,
                      width: 100,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ExpansionTile(
              title: Container(
                height: 20,
                width: 100,
                color: Colors.white,
              ),
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 20,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesOrderItem({
    required BuildContext context,
    required int index,
    required String orderNumber,
    required String companyName,
    required DateTime creationDate,
    required String amount,
    required String status,
    required List<Map<String, dynamic>> items,
  }) {
    String getDisplayStatus(String status) {
      if (status == 'in progress') {
        return 'Pending';
      }
      return status;
    }

    Color getStatusColor(String displayStatus) {
      switch (displayStatus) {
        case 'Confirm':
          return Colors.green;
        case 'Pending':
          return const Color.fromARGB(255, 213, 155, 8);
        case 'Void':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    Widget getStatusLabel(String status) {
      String displayStatus = getDisplayStatus(status);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: getStatusColor(displayStatus),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayStatus,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }

    String formattedOrderNumber = 'S${orderNumber.toString().padLeft(7, '0')}';
    int orderId = int.parse(orderNumber);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderDetailsPage(cartID: orderId)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${index + 1}. $formattedOrderNumber',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        companyName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Created on: ${DateFormat('dd-MM-yyyy').format(creationDate)}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'RM $amount',
                                        style: const TextStyle(
                                          color:
                                          Color.fromARGB(255, 76, 175, 80),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 6,
                    child: getStatusLabel(status),
                  ),
                ],
              ),
            ),
            ExpansionTile(
              title: const Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              children: items
                  .map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['product_name']} ${item['uom']} X${item['qty']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        final cartItem = CartItem(
                          buyerId: await UtilityFunction.getUserId(),
                          productId: item['product_id'],
                          productName: item['product_name'],
                          uom: item['uom'],
                          quantity: item['qty'],
                          discount: 0,
                          originalUnitPrice: item['ori_unit_price'],
                          unitPrice: item['ori_unit_price'],
                          total: item['ori_unit_price'] * item['qty'],
                          cancel: null,
                          remark: null,
                          status: 'in progress',
                          created: DateTime.now(),
                          modified: DateTime.now(),
                        );

                        await insertItemIntoCart(cartItem);
                        showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            backgroundColor: Colors.green,
                            title: Row(
                              children: [
                                SizedBox(width: 20),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Item copied to cart',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        Future.delayed(const Duration(seconds: 1), () {
                          Navigator.pop(context);
                        });
                      },
                    ),
                  ],
                ),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
