import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(top:16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Sales Orders Status',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const OrderStatusWidget(),
              ),
              const SizedBox(height: 32),
              const InProgressOrdersWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderStatusWidget extends StatelessWidget {
  const OrderStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            top: 12.0,
            left: 16.0,
          ),
          child: Text(
            'Order Status',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const OrderStatusIndicator(),
        ),
      ],
    );
  }
}

class OrderStatusIndicator extends StatefulWidget {
  const OrderStatusIndicator({super.key});

  @override
  _OrderStatusIndicatorState createState() => _OrderStatusIndicatorState();
}

class _OrderStatusIndicatorState extends State<OrderStatusIndicator> {
  int complete = 0;
  int pending = 0;
  int voided = 0;
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    loadUsernameAndFetchData();
  }

  Future<void> loadUsernameAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';
    setState(() {
      loggedInUsername = username;
    });
    await fetchDataForDateRange(dateRange);
  }

  Future<void> fetchDataForDateRange(DateTimeRange selectedDateRange) async {
    var db = await connectToDatabase();

    if (loggedInUsername.isEmpty) {
      return;
    }

    String formattedStartDate = DateFormat('yyyy-MM-dd').format(selectedDateRange.start);
    String formattedEndDate = DateFormat('yyyy-MM-dd').format(selectedDateRange.end);

    var results = await db.query(
      '''SELECT 
        COUNT(*) AS Total,
        CASE 
            WHEN c.status = 'confirm' THEN 'Complete'
            WHEN c.status = 'Pending' THEN 'Pending'
            ELSE 'Void'
        END AS status,
        s.username
      FROM 
        cart AS c
      JOIN 
        salesman AS s ON c.buyer_id = s.id
      WHERE 
        c.created BETWEEN ? AND ? AND 
        c.buyer_user_group = 'salesman' AND 
        s.username = ?
      GROUP BY 
        status, s.username;
      ''',
      [formattedStartDate, formattedEndDate, loggedInUsername],
    );

    int completeOrders = 0;
    int pendingOrders = 0;
    int voidedOrders = 0;

    for (var row in results) {
      String status = row['status'] as String;
      int count = row['Total'] as int;
      if (status == 'Complete') {
        completeOrders += count;
      } else if (status == 'Pending') {
        pendingOrders += count;
      } else if (status == 'Void') {
        voidedOrders += count;
      }
    }

    setState(() {
      complete = completeOrders;
      pending = pendingOrders;
      voided = voidedOrders;
    });

    await db.close();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth),
      firstDate: DateTime(2019),
      lastDate: DateTime(2025),
    );

    if (pickedRange != null && pickedRange != dateRange) {
      setState(() {
        dateRange = pickedRange;
      });
      await fetchDataForDateRange(dateRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _selectDateRange(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 24.0),
                const SizedBox(width: 8),
                Text(
                  "${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Icon(Icons.arrow_drop_down, size: 24.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            // Complete Order Number
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$pending',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Orders Pending',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            CustomPaint(
              size: const Size(200, 200),
              painter: OrderStatusPainter(
                complete: complete,
                pending: pending,
                voided: voided,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusIndicator('Complete', Colors.green, complete),
            _buildStatusIndicator('Pending', Colors.blue, pending),
            _buildStatusIndicator('Void', Colors.red, voided),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, Color color, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.brightness_1, color: color, size: 12),
          const SizedBox(width: 4),
          Text('$label $value'),
        ],
      ),
    );
  }
}

class OrderStatusPainter extends CustomPainter {
  final int complete;
  final int pending;
  final int voided;
  final double lineWidth;

  OrderStatusPainter({
    required this.complete,
    required this.pending,
    required this.voided,
    this.lineWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - lineWidth / 2;
    final total = complete + pending + voided;
    const sweepAngle = 2 * 3.141592653589793238462643383279502884197;

    Paint paintComplete = Paint()
      ..color = Colors.green
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    Paint paintPending = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    Paint paintVoided = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    double startAngle = -3.141592653589793238462643383279502884197 / 2;

    double completeSweep = sweepAngle * (complete / total);
    double pendingSweep = sweepAngle * (pending / total);
    double voidedSweep = sweepAngle * (voided / total);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      completeSweep,
      false,
      paintComplete,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + completeSweep,
      pendingSweep,
      false,
      paintPending,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + completeSweep + pendingSweep,
      voidedSweep,
      false,
      paintVoided,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class InProgressOrdersWidget extends StatelessWidget {
  const InProgressOrdersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'In Progress Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<InProgressOrder>>(
          future: fetchInProgressOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...snapshot.data!.map((order) => Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          order.date,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4), 
                        Center(
                          child: Text(
                            '${order.status} Orders',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    )),
                  ],
                ),
              );
            } else {
              return const Text('No data');
            }
          },
        ),
      ],
    );
  }

  Future<List<InProgressOrder>> fetchInProgressOrders() async {
    var db = await connectToDatabase();
    var results = await db.query(
      'SELECT id, CASE WHEN status = Pending ELSE status END AS status, created FROM cart;',
    );

    List<InProgressOrder> inProgressOrders = [];
    for (var row in results) {
      inProgressOrders.add(
        InProgressOrder(
          row['created'].toString(),
          row['status'].toString(),
        ),
      );
    }
    await db.close();
    return inProgressOrders;
  }
}

class InProgressOrder {
  final String date;
  final String status;

  InProgressOrder(this.date, this.status);
}
