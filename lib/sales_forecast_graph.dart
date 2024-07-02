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
  Future<List<SalesForecast>>? salesForecasts;
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails().then((_) {
      if (mounted) {
        setState(() {
          salesForecasts = fetchSalesForecasts();
        });
      }
    });
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        loggedInUsername = prefs.getString('username') ?? '';
      });
    }
  }

  Future<List<SalesForecast>> fetchSalesForecasts() async {
    var db = await connectToDatabase();
    var results = await db.query('''
      SELECT 
          salesman.id AS salesman_id,
          salesman.salesman_name,
          MONTH(cart.created) AS purchase_month,
          YEAR(cart.created) AS purchase_year,
          SUM(cart.final_total) AS total_sales,
          SUM(cart_item.qty) AS cart_quantity
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
          salesman.id, salesman.salesman_name, purchase_month, purchase_year
      ORDER BY 
          purchase_year DESC, purchase_month DESC
      LIMIT 2;
    ''');

    List<SalesForecast> forecasts = [];
    for (var row in results) {
      final salesmanId = row['salesman_id'] as int;
      final salesmanName = row['salesman_name'] as String;
      final purchaseMonth = row['purchase_month'] as int;
      final purchaseYear = row['purchase_year'] as int;
      final totalSales = (row['total_sales'] as num).toDouble();
      final cartQuantity = (row['cart_quantity'] is num &&
              (row['cart_quantity'] as num).isFinite)
          ? (row['cart_quantity'] as num).toInt()
          : 0;
      forecasts.add(SalesForecast(
        salesmanId: salesmanId,
        salesmanName: salesmanName,
        purchaseMonth: purchaseMonth,
        purchaseYear: purchaseYear,
        totalSales: totalSales,
        cartQuantity: cartQuantity,
        previousMonthSales: 0.0,
        previousCartQuantity: 0,
      ));
    }

    print('Forecasts fetched: ${forecasts.length}');

    double predictedTarget = 0.0;
    int stockNeeded = 0;

    if (forecasts.length == 2) {
      predictedTarget = (forecasts[0].totalSales + forecasts[1].totalSales) / 2;
      stockNeeded =
          ((forecasts[0].cartQuantity + forecasts[1].cartQuantity) / 2).round();
    }

    if (forecasts.isNotEmpty) {
      forecasts[0] = SalesForecast(
        salesmanId: forecasts[0].salesmanId,
        salesmanName: forecasts[0].salesmanName,
        purchaseMonth: forecasts[0].purchaseMonth,
        purchaseYear: forecasts[0].purchaseYear,
        totalSales: forecasts[0].totalSales,
        cartQuantity: forecasts[0].cartQuantity,
        previousMonthSales: forecasts.length > 1 ? forecasts[1].totalSales : 0.0,
        previousCartQuantity: forecasts.length > 1 ? forecasts[1].cartQuantity : 0,
        predictedTarget: predictedTarget,
        stockNeeded: stockNeeded,
      );
    }

    await db.close();
    return forecasts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Sales Forecast',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              FutureBuilder<List<SalesForecast>>(
                future: salesForecasts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    if (snapshot.data == null || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No sales forecast data available.'));
                    }

                    if (snapshot.data!.length < 2) {
                      return const Center(child: Text('Not enough data for prediction.'));
                    }

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
                        predictedTarget: 0.0,
                        stockNeeded: 0,
                      ),
                    );

                    return EditableSalesTargetCard(
                      currentSales: currentMonthData.totalSales,
                      predictedTarget: currentMonthData.predictedTarget,
                      cartQuantity: currentMonthData.cartQuantity,
                      stockNeeded: currentMonthData.stockNeeded,
                      previousMonthSales: currentMonthData.previousMonthSales,
                      previousCartQuantity: currentMonthData.previousCartQuantity,
                      loggedInUsername: loggedInUsername,
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ],
          ),
        ),
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
    super.key,
    required this.currentSales,
    required this.predictedTarget,
    required this.cartQuantity,
    required this.stockNeeded,
    required this.previousMonthSales,
    required this.previousCartQuantity,
    required this.loggedInUsername,
  });

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
      SELECT sales_target
      FROM sales_targets
      WHERE username = ?
      AND purchase_month = ?
      AND purchase_year = ?
    ''', [widget.loggedInUsername, currentMonth, currentYear]);

    if (results.isNotEmpty) {
      final salesTarget = results.first['sales_target'] as double;
      setState(() {
        _salesTarget = _currencyFormat.format(salesTarget);
      });
    }

    await db.close();
  }

  @override
  Widget build(BuildContext context) {
    double salesTargetValue = 0.0;
    try {
      salesTargetValue =
          double.parse(_salesTarget.replaceAll(RegExp(r'[^\d.]'), ''));
    } catch (e) {
      salesTargetValue = 1.0;
    }

    double progressValue =
        (widget.currentSales / salesTargetValue).clamp(0.0, 1.0);

    double completionPercentage =
        (widget.currentSales / salesTargetValue) * 100;
    completionPercentage = completionPercentage.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: Card(
              color: const Color.fromARGB(255, 222, 247, 255),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                            SizedBox(width: 8.0),
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
                        const SizedBox(width: 8.0),
                        Text(
                          '${completionPercentage.toStringAsFixed(0)}% Complete',
                          style: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w500,
                              color: Color.fromRGBO(0, 57, 104, 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Current Sales: ${NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 2).format(widget.currentSales)}',
                      style: const TextStyle(
                          fontSize: 17.0,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 0, 122, 4)),
                    ),
                    const SizedBox(height: 4.0),
                    LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 14.0,
                      backgroundColor: const Color.fromRGBO(112, 112, 112, 0.37),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color.fromARGB(255, 0, 150, 5)),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14.0),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                InfoBox(
                  label: 'Monthly Revenue',
                  value:
                      NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 2).format(widget.currentSales),
                  currentValue: widget.currentSales,
                  previousValue: widget.previousMonthSales,
                  isUp: widget.currentSales >= widget.previousMonthSales,
                  isDown: widget.currentSales < widget.previousMonthSales,
                  backgroundColor: const Color(0x300F9D58),
                  textColor: const Color(0xFF508155),
                  fromLastMonthTextColor: Colors.black87,
                ),
                InfoBox(
                  label: 'Predicted Target',
                  value: _currencyFormat.format(widget.predictedTarget),
                  currentValue: widget.predictedTarget,
                  previousValue: widget.previousMonthSales,
                  isUp: widget.predictedTarget >= widget.previousMonthSales,
                  isDown: widget.predictedTarget < widget.previousMonthSales,
                  backgroundColor: const Color(0x49004C87),
                  textColor: const Color(0xFF004C87),
                  fromLastMonthTextColor: Colors.black87,
                ),
                InfoBox(
                  label: 'Stock Sold',
                  value: '${widget.cartQuantity}',
                  currentValue: widget.cartQuantity.toDouble(),
                  previousValue: widget.previousCartQuantity.toDouble(),
                  isUp: widget.cartQuantity >= widget.previousCartQuantity,
                  isDown: widget.cartQuantity < widget.previousCartQuantity,
                  backgroundColor: const Color(0xFF004C87),
                  textColor: Colors.white,
                  fromLastMonthTextColor: Colors.white,
                ),
                InfoBox(
                  label: 'Predicted Stock',
                  value: '${widget.stockNeeded}',
                  currentValue: widget.stockNeeded.toDouble(),
                  previousValue: widget.previousCartQuantity.toDouble(),
                  isUp: widget.stockNeeded >= widget.previousCartQuantity,
                  isDown: widget.stockNeeded < widget.previousCartQuantity,
                  backgroundColor: const Color(0xFF709640),
                  textColor: Colors.white,
                  fromLastMonthTextColor: Colors.white,
                ),
              ],
            ),
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
          title: const Text('Edit Sales Target'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'New Sales Target'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Save'),
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
      SET sales_target = ?
      WHERE username = ?
      AND purchase_month = ?
      AND purchase_year = ?
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
  final Color backgroundColor;
  final Color textColor;
  final Color fromLastMonthTextColor;

  const InfoBox({
    super.key,
    required this.label,
    required this.value,
    required this.currentValue,
    this.previousValue,
    this.isUp = false,
    this.isDown = false,
    required this.backgroundColor,
    required this.textColor,
    required this.fromLastMonthTextColor,
  });

  @override
  Widget build(BuildContext context) {
    double previousSales = previousValue ?? 0.0;
    double change = 0.0;

    if (!currentValue.isNaN && !previousSales.isNaN && previousSales != 0.0) {
      change = ((currentValue - previousSales) / previousSales) * 100;
    } else {
      change = 0.0;
    }

    change = change.clamp(-100.0, 100.0);

    bool isIncrease = change >= 0;

    Color increaseColor;
    if (label == 'Stock Sold' || label == 'Predicted Stock') {
      increaseColor = const Color.fromARGB(255, 0, 255, 13);
    } else {
      increaseColor = const Color.fromARGB(255, 0, 117, 6);
    }

    Widget icon;
    switch (label) {
      case 'Monthly Revenue':
        icon = const Icon(Icons.monetization_on, color: Color(0xFF508155));
        break;
      case 'Predicted Target':
        icon = const Icon(Icons.gps_fixed, color: Color(0xFF004C87));
        break;
      case 'Stock Sold':
        icon = const Icon(Icons.outbox, color: Colors.white);
        break;
      case 'Predicted Stock':
        icon = const Icon(Icons.inbox, color: Colors.white);
        break;
      default:
        icon = const SizedBox.shrink();
    }

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              icon,
            ],
          ),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          if (isUp || isDown) ...[
            Text(
              '${isIncrease ? '▲ Up' : '▼ Down'} ${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: isIncrease ? increaseColor : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'From Last Month',
              style: TextStyle(
                  color: fromLastMonthTextColor,
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
  final double predictedTarget;
  final int stockNeeded;

  SalesForecast({
    required this.salesmanId,
    required this.salesmanName,
    required this.purchaseMonth,
    required this.purchaseYear,
    required this.totalSales,
    required this.cartQuantity,
    required this.previousMonthSales,
    required this.previousCartQuantity,
    this.predictedTarget = 0.0,
    this.stockNeeded = 0,
  });
}
