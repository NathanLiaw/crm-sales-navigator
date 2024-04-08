import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_connection.dart'; // Import your database connection utility
import 'package:intl/intl.dart';
import 'dart:math' as math;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SalesReport(),
    );
  }
}

class SalesReport extends StatefulWidget {
  @override
  _SalesReportState createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> {
  Map<String, List<SalesData>> _salesDataMap = {};
  String _selectedInterval = 'Weekly';

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    // Preload data for all intervals
    await _fetchData('Weekly');
    await _fetchData('Monthly');
    await _fetchData('Yearly');
  }

  Future<void> _fetchData(String interval) async {
    List<SalesData> fetchedData;
    switch (interval) {
      case 'Weekly':
        fetchedData = await fetchSalesData('Week');
        break;
      case 'Monthly':
        fetchedData = await fetchSalesData('Month');
        break;
      case 'Yearly':
        fetchedData = await fetchSalesData('Year');
        break;
      default:
        fetchedData = [];
    }
    setState(() {
      _salesDataMap[interval] = fetchedData;
    });
  }

  Future<List<SalesData>> fetchSalesData(String reportType) async {
    var db = await connectToDatabase();
    late String query;

    switch (reportType) {
    case 'Week':
      query = '''
    SELECT 
        Dates.`Date`,
        DATE_FORMAT(Dates.`Date`, '%a') AS `Day`, -- Short form of the day
        IFNULL(DailySales.`Total Sales`, 0) AS `Total Sales`
    FROM (
        SELECT CURDATE() - INTERVAL 6 DAY AS `Date`
        UNION ALL SELECT CURDATE() - INTERVAL 5 DAY
        UNION ALL SELECT CURDATE() - INTERVAL 4 DAY
        UNION ALL SELECT CURDATE() - INTERVAL 3 DAY
        UNION ALL SELECT CURDATE() - INTERVAL 2 DAY
        UNION ALL SELECT CURDATE() - INTERVAL 1 DAY
        UNION ALL SELECT CURDATE()
    ) AS Dates
    LEFT JOIN (
        SELECT 
            DATE(ci.created) AS `Date`,
            ROUND(SUM(ci.total), 0) AS `Total Sales`
        FROM cart_item ci
        WHERE ci.created BETWEEN CURDATE() - INTERVAL 6 DAY AND CURDATE() -- Include data for the current day
        GROUP BY DATE(ci.created)
    ) AS DailySales ON Dates.`Date` = DailySales.`Date`
    ORDER BY Dates.`Date` ASC;
      ''';
      break;

      case 'Month':
        query = '''
SELECT 
    Dates.`Date`,
    DATE_FORMAT(Dates.`Date`, '%a') AS `Day`, -- Short form of the day
    IFNULL(DailySales.`Total Sales`, 0) AS `Total Sales`
FROM (
    SELECT CURDATE() - INTERVAL 6 DAY AS `Date`
    UNION ALL SELECT CURDATE() - INTERVAL 5 DAY
    UNION ALL SELECT CURDATE() - INTERVAL 4 DAY
    UNION ALL SELECT CURDATE() - INTERVAL 3 DAY
    UNION ALL SELECT CURDATE() - INTERVAL 2 DAY
    UNION ALL SELECT CURDATE() - INTERVAL 1 DAY
    UNION ALL SELECT CURDATE()
) AS Dates
LEFT JOIN (
    SELECT 
        DATE(ci.created) AS `Date`,
        ROUND(SUM(ci.total), 0) AS `Total Sales`
    FROM cart_item ci
    WHERE ci.created BETWEEN CURDATE() - INTERVAL 6 DAY AND CURDATE()
    GROUP BY DATE(ci.created)
) AS DailySales ON Dates.`Date` = DailySales.`Date`
ORDER BY Dates.`Date` ASC;
        ''';
        break;
      case 'Year':
        query = '''
          SELECT
              GeneratedYears.Year AS `Year`,
              IFNULL(SUM(YearlySales.`Total Sales`), 0) AS `Total Sales`
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
                  YEAR(ci.created) AS Year,
                  ROUND(SUM(ci.total), 0) AS `Total Sales`
              FROM 
                  cart_item ci
              WHERE 
                  ci.created >= CURDATE() - INTERVAL 6 YEAR
              GROUP BY 
                  YEAR(ci.created)
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
      return SalesData(
        date: row['Date'] != null ? row['Date'] as DateTime : DateTime.now(),
        totalSales: row['Total Sales'] != null
            ? (row['Total Sales'] as num).toDouble()
            : 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sales Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedInterval,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedInterval = newValue;
                  });
                }
              },
              items: <String>['Weekly', 'Monthly', 'Yearly']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: _salesDataMap[_selectedInterval] != null
          ? _salesDataMap[_selectedInterval]!.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
                  child: LineChart(
                    sampleData(_salesDataMap[_selectedInterval]!),
                  ),
                )
              : Center(
                  child: Text('No data available'),
                )
          : Center(
              child: CircularProgressIndicator(),
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
      ),
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          showTitles: true,
          getTitles: (value) =>
              value % (maxY / 6) == 0 ? '${value.toInt()}' : '',
          interval: maxY / 6,
          reservedSize: 40,
        ),
bottomTitles: SideTitles(
  showTitles: true,
  getTitles: (value) {
    if (salesData.isEmpty) return '';

    int index = value.toInt();
    int lastIndex = salesData.length - 1;

    if (_selectedInterval == 'Weekly') {
      // Display weekdays for the current week
      if (index == lastIndex) {
        // Return current day for the last point
        return DateFormat('EEE').format(DateTime.now());
      } else {
        // Display previous days
        DateTime currentDate = DateTime.now();
        DateTime date =
            currentDate.subtract(Duration(days: lastIndex - index));
        return DateFormat('EEE').format(date);
      }
    } else if (_selectedInterval == 'Monthly') {
      // Display months
      if (index == lastIndex) {
        // Return current month for the last point
        return DateFormat('MMM').format(DateTime.now());
      } else {
        // Display previous months
        DateTime date = DateTime.now()
            .subtract(Duration(days: (lastIndex - index) * 30));
        return DateFormat('MMM').format(date);
      }
    } else {
      // Display years
      if (index == lastIndex) {
        // Return current year for the last point
        return DateFormat('yyyy').format(DateTime.now());
      } else {
        // Display previous years
        return (DateTime.now().year - (lastIndex - index)).toString();
      }
    }
  },
  reservedSize: 22,
),

      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
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
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            colors: [Colors.blue.withOpacity(0.3)],
          ),
          aboveBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueAccent,
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
            return LineTooltipItem(
              'RM ${spot.y.toInt()}',
              const TextStyle(color: Colors.white),
            );
          }).toList(),
        ),
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
