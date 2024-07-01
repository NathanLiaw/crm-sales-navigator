import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_connection.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme.light(
          primary: Colors.lightBlue,
          onPrimary: Colors.white,
          surface: Colors.lightBlue,
        ),
        iconTheme: const IconThemeData(color: Colors.lightBlue),
      ),
      home: const SalesReport(),
    );
  }
}

class SalesReport extends StatefulWidget {
  const SalesReport({super.key});

  @override
  _SalesReportState createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> {
  final Map<String, List<SalesData>> _salesDataMap = {};
  String _selectedInterval = '3D';
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _loadUsername().then((_) {
      _preloadData();
    });
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? 'default_username';
    });
  }

  Future<void> _preloadData() async {
    await _fetchData('3D');
    await _fetchData('5D');
    await _fetchData('1M');
    await _fetchData('1Y');
    await _fetchData('5Y');
  }

  Future<void> _fetchData(String interval) async {
    List<SalesData> fetchedData;
    switch (interval) {
      case '3D':
        fetchedData = await fetchSalesData('ThreeDays');
        break;
      case '5D':
        fetchedData = await fetchSalesData('FiveDays');
        break;
      case '1M':
        fetchedData = await fetchSalesData('FourMonths');
        break;
      case '1Y':
        fetchedData = await fetchSalesData('Year');
        break;
      case '5Y':
        fetchedData = await fetchSalesData('FiveYears');
        break;
      default:
        fetchedData = [];
    }
    if (mounted) {
      setState(() {
        _salesDataMap[interval] = fetchedData;
      });
    }
  }

  Future<List<SalesData>> fetchSalesData(String reportType) async {
    var db = await connectToDatabase();
    late String query;

    switch (reportType) {
      case 'ThreeDays':
        query = '''
      SELECT 
          Dates.Date,
          DATE_FORMAT(Dates.Date, '%Y-%m-%d') AS Date,
          IFNULL(DailySales.TotalSales, 0) AS TotalSales
      FROM (
          SELECT CURDATE() - INTERVAL 2 DAY AS Date
          UNION ALL SELECT CURDATE() - INTERVAL 1 DAY
          UNION ALL SELECT CURDATE()
      ) AS Dates
      LEFT JOIN (
          SELECT 
              DATE(c.created) AS Date,
              ROUND(SUM(c.final_total), 0) AS TotalSales
          FROM cart c
          JOIN salesman s ON c.buyer_id = s.id AND c.buyer_user_group = 'salesman'
          WHERE c.created >= CURDATE() - INTERVAL 2 DAY
            AND c.status != 'void'
            AND s.username = '$loggedInUsername'
          GROUP BY DATE(c.created)
      ) AS DailySales ON Dates.Date = DailySales.Date
      ORDER BY Dates.Date ASC;
      ''';
        break;
      case 'FiveDays':
        query = '''
      SELECT 
          Dates.Date,
          DATE_FORMAT(Dates.Date, '%Y-%m-%d') AS Date,
          IFNULL(DailySales.TotalSales, 0) AS TotalSales
      FROM (
          SELECT CURDATE() - INTERVAL 4 DAY AS Date
          UNION ALL SELECT CURDATE() - INTERVAL 3 DAY
          UNION ALL SELECT CURDATE() - INTERVAL 2 DAY
          UNION ALL SELECT CURDATE() - INTERVAL 1 DAY
          UNION ALL SELECT CURDATE()
      ) AS Dates
      LEFT JOIN (
          SELECT 
              DATE(c.created) AS Date,
              ROUND(SUM(c.final_total), 0) AS TotalSales
          FROM cart c
          JOIN salesman s ON c.buyer_id = s.id AND c.buyer_user_group = 'salesman'
          WHERE c.created >= CURDATE() - INTERVAL 4 DAY
            AND c.status != 'void'
            AND s.username = '$loggedInUsername'
          GROUP BY DATE(c.created)
      ) AS DailySales ON Dates.Date = DailySales.Date
      ORDER BY Dates.Date ASC;
      ''';
        break;
      case 'FourMonths':
        query = '''
      SELECT
          GeneratedMonths.Month AS Date,
          IFNULL(SUM(MonthlySales.TotalSales), 0) AS TotalSales
      FROM (
          SELECT 
              DATE_FORMAT(CURDATE() - INTERVAL a.a MONTH, '%Y-%m') AS Month
          FROM (SELECT 0 AS a UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3) a
      ) AS GeneratedMonths
      LEFT JOIN (
          SELECT 
              DATE_FORMAT(c.created, '%Y-%m') AS Month,
              ROUND(SUM(c.final_total), 0) AS TotalSales
          FROM cart c
          JOIN salesman s ON c.buyer_id = s.id AND c.buyer_user_group = 'salesman'
          WHERE c.created >= CURDATE() - INTERVAL 4 MONTH
            AND c.status != 'void'
            AND s.username = '$loggedInUsername'
          GROUP BY DATE_FORMAT(c.created, '%Y-%m')
      ) AS MonthlySales ON GeneratedMonths.Month = MonthlySales.Month
      GROUP BY GeneratedMonths.Month
      ORDER BY GeneratedMonths.Month ASC;
      ''';
        break;
      case 'Year':
        query = '''
      SELECT
          GeneratedMonths.Month AS Date,
          IFNULL(SUM(MonthlySales.TotalSales), 0) AS TotalSales
      FROM (
          SELECT 
              DATE_FORMAT(CURDATE() - INTERVAL a.a MONTH, '%Y-%m') AS Month
          FROM (SELECT 0 AS a UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11) a
      ) AS GeneratedMonths
      LEFT JOIN (
          SELECT 
              DATE_FORMAT(c.created, '%Y-%m') AS Month,
              ROUND(SUM(c.final_total), 0) AS TotalSales
          FROM cart c
          JOIN salesman s ON c.buyer_id = s.id AND c.buyer_user_group = 'salesman'
          WHERE c.created >= CURDATE() - INTERVAL 12 MONTH
            AND c.status != 'void'
            AND s.username = '$loggedInUsername'
          GROUP BY DATE_FORMAT(c.created, '%Y-%m')
      ) AS MonthlySales ON GeneratedMonths.Month = MonthlySales.Month
      GROUP BY GeneratedMonths.Month
      ORDER BY GeneratedMonths.Month ASC;
      ''';
        break;
      case 'FiveYears':
        query = '''
        SELECT
            GeneratedYears.Year AS Year,
            IFNULL(SUM(YearlySales.TotalSales), 0) AS TotalSales
        FROM (
            SELECT 
                YEAR(CURDATE()) AS Year
            UNION ALL SELECT 
                YEAR(CURDATE()) - 1
            UNION ALL SELECT 
                YEAR(CURDATE()) - 2
            UNION ALL SELECT 
                YEAR(CURDATE()) - 3
            UNION ALL SELECT 
                YEAR(CURDATE()) - 4
            UNION ALL SELECT 
                YEAR(CURDATE()) - 5
        ) AS GeneratedYears
        LEFT JOIN (
            SELECT 
                YEAR(c.created) AS Year,
                ROUND(SUM(c.final_total), 0) AS TotalSales
            FROM 
                cart c
            JOIN salesman s ON c.buyer_id = s.id AND c.buyer_user_group = 'salesman'
            WHERE 
                c.created >= CURDATE() - INTERVAL 5 YEAR
              AND 
                c.status != 'void' AND s.username = '$loggedInUsername'
            GROUP BY 
                YEAR(c.created)
        ) AS YearlySales ON GeneratedYears.Year = YearlySales.Year
        GROUP BY 
            GeneratedYears.Year
        ORDER BY 
            GeneratedYears.Year ASC;
      ''';
        break;
    }

    var results = await db.query(query);

    return results.map((row) {
      DateTime date;
      if (reportType == 'FiveYears') {
        date = DateTime(row['Year']);
      } else if (reportType == 'FourMonths' || reportType == 'Year') {
        date = DateFormat('yyyy-MM').parse(row['Date']);
      } else {
        date = DateFormat('yyyy-MM-dd').parse(row['Date']);
      }
      return SalesData(
        date: date,
        totalSales: row['TotalSales'] != null
            ? (row['TotalSales'] as num).toDouble()
            : 0,
      );
    }).toList();
  }

  void _refreshData() async {
    await _fetchData(_selectedInterval);
  }

  Widget _buildQuickAccessButton(String interval) {
    final bool isSelected = _selectedInterval == interval;
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedInterval = interval;
          _refreshData();
        });
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return isSelected
                ? const Color(0xFF047CBD)
                : const Color(0xFFD9D9D9);
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return isSelected ? Colors.white : Colors.black;
          },
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
      child: Text(interval, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Report',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAccessButton('3D'),
                  const SizedBox(width: 10),
                  _buildQuickAccessButton('5D'),
                  const SizedBox(width: 10),
                  _buildQuickAccessButton('1M'),
                  const SizedBox(width: 10),
                  _buildQuickAccessButton('1Y'),
                  const SizedBox(width: 10),
                  _buildQuickAccessButton('5Y'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _salesDataMap[_selectedInterval] != null
                ? _salesDataMap[_selectedInterval]!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 4.0),
                        child: Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.95,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24, horizontal: 18),
                              height: MediaQuery.of(context).size.height * 0.52,
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
                              child: LineChart(
                                sampleData(_salesDataMap[_selectedInterval]!),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text('No data available'),
                      )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ],
      ),
    );
  }

  LineChartData sampleData(List<SalesData> salesData) {
    List<FlSpot> spots = salesData
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.totalSales))
        .toList();

    double maxYValue = salesData.map((e) => e.totalSales).reduce(math.max);
    double topPadding = maxYValue <= 100 ? 40 : (maxYValue * 0.2);
    double maxY = maxYValue + topPadding;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        horizontalInterval: maxY / 6,
        getDrawingHorizontalLine: (value) => FlLine(
          color: const Color(0xffe7e8ec),
          strokeWidth: 1,
        ),
        drawVerticalLine: false,
      ),
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          showTitles: true,
          getTitles: (value) {
            if (value >= 1000) {
              return '${(value / 1000).toStringAsFixed(1)}K';
            } else {
              return value.toInt().toString();
            }
          },
          interval: maxY / 6,
          reservedSize: 40,
          margin: 8,
        ),
        bottomTitles: SideTitles(
          showTitles: true,
          getTitles: (value) {
            if (salesData.isEmpty) return '';

            int index = value.toInt();
            int lastIndex = salesData.length - 1;

            if (_selectedInterval == '3D' || _selectedInterval == '5D') {
              if (index >= 0 && index < salesData.length) {
                return DateFormat('EEE').format(salesData[index].date);
              }
            } else if (_selectedInterval == '1M') {
              if (index >= 0 && index < salesData.length) {
                return DateFormat('MMM yy').format(salesData[index].date);
              }
            } else if (_selectedInterval == '1Y') {
              int interval = (salesData.length / 4).round();
              if (index % interval == 0 || index == lastIndex) {
                if (index >= 0 && index < salesData.length) {
                  return DateFormat('MMM yy').format(salesData[index].date);
                }
              }
            } else if (_selectedInterval == '5Y') {
              if (index >= 0 && index < salesData.length) {
                return salesData[index].date.year.toString();
              }
            }
            return '';
          },
          reservedSize: 22,
          margin: 8,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 1),
          left: BorderSide(color: Colors.grey, width: 1),
          right: BorderSide.none,
          top: BorderSide.none,
        ),
      ),
      minX: 0,
      maxX: salesData.length.toDouble() - 1,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          colors: [Colors.blue],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            colors: [Colors.blue.withOpacity(0.3)],
            cutOffY: 0,
            applyCutOffY: true,
          ),
          aboveBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueAccent,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
            DateTime date = salesData[spot.spotIndex].date;
            String formattedDate;
            if (_selectedInterval == '3D' || _selectedInterval == '5D') {
              formattedDate = DateFormat('dd-MM-yyyy').format(date);
            } else if (_selectedInterval == '1M' || _selectedInterval == '1Y') {
              formattedDate = DateFormat('MMM yyyy').format(date);
            } else if (_selectedInterval == '5Y') {
              formattedDate = date.year.toString();
            } else {
              formattedDate = DateFormat('yyyy-MM-dd').format(date);
            }

            String formattedSales =
                'RM${spot.y.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

            return LineTooltipItem(
              'Date: $formattedDate\nSales: $formattedSales',
              const TextStyle(color: Colors.white),
            );
          }).toList(),
        ),
        handleBuiltInTouches: true,
      ),
    );
  }
}

class SalesData {
  final DateTime date;
  final double totalSales;

  SalesData({
    required this.date,
    required this.totalSales,
  });
}
