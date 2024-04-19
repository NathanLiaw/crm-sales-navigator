import 'package:flutter/material.dart';
import 'db_connection.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Total Income Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SalesReportPage(),
    );
  }
}

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  _SalesReportPageState createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  late Future<List<SalesData>> salesData;
  late String selectedReportType;

  @override
  void initState() {
    super.initState();
    selectedReportType = 'Week';
    salesData = fetchSalesData(selectedReportType);
  }

  Future<List<SalesData>> fetchSalesData(String reportType) async {
    var db = await connectToDatabase();
    late String query;

    switch (reportType) {
      case 'Week':
        query = '''
SELECT 
    Dates.`Date`,
    DAYNAME(Dates.`Date`) AS `Day`,
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
ORDER BY Dates.`Date` DESC;


        ''';
        break;
      case 'Month':
        query = '''
        SELECT
    GeneratedMonths.YearMonth,
    GeneratedMonths.MonthName,
    IFNULL(SUM(MonthlySales.`Total Sales`), 0) AS `Total Sales`
FROM (
    SELECT DATE_FORMAT(CURDATE() - INTERVAL c.num MONTH, '%Y-%m') AS YearMonth,
           DATE_FORMAT(CURDATE() - INTERVAL c.num MONTH, '%M %Y') AS MonthName
    FROM (
        SELECT 0 AS num UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL
        SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
        SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
        SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
    ) AS c
) AS GeneratedMonths
LEFT JOIN (
    SELECT 
        DATE_FORMAT(ci.created, '%Y-%m') AS YearMonth,
        ci.total AS `Total Sales`
    FROM cart_item ci
    WHERE ci.created >= CURDATE() - INTERVAL 12 MONTH
) AS MonthlySales ON GeneratedMonths.YearMonth = MonthlySales.YearMonth
GROUP BY GeneratedMonths.YearMonth, GeneratedMonths.MonthName
ORDER BY GeneratedMonths.YearMonth DESC;

        ''';
        break;
      case 'Year':
        query = '''
          SELECT
              GeneratedYears.Year AS `Year`,
              IFNULL(SUM(YearlySales.`Total Sales`), 0) AS `Total Sales`
          FROM (
              SELECT YEAR(CURDATE()) AS Year
              UNION ALL SELECT YEAR(CURDATE()) - 1
              UNION ALL SELECT YEAR(CURDATE()) - 2
              UNION ALL SELECT YEAR(CURDATE()) - 3
              UNION ALL SELECT YEAR(CURDATE()) - 4
              UNION ALL SELECT YEAR(CURDATE()) - 5
          ) AS GeneratedYears
          LEFT JOIN (
              SELECT 
                  YEAR(ci.created) AS Year,
                  ci.total AS `Total Sales`
              FROM cart_item ci
              WHERE ci.created >= CURDATE() - INTERVAL 6 YEAR
          ) AS YearlySales ON GeneratedYears.Year = YearlySales.Year
          GROUP BY GeneratedYears.Year
          ORDER BY GeneratedYears.Year DESC;
          ''';
        break;
    }

    var results = await db.query(query);

    return results.map((row) {
      return SalesData(
        day: row['Day'] ??
            row['MonthName']?.toString() ??
            row['Year']?.toString(),
        date: row['Date'], // Adding date to SalesData object
        totalSales: row['Total Sales'] != null
            ? (row['Total Sales'] as num).toDouble()
            : null,
      );
    }).toList();
  }

  void changeReportType(String newReportType) {
    setState(() {
      selectedReportType = newReportType;
      salesData = fetchSalesData(selectedReportType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF004C87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Total Income Report',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 16.0),
            child: Align(
              alignment: Alignment.topRight,
              child: DropdownButton<String>(
                value: selectedReportType,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    changeReportType(newValue);
                  }
                },
                items: ['Week', 'Month', 'Year']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SalesData>>(
              future: salesData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error.toString()}'));
                } else if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];
                      return Column(
                        children: [
                          ListTile(
                            title: Text(item.day != null ? item.day! : '',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: selectedReportType == 'Week' &&
                                    item.date !=
                                        null // Check if report type is 'Week' and date is available
                                ? Text(
                                    'Date: ${_formatDate(item.date!)}', // Display date in the required format
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null, // If not 'Week' or date is null, don't show subtitle
                          ),
                          if (item.totalSales != null)
                            ListTile(
                              title: Text(
                                  'Total Sales: RM ${item.totalSales!.toStringAsFixed(2)}'),
                            ),
                          const Divider(color: Colors.grey),
                        ],
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No data available'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format the DateTime object as "dd-mm-yyyy"
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString()}';
  }
}

class SalesData {
  final String? day;
  final DateTime? date; // Changed type to DateTime

  final double? totalSales;

  SalesData({
    this.day,
    this.date,
    this.totalSales,
  });
}
