import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_connection.dart';

class SalesForecastGraph extends StatefulWidget {
  const SalesForecastGraph({super.key});

  @override
  _SalesForecastGraphState createState() => _SalesForecastGraphState();
}

class _SalesForecastGraphState extends State<SalesForecastGraph> {
  late Future<List<SalesForecast>> salesForecasts;
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails().then((_) {
      salesForecasts = fetchSalesForecasts();
    });
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? '';
    });
  }

  Future<List<SalesForecast>> fetchSalesForecasts() async {
    var db = await connectToDatabase();
    var results = await db.query('''
      SELECT 
        salesman.id AS salesman_id,
        salesman.salesman_name,
        MONTH(cart.created) AS Purchase_Month,
        YEAR(cart.created) AS Purchase_Year,
        SUM(cart.final_total) AS Total_Sales,
        SUM(cart_item.qty) AS Cart_Quantity
      FROM 
        cart
      JOIN 
        salesman ON cart.buyer_id = salesman.id 
      JOIN 
        cart_item ON cart.session = cart_item.session OR cart.id = cart_item.cart_id
      WHERE 
        cart.buyer_user_group != 'customer' 
        AND cart.status != 'void' 
        AND cart_item.status != 'void' 
        AND salesman.username = '$loggedInUsername'
      GROUP BY 
        salesman.id, Purchase_Month, Purchase_Year
      ORDER BY 
        Purchase_Year DESC, Purchase_Month DESC;
    ''');

    List<SalesForecast> forecasts = [];
    for (var row in results) {
      final salesmanId = row['salesman_id'] as int;
      final salesmanName = row['salesman_name'] as String;
      final purchaseMonth = row['Purchase_Month'] as int;
      final purchaseYear = row['Purchase_Year'] as int;
      final totalSales = (row['Total_Sales'] as num).toDouble();
      final cartQuantity = (row['Cart_Quantity'] as num).toInt();

      var previousMonthResults = await db.query('''
        SELECT 
          COALESCE(SUM(cart.final_total), 0) AS Previous_Month_Sales,
          COALESCE(SUM(cart_item.qty), 0) AS Previous_Cart_Quantity
        FROM 
          cart
        JOIN 
          salesman ON cart.buyer_id = salesman.id 
        JOIN 
          cart_item ON cart.session = cart_item.session OR cart.id = cart_item.cart_id
        WHERE 
          cart.buyer_user_group != 'customer' 
          AND cart.status != 'void' 
          AND cart_item.status != 'void' 
          AND salesman.username = '$loggedInUsername'
          AND MONTH(cart.created) = MONTH(CURRENT_DATE() - INTERVAL 1 MONTH) 
          AND YEAR(cart.created) = YEAR(CURRENT_DATE() - INTERVAL 1 MONTH);
      ''');

      final previousMonthSales =
          (previousMonthResults.first['Previous_Month_Sales'] as num)
              .toDouble();
      final previousCartQuantity =
          (previousMonthResults.first['Previous_Cart_Quantity'] as num).toInt();

      forecasts.add(SalesForecast(
        salesmanId: salesmanId,
        salesmanName: salesmanName,
        purchaseMonth: purchaseMonth,
        purchaseYear: purchaseYear,
        totalSales: totalSales,
        cartQuantity: cartQuantity,
        previousMonthSales: previousMonthSales,
        previousCartQuantity: previousCartQuantity,
      ));
    }

    await db.close();
    return forecasts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Sales Forecast',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<SalesForecast>>(
            future: salesForecasts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                final currentMonthData = snapshot.data!.firstWhere(
                  (forecast) => forecast.purchaseMonth == DateTime.now().month,
                  orElse: () => SalesForecast(
                    salesmanId: 0,
                    salesmanName: '',
                    purchaseMonth: DateTime.now().month,
                    purchaseYear: DateTime.now().year,
                    totalSales: 0.0,
                    cartQuantity: 0,
                    previousMonthSales: 0.0,
                    previousCartQuantity: 0,
                  ),
                );

                if (currentMonthData != null) {
                  return EditableSalesTargetCard(
                    currentSales: currentMonthData.totalSales,
                    predictedTarget:
                        70850.0,
                    cartQuantity: currentMonthData.cartQuantity,
                    stockNeeded:
                        3000,
                    previousMonthSales: currentMonthData.previousMonthSales,
                    previousCartQuantity: currentMonthData.previousCartQuantity,
                    loggedInUsername: loggedInUsername,
                  );
                } else {
                  return Text('No data available for the current month');
                }
              } else {
                return Text('No data');
              }
            },
          ),
        ],
      ),
    );
  }
}

class EditableSalesTargetCard extends StatefulWidget {
  final double currentSales;
  final double predictedTarget;
  final int cartQuantity;
  final int stockNeeded;
  final double previousMonthSales;
  final int previousCartQuantity;
  final String loggedInUsername;

  const EditableSalesTargetCard({
    Key? key,
    required this.currentSales,
    required this.predictedTarget,
    required this.cartQuantity,
    required this.stockNeeded,
    required this.previousMonthSales,
    required this.previousCartQuantity,
    required this.loggedInUsername,
  }) : super(key: key);

  @override
  _EditableSalesTargetCardState createState() =>
      _EditableSalesTargetCardState();
}

class _EditableSalesTargetCardState extends State<EditableSalesTargetCard> {
  late final NumberFormat _currencyFormat;
  late String _salesTarget;

