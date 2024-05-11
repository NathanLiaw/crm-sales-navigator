import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'db_connection.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesForecastGraph extends StatefulWidget {
  const SalesForecastGraph({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
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
        salesman.username,
        cart.buyer_user_group,
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
        AND cart_item.status != 'void' AND Salesman.username = '$loggedInUsername'
        AND MONTH(cart.created) = MONTH(CURRENT_DATE())
        AND YEAR(cart.created) = YEAR(CURRENT_DATE())
    GROUP BY 
        salesman.id, Purchase_Month, Purchase_Year, buyer_user_group
    ORDER BY 
        Total_Sales;

  ''');

    List<SalesForecast> forecasts = [];
    for (var row in results) {
      final salesmanId = row['salesman_id'] as int;
      final salesmanName = row['salesman_name'] as String;
      final purchaseMonth = row['Purchase_Month'] as int;
      final purchaseYear = row['Purchase_Year'] as int;
      final totalSales = (row['Total_Sales'] as num).toDouble();

      forecasts.add(SalesForecast(
        salesmanId: salesmanId,
        salesmanName: salesmanName,
        purchaseMonth: purchaseMonth,
        purchaseYear: purchaseYear,
        totalSales: totalSales,
      ));
    }

    await db.close();
    return forecasts;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
              return Column(
                children: [
                  EditableSalesTargetCard(
                    currentSales: snapshot.data!
                        .fold(0, (sum, forecast) => sum + forecast.totalSales),
                    loggedInUsername: loggedInUsername,
                  ),
                ],
              );
            } else {
              return Text('No data');
            }
          },
        ),
      ],
    );
  }
}

class EditableSalesTargetCard extends StatefulWidget {
  final double currentSales;
  final String loggedInUsername;

  const EditableSalesTargetCard(
      {Key? key, required this.currentSales, required this.loggedInUsername})
      : super(key: key);

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
    return Card(
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
                SizedBox(width: 16.0),
                Text(
                  '${((widget.currentSales / double.parse(_salesTarget.replaceAll(RegExp(r'[^\d.]'), ''))) * 100).toStringAsFixed(0)}% Complete',
                  style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(0, 57, 104, 1)),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              'Current Sales: RM ${widget.currentSales.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 0, 122, 4)),
            ),
            SizedBox(height: 8.0),
            LinearProgressIndicator(
              value: widget.currentSales /
                  double.parse(_salesTarget.replaceAll(RegExp(r'[^\d.]'), '')),
              minHeight: 14.0,
              backgroundColor: Color.fromRGBO(112, 112, 112, 0.37),
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 0, 150, 5)),
            ),
            SizedBox(height: 8.0),
          ],
        ),
      ),
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

class SalesForecast {
  final int salesmanId;
  final String salesmanName;
  final int purchaseMonth;
  final int purchaseYear;
  final double totalSales;

  SalesForecast({
    required this.salesmanId,
    required this.salesmanName,
    required this.purchaseMonth,
    required this.purchaseYear,
    required this.totalSales,
  });
}
