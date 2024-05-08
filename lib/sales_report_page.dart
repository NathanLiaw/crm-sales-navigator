import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_connection.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  _SalesReportPageState createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  late Future<List<SalesData>> salesData;
  late String selectedReportType;
  String _loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    selectedReportType = 'Week';
    _loadUsername().then((_) {
      salesData = fetchSalesData(selectedReportType);
    });
  }

  Future<void> _loadUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';
    setState(() {
      _loggedInUsername = username;
    });
  }

  Future<List<SalesData>> fetchSalesData(String reportType) async {
    var db = await connectToDatabase();
    late String query;

    // Using the username in the query to filter data
    String usernameCondition = " AND s.username = '$_loggedInUsername'";

    switch (reportType) {
      case 'Week':
        query = '''
          SELECT 
              Dates.`Date`,
              DATE_FORMAT(Dates.`Date`, '%a') AS `Day`,
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
                  DATE(c.created) AS `Date`,
                  ROUND(SUM(c.final_total), 0) AS `Total Sales`
              FROM cart c
              JOIN Salesman s ON c.buyer_id = s.id AND c.buyer_user_group != 'customer'
              WHERE c.created BETWEEN CURDATE() - INTERVAL 6 DAY AND CURDATE()
              AND c.status != 'void' $usernameCondition
              GROUP BY DATE(c.created)
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
                  SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL
                  SELECT 12 -- Adjusted to cover 13 months including the current month
              ) AS c
          ) AS GeneratedMonths
          LEFT JOIN (
              SELECT 
                  DATE_FORMAT(c.created, '%Y-%m') AS YearMonth,
                  ROUND(SUM(c.final_total), 0) AS `Total Sales`
              FROM cart c
              JOIN Salesman s ON c.buyer_id = s.id AND c.buyer_user_group != 'customer'
              WHERE c.created >= CURDATE() - INTERVAL 12 MONTH
              AND c.status != 'void' $usernameCondition
              GROUP BY DATE_FORMAT(c.created, '%Y-%m')
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
                    YEAR(c.created) AS Year,
                    ROUND(SUM(c.final_total), 0) AS `Total Sales`
                FROM cart c
                JOIN Salesman s ON c.buyer_id = s.id AND c.buyer_user_group != 'customer'
                WHERE c.created >= CURDATE() - INTERVAL 6 YEAR
                AND c.status != 'void' $usernameCondition
                GROUP BY YEAR(c.created)
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
        date: row['Date'],
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              item.day != null ? item.day! : '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: selectedReportType == 'Week' &&
                                    item.date != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date: ${_formatDate(item.date!)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total Sales: RM ${item.totalSales!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color.fromARGB(255, 0, 100, 0),
                                        ),
                                      ),
                                    ],
                                  )
                                : selectedReportType == 'Month' ||
                                        selectedReportType == 'Year'
                                    ? Text(
                                        'Total Sales: RM ${item.totalSales!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Color.fromARGB(255, 0, 100, 0),
                                        ),
                                      )
                                    : null,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 16),
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
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString()}';
  }
}

class SalesData {
  final String? day;
  final DateTime? date;
  final double? totalSales;

  SalesData({this.day, this.date, this.totalSales});
}