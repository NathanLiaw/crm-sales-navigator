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
      setState(() {
        salesForecasts = fetchSalesForecasts();
      });
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
        Purchase_Year DESC, Purchase_Month DESC
      LIMIT 2;  -- Fetch only the last two months
    ''');

    List<SalesForecast> forecasts = [];
    for (var row in results) {
      final salesmanId = row['salesman_id'] as int;
      final salesmanName = row['salesman_name'] as String;
      final purchaseMonth = row['Purchase_Month'] as int;
      final purchaseYear = row['Purchase_Year'] as int;
      final totalSales = (row['Total_Sales'] as num).toDouble();
      final cartQuantity = (row['Cart_Quantity'] is num && (row['Cart_Quantity'] as num).isFinite)
          ? (row['Cart_Quantity'] as num).toInt()
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

    double predictedTarget = 0.0;
    int stockNeeded = 0;

    if (forecasts.length == 2) {
      predictedTarget = (forecasts[0].totalSales + forecasts[1].totalSales) / 2;
      stockNeeded = ((forecasts[0].cartQuantity + forecasts[1].cartQuantity) / 2).round();
    }

    await db.close();

    if (forecasts.isNotEmpty) {
      forecasts[0] = SalesForecast(
        salesmanId: forecasts[0].salesmanId,
        salesmanName: forecasts[0].salesmanName,
        purchaseMonth: forecasts[0].purchaseMonth,
        purchaseYear: forecasts[0].purchaseYear,
        totalSales: forecasts[0].totalSales,
        cartQuantity: forecasts[0].cartQuantity,
        previousMonthSales: forecasts[1].totalSales,
        previousCartQuantity: forecasts[1].cartQuantity,
        predictedTarget: predictedTarget,
        stockNeeded: stockNeeded,
      );
    }

    return forecasts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
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
                    (forecast) =>
                        forecast.purchaseMonth == DateTime.now().month,
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
                  return CircularProgressIndicator();
                }
              },
            ),
          ],
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
    double salesTargetValue = 0.0;
    try {
      salesTargetValue =
          double.parse(_salesTarget.replaceAll(RegExp(r'[^\d.]'), ''));
    } catch (e) {
      salesTargetValue = 1.0; // Avoid division by zero or NaN
    }

    double progressValue = (widget.currentSales / salesTargetValue)
        .clamp(0.0, 1.0); // Ensure value is between 0 and 1

    double completionPercentage = (widget.currentSales / salesTargetValue) * 100;
    completionPercentage = completionPercentage.clamp(0, 100);

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
                      '${completionPercentage.toStringAsFixed(0)}% Complete',
                      style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(0, 57, 104, 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Current Sales: ${NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 2).format(widget.currentSales)}',
                  style: const TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 0, 122, 4)),
                ),
                const SizedBox(height: 8.0),
                LinearProgressIndicator(
                  value: progressValue,
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
                  isUp: widget.currentSales >= widget.previousMonthSales,
                  isDown: widget.currentSales < widget.previousMonthSales,
                  backgroundColor: Color(0x300F9D58),
                  textColor: Color(0xFF508155),
                  fromLastMonthTextColor: Colors.black87,
                ),
              ),
              SizedBox(
                width: 180,
                height: 125,
                child: InfoBox(
                  label: 'Predicted Target',
                  value: _currencyFormat.format(widget.predictedTarget),
                  currentValue: widget.predictedTarget,
                  previousValue: widget.previousMonthSales,
                  isUp: widget.predictedTarget >= widget.previousMonthSales,
                  isDown: widget.predictedTarget < widget.previousMonthSales,
                  backgroundColor: Color(0x49004C87),
                  textColor: Color(0xFF004C87),
                  fromLastMonthTextColor: Colors.black87,
                ),
              ),
              SizedBox(
                width: 180,
                height: 125,
                child: InfoBox(
                  label: 'Stock Sold',
                  value: '${widget.cartQuantity}',
                  currentValue: widget.cartQuantity.toDouble(),
                  previousValue: widget.previousCartQuantity.toDouble(),
                  isUp: widget.cartQuantity >= widget.previousCartQuantity,
                  isDown: widget.cartQuantity < widget.previousCartQuantity,
                  backgroundColor: Color(0xFF004C87),
                  textColor: Colors.white,
                  fromLastMonthTextColor: Colors.white,
                ),
              ),
              SizedBox(
                width: 180,
                height: 125,
                child: InfoBox(
                  label: 'Predicted Stock',
                  value: '${widget.stockNeeded}',
                  currentValue: widget.stockNeeded.toDouble(),
                  previousValue: widget.previousCartQuantity.toDouble(),
                  isUp: widget.stockNeeded >= widget.previousCartQuantity,
                  isDown: widget.stockNeeded < widget.previousCartQuantity,
                  backgroundColor: Color(0xFF709640),
                  textColor: Colors.white,
                  fromLastMonthTextColor: Colors.white,
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
  final Color backgroundColor;
  final Color textColor;
  final Color fromLastMonthTextColor;

  const InfoBox({
    Key? key,
    required this.label,
    required this.value,
    required this.currentValue,
    this.previousValue,
    this.isUp = false,
    this.isDown = false,
    required this.backgroundColor,
    required this.textColor,
    required this.fromLastMonthTextColor,
  }) : super(key: key);

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
      increaseColor = Color.fromARGB(255, 0, 255, 13);
    } else {
      increaseColor = Color.fromARGB(255, 0, 117, 6);
    }

    Widget icon;
    switch (label) {
      case 'Monthly Revenue':
        icon = Icon(Icons.monetization_on, color: Color(0xFF508155)); 
        break;
      case 'Predicted Target':
        icon = Icon(Icons.gps_fixed, color: Color(0xFF004C87));
        break;
      case 'Stock Sold':
        icon = Icon(Icons.outbox, color: Colors.white); 
        break;
      case 'Predicted Stock':
        icon = Icon(Icons.inbox, color: Colors.white);
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor)),
              icon,
            ],
          ),
          SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
          if (isUp || isDown) ...[
            Text(
              '${isIncrease ? '▲ Up' : '▼ Down'} ${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: isIncrease ? increaseColor : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
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
