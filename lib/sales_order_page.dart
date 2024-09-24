import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/cart_item.dart';
import 'package:sales_navigator/db_sqlite.dart';
import 'package:sales_navigator/order_details_page.dart';
import 'package:sales_navigator/utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'db_connection.dart';
import 'customer_details_page.dart';
import 'customer.dart';
import 'dart:developer' as developer;

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
  bool isSortedAscending = false; // Ensure this is set to false
  String loggedInUsername = '';
  Customer? selectedCustomer;

  final List<String> _sortingMethods = [
    'By Creation Date (Ascending)',
    'By Creation Date (Descending)',
    'By Amount (Low to High)',
    'By Amount (High to Low)',
  ];

  String _selectedMethod =
      'By Creation Date (Descending)'; // Default to descending

  final Map<String, bool> _statusFilters = {
    'Void': false,
    'Pending': false,
    'Confirm': false,
  };

  @override
  void initState() {
    super.initState();
    _loadUserDetails().then((_) {
      if (mounted) {
        _loadSalesOrders(days: selectedDays, dateRange: dateRange);
      }
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

  Future<void> insertAllItemsIntoCart(List<Map<String, dynamic>> items) async {
    try {
      for (var item in items) {
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
      }
      developer.log('All items copied to cart successfully');
    } catch (e) {
      developer.log('Error copying all items to cart: $e', error: e);
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
        _loadSalesOrders(days: selectedDays, dateRange: dateRange);
      });
    }
  }

  void _updateSelectedCustomer(Customer customer) {
    setState(() {
      selectedCustomer = customer;
      _loadSalesOrders(days: selectedDays, dateRange: dateRange);
    });
  }

  Future<void> _loadSalesOrders({int? days, DateTimeRange? dateRange}) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    String orderByClause =
        'ORDER BY ${_getOrderByField()} ${isSortedAscending ? 'ASC' : 'DESC'}';
    String usernameFilter = "AND salesman.username = '$loggedInUsername'";
    String customerFilter = selectedCustomer != null
        ? "AND cart.customer_id = '${selectedCustomer!.id}'"
        : "";
    String statusFilter = _statusFilters.entries
        .where((entry) => entry.value)
        .map((entry) => "cart.status = '${entry.key.toLowerCase()}'")
        .join(' OR ');

    if (statusFilter.isNotEmpty) {
      statusFilter = 'AND ($statusFilter)';
    }

    String query;

    if (dateRange != null) {
      String startDate =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(dateRange.start);
      String endDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateRange.end);
      query = '''
    SELECT 
    cart.*, 
    cart_item.product_id,
    cart_item.product_name, 
    cart_item.qty,
    cart_item.uom,
    cart_item.ori_unit_price,
    salesman.salesman_name,
    DATE_FORMAT(cart.created, '%d/%m/%Y %H:%i:%s') AS created_date
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
    $statusFilter
    $orderByClause;
    ''';
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
    DATE_FORMAT(cart.created, '%d/%m/%Y %H:%i:%s') AS created_date
    FROM 
        cart
    JOIN 
        cart_item ON cart.session = cart_item.session OR cart.id = cart_item.cart_id
    JOIN 
        salesman ON cart.buyer_id = salesman.id
    WHERE 
    cart.created >= DATE_SUB(NOW(), INTERVAL $days DAY)
    $usernameFilter
    $customerFilter
    $statusFilter
    $orderByClause;
    ''';
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
    DATE_FORMAT(cart.created, '%d/%m/%Y %H:%i:%s') AS created_date
    FROM 
        cart
    JOIN 
        cart_item ON cart.session = cart_item.session OR cart.id = cart_item.cart_id
    JOIN 
        salesman ON cart.buyer_id = salesman.id
    $usernameFilter
    $customerFilter
    $statusFilter
    $orderByClause;
    ''';
    }

    developer.log('Executing query: $query');

    try {
      orders = await executeQuery(query);
      developer
          .log('Query executed successfully, loaded orders: ${orders.length}');
    } catch (e, stackTrace) {
      developer.log('Failed to load orders: $e',
          error: e, stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      const tableName = 'cart';
      final data = {
        'id': orderId,
        'status': status,
        'modified': UtilityFunction.getCurrentDateTime(),
      };

      await DatabaseHelper.updateData(data, tableName);
      developer.log('Order status updated successfully');
      _loadSalesOrders(days: selectedDays, dateRange: dateRange);
    } catch (e) {
      developer.log('Error updating order status: $e', error: e);
    }
  }

  Future<void> _showItemSelectionDialog(
      List<Map<String, dynamic>> items) async {
    List<bool> checkedItems = List<bool>.filled(items.length, false);
    bool selectAll = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            var mediaQuery = MediaQuery.of(context);
            var screenHeight = mediaQuery.size.height;
            var screenWidth = mediaQuery.size.width;

            int selectedCount = checkedItems.where((item) => item).length;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(15),
                ),
                width: screenWidth * 0.95,
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Copy Items To Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF004072),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: Colors.grey, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '   Select Items: $selectedCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF004072),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            selectAll ? 'Unselect All' : 'Select All',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              selectAll = !selectAll;
                              for (int i = 0; i < checkedItems.length; i++) {
                                checkedItems[i] = selectAll;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (items.length == 1)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[0]['product_name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.045,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'UOM: ${items[0]['uom']}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'Qty: ${items[0]['qty']}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        leading: Checkbox(
                          value: checkedItems[0],
                          onChanged: (bool? value) {
                            if (mounted) {
                              setState(() {
                                checkedItems[0] = value!;
                                if (!value) selectAll = false;
                              });
                            }
                          },
                        ),
                      ),
                    if (items.length > 1)
                      Flexible(
                        child: SizedBox(
                          height: items.length <= 3 ? null : screenHeight * 0.5,
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  children: items.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    var item = entry.value;
                                    return Column(
                                      children: [
                                        CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          title: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['product_name'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        screenWidth * 0.045,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height:
                                                        screenHeight * 0.005),
                                                Text(
                                                  'UOM: ${item['uom']}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height:
                                                        screenHeight * 0.005),
                                                Text(
                                                  'Qty: ${item['qty']}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          value: checkedItems[index],
                                          onChanged: (bool? value) {
                                            if (mounted) {
                                              setState(() {
                                                checkedItems[index] = value!;
                                                if (!value) selectAll = false;
                                              });
                                            }
                                          },
                                        ),
                                        if (index != items.length - 1)
                                          const Divider(color: Colors.grey),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                            'Copy to cart',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: () async {
                            for (int i = 0; i < items.length; i++) {
                              if (checkedItems[i]) {
                                final item = items[i];
                                final oriUnitPrice =
                                    item['ori_unit_price'] ?? 0.0;
                                final qty = item['qty'] ?? 0;

                                final cartItem = CartItem(
                                  buyerId: await UtilityFunction.getUserId(),
                                  productId: item['product_id'],
                                  productName: item['product_name'],
                                  uom: item['uom'],
                                  quantity: qty,
                                  discount: 0,
                                  originalUnitPrice: oriUnitPrice,
                                  unitPrice: oriUnitPrice,
                                  total: oriUnitPrice * qty,
                                  cancel: null,
                                  remark: null,
                                  status: 'in progress',
                                  created: DateTime.now(),
                                  modified: DateTime.now(),
                                );
                                await insertItemIntoCart(cartItem);
                              }
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Selected items copied to cart',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                duration: Duration(seconds: 3),
                                backgroundColor: Color(0xFF487C08),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSortingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _sortingMethods.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              _sortingMethods[index],
                              style: TextStyle(
                                fontWeight:
                                    _selectedMethod == _sortingMethods[index]
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color: _selectedMethod == _sortingMethods[index]
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                            ),
                            trailing: _selectedMethod == _sortingMethods[index]
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedMethod = _sortingMethods[index];
                              });
                              Navigator.pop(context);
                              _sortResults();
                            },
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: _statusFilters.keys.map((String key) {
                          return CheckboxListTile(
                            title: Text(key),
                            value: _statusFilters[key],
                            onChanged: (bool? value) {
                              setState(() {
                                _statusFilters[key] = value!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF047CBD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _loadSalesOrders(
                              days: selectedDays, dateRange: dateRange);
                        },
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _sortResults() {
    setState(() {
      orders.sort((a, b) {
        switch (_selectedMethod) {
          case 'By Creation Date (Ascending)':
            return DateFormat('dd/MM/yyyy HH:mm:ss')
                .parse(a['created_date'])
                .compareTo(
                    DateFormat('dd/MM/yyyy HH:mm:ss').parse(b['created_date']));
          case 'By Creation Date (Descending)':
            return DateFormat('dd/MM/yyyy HH:mm:ss')
                .parse(b['created_date'])
                .compareTo(
                    DateFormat('dd/MM/yyyy HH:mm:ss').parse(a['created_date']));
          case 'By Amount (Low to High)':
            return a['final_total'].compareTo(b['final_total']);
          case 'By Amount (High to Low)':
            return b['final_total'].compareTo(a['final_total']);
          default:
            return DateFormat('dd/MM/yyyy HH:mm:ss')
                .parse(a['created_date'])
                .compareTo(
                    DateFormat('dd/MM/yyyy HH:mm:ss').parse(b['created_date']));
        }
      });
    });
  }

  int _calculateTotalQuantity(Map<String, dynamic> order) {
    int totalQuantity = 0;
    if (order.containsKey('items') && order['items'] is List) {
      for (final item in order['items']) {
        totalQuantity += (item['qty'] as num).toInt();
      }
    } else {
      developer.log('Order ${order['id']} does not contain valid items.');
    }
    developer.log('Total quantity for order ${order['id']}: $totalQuantity');
    return totalQuantity;
  }

  String _getOrderByField() {
    switch (_selectedMethod) {
      case 'By Creation Date (Ascending)':
      case 'By Creation Date (Descending)':
        return 'cart.created';
      case 'By Amount (Low to High)':
      case 'By Amount (High to Low)':
        return 'final_total';
      default:
        return 'cart.created';
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
              IconButton(
                onPressed: () => _showSortingOptions(context),
                icon: const Icon(Icons.sort, color: Colors.black),
              ),
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
      onTap: selectedCustomer == null ? _selectCustomer : null,
      child: Container(
        height: 50.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedCustomer?.companyName ?? 'Select Customer',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selectedCustomer != null)
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.grey),
                onPressed: _cancelSelectedCustomer,
                constraints: const BoxConstraints(maxHeight: 24.0),
                padding: EdgeInsets.zero,
              )
            else
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _cancelSelectedCustomer() {
    setState(() {
      selectedCustomer = null;
      _loadSalesOrders(days: selectedDays, dateRange: dateRange);
    });
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
          if (days != null) {
            DateTime now = DateTime.now();
            DateTime startDate = now.subtract(Duration(days: days));
            DateTime endDate = now;
            DateTimeRange newRange =
                DateTimeRange(start: startDate, end: endDate);

            dateRange = newRange;
            _loadSalesOrders(days: days, dateRange: newRange);
          } else {
            dateRange = null;
            _loadSalesOrders();
          }
        });
      },
      style: TextButton.styleFrom(
        backgroundColor:
            isSelected ? const Color(0xFF047CBD) : const Color(0xFFD9D9D9),
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
    DateTimeRange? newDateRange = await showRangePickerDialog(
      context: context,
      minDate: DateTime(DateTime.now().year - 5),
      maxDate: DateTime.now(),
      selectedRange: dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );

    if (newDateRange != null) {
      DateTime startOfDay = DateTime(newDateRange.start.year,
          newDateRange.start.month, newDateRange.start.day, 0, 0, 0);
      DateTime endOfDay = DateTime(newDateRange.end.year,
          newDateRange.end.month, newDateRange.end.day, 23, 59, 59);

      setState(() {
        dateRange = DateTimeRange(start: startOfDay, end: endOfDay);
        selectedDays = null;
        _loadSalesOrders(dateRange: dateRange);
      });
    }
  }

  Widget _buildSalesOrderList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
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
          index: index,
          orderNumber: orderId,
          companyName: firstItem['customer_company_name'] ?? 'Unknown Company',
          creationDate: firstItem['created_date'] != null
              ? DateFormat('dd/MM/yyyy').parse(firstItem['created_date'])
              : DateTime.now(),
          amount: '${firstItem['final_total']?.toStringAsFixed(3) ?? '0.000'}',
          status: firstItem['status'] ?? 'Unknown Status',
          items: items,
        );
      },
    );
  }

  Widget _buildSalesOrderItem({
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
          return const Color(0xFF487C08);
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
      onTap: () async {
        bool? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(cartID: orderId),
          ),
        );
        if (result == true) {
          _loadSalesOrders(days: selectedDays, dateRange: dateRange);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(111, 188, 249, 0.35),
            borderRadius: BorderRadius.circular(10.0),
          ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${index + 1}. $formattedOrderNumber',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          companyName,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Created on: ${DateFormat('dd-MM-yyyy').format(creationDate)}',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'RM $amount',
                                              style: const TextStyle(
                                                color: Color(0xFF487C08),
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy),
                                              onPressed: () async {
                                                await _showItemSelectionDialog(
                                                    items);
                                              },
                                            ),
                                          ],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: const Text(
                  'Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                children: [
                  Container(
                    color: const Color(0xFFE1F5FE),
                    child: Column(
                      children: items
                          .map((item) => Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 2, 16, 2),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['product_name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'UOM: ',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      item['uom'],
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Qty: ',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    item['qty'].toString(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(color: Colors.grey),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