  @override
  void initState() {
    super.initState();
    _currencyFormat =
        NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 2);
    _salesTarget = _currencyFormat.format(0);
    _fetchSalesTarget();
  }

  Future<void> _fetchSalesTarget() async {
    var db = await connectToDatabase();
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    var results = await db.query('''
      SELECT Sales_Target
      FROM sales_targets
      WHERE username = ?
      AND Purchase_Month = ?
      AND Purchase_Year = ?
    ''', [widget.loggedInUsername, currentMonth, currentYear]);

    if (results.isNotEmpty) {
      final salesTarget = results.first['Sales_Target'] as double;
      setState(() {
        _salesTarget = _currencyFormat.format(salesTarget);
      });
    }

    await db.close();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Color.fromARGB(255, 222, 247, 255),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Sales Target',
                          style: TextStyle(
                              fontSize: 24.0, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 16.0),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.grey[800]),
                        onPressed: _editSalesTarget,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _salesTarget,
                      style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(0, 57, 104, 1)),
                    ),
                    const SizedBox(width: 16.0),
                    Text(
                      '${((widget.currentSales / double.parse(_salesTarget.replaceAll(RegExp(r'[^\d.]'), ''))) * 100).toStringAsFixed(0)}% Complete',
                      style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(0, 57, 104, 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Current Sales: RM ${widget.currentSales.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 0, 122, 4)),
                ),
                const SizedBox(height: 8.0),
                LinearProgressIndicator(
                  value: widget.currentSales /
                      double.parse(
                          _salesTarget.replaceAll(RegExp(r'[^\d.]'), '')),
                  minHeight: 14.0,
                  backgroundColor: Color.fromRGBO(112, 112, 112, 0.37),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 0, 150, 5)),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.0),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 180,
                height: 125,
                child: InfoBox(
                  label: 'Monthly Revenue',
                  value:
                      '${NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 2).format(widget.currentSales)}',
                  currentValue: widget.currentSales,
                  previousValue: widget.previousMonthSales,
                  isUp: true,
                  isDown: false,
                ),
              ),
              SizedBox(
                width: 180,
                height: 125,
                child: InfoBox(
                  label: 'Predicted Target',
                  value: 'RM ${widget.predictedTarget.toStringAsFixed(2)}',
                  currentValue: 0,
                  previousValue: 0,
                  isUp: true,
                  isDown: false,
                ),
              ),
              SizedBox(
                width: 180,
                height: 125,
                child: 
              InfoBox(
                label: 'Stock Sold',
                value: '${widget.cartQuantity}',
                currentValue: widget.cartQuantity.toDouble(),
                previousValue: widget.previousCartQuantity.toDouble(),
                isUp: true,
                isDown: false,
              ),
              ),
              SizedBox(
                width: 180,
                height: 125,
                child: InfoBox(
                  label: 'Predicted Stock',
                  value: '${widget.stockNeeded}',
                  currentValue: 0,
                  previousValue: 0,
                  isUp: true,
                  isDown: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editSalesTarget() async {
    final newSalesTarget = await showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text('Edit Sales Target'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'New Sales Target'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (newSalesTarget != null) {
      setState(() {
        _salesTarget = _currencyFormat.format(double.parse(newSalesTarget));
      });

      await updateSalesTargetInDatabase(double.parse(newSalesTarget));
    }
  }

  Future<void> updateSalesTargetInDatabase(double newSalesTarget) async {
    var db = await connectToDatabase();
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    await db.query('''
      UPDATE sales_targets
      SET Sales_Target = ?
      WHERE username = ?
      AND Purchase_Month = ?
      AND Purchase_Year = ?
    ''', [newSalesTarget, widget.loggedInUsername, currentMonth, currentYear]);

    await db.close();
  }
}

class InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final double currentValue;
  final double? previousValue;
  final bool isUp;
  final bool isDown;

  const InfoBox({
    Key? key,
    required this.label,
    required this.value,
    required this.currentValue,
    this.previousValue,
    this.isUp = false,
    this.isDown = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double previousSales = previousValue ?? 0.0;
    double change = 0.0;

    if (previousSales != 0.0 && currentValue != null) {
      change = ((currentValue - previousSales) / previousSales) * 100;
    } else {
      change = 0.0;
    }

    change = change.clamp(-100.0, 100.0);

    bool isIncrease = change >= 0;

    Color backgroundColor = Colors.white;
    if (label == 'Monthly Revenue') {
      backgroundColor = Color.fromARGB(255, 229, 255, 224);
    } else if (label == 'Predicted Target') {
      backgroundColor = Color.fromARGB(255, 222, 247, 255);
    } else if (label == 'Stock Sold') {
      backgroundColor = Color.fromARGB(255, 222, 247, 255);
    } else if (label == 'Predicted Stock') {
      backgroundColor = Color.fromARGB(255, 229, 255, 224);
    }

    Widget icon;
    switch (label) {
      case 'Monthly Revenue':
        icon = Icon(Icons.monetization_on);
        break;
      case 'Predicted Target':
        icon = Icon(Icons.gps_fixed);
        break;
      case 'Stock Sold':
        icon = Icon(Icons.outbox);
        break;
      case 'Predicted Stock':
        icon = Icon(Icons.inbox);
        break;
      default:
        icon = SizedBox.shrink();
    }

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              icon,
            ],
          ),
          SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          if (isUp || isDown) ...[
            Text(
              '${isIncrease ? '▲ Up' : '▼ Down'} ${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: isIncrease ? Color.fromARGB(255, 0, 145, 5) : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            const Text(
              'From Last Month',
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

class SalesForecast {
  final int salesmanId;
  final String salesmanName;
  final int purchaseMonth;
  final int purchaseYear;
  final double totalSales;
  final int cartQuantity;
  final double previousMonthSales;
  final int previousCartQuantity;

  SalesForecast({
    required this.salesmanId,
    required this.salesmanName,
    required this.purchaseMonth,
    required this.purchaseYear,
    required this.totalSales,
    required this.cartQuantity,
    required this.previousMonthSales,
    required this.previousCartQuantity,
  });
}
