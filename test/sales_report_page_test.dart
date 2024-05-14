import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesReportPage', () {
    late _SalesReportPageState state;

    setUp(() {
      state = _SalesReportPageState();
      state._loggedInUsername = 'testuser';
    });

    test(
        'fetchSalesData should return sales data for the specified report type',
        () async {
      // Arrange
      List<Map<String, dynamic>> salesDataList = [
        {'Day': 'Mon', 'Date': DateTime(2023, 6, 5), 'Total Sales': 100.0},
        {'Day': 'Tue', 'Date': DateTime(2023, 6, 6), 'Total Sales': 200.0},
        {'Day': 'Wed', 'Date': DateTime(2023, 6, 7), 'Total Sales': 150.0},
        {'MonthName': 'June 2023', 'Total Sales': 1000.0},
        {'MonthName': 'May 2023', 'Total Sales': 800.0},
        {'Year': '2023', 'Total Sales': 5000.0},
        {'Year': '2022', 'Total Sales': 4000.0},
      ];

      // Act
      List<SalesData> weeklyData = await state.fetchSalesData('Week');
      List<SalesData> monthlyData = await state.fetchSalesData('Month');
      List<SalesData> yearlyData = await state.fetchSalesData('Year');

      // Assert
      expect(weeklyData.length, 3);
      expect(weeklyData[0].day, 'Mon');
      expect(weeklyData[0].date, DateTime(2023, 6, 5));
      expect(weeklyData[0].totalSales, 100.0);

      expect(monthlyData.length, 2);
      expect(monthlyData[0].day, 'June 2023');
      expect(monthlyData[0].totalSales, 1000.0);

      expect(yearlyData.length, 2);
      expect(yearlyData[0].day, '2023');
      expect(yearlyData[0].totalSales, 5000.0);
    });

    test(
        'changeReportType should update the selected report type and fetch new sales data',
        () async {
      // Arrange
      List<Map<String, dynamic>> salesDataList = [
        {'Day': 'Mon', 'Date': DateTime(2023, 6, 5), 'Total Sales': 100.0},
        {'Day': 'Tue', 'Date': DateTime(2023, 6, 6), 'Total Sales': 200.0},
        {'Day': 'Wed', 'Date': DateTime(2023, 6, 7), 'Total Sales': 150.0},
        {'MonthName': 'June 2023', 'Total Sales': 1000.0},
        {'MonthName': 'May 2023', 'Total Sales': 800.0},
        {'Year': '2023', 'Total Sales': 5000.0},
        {'Year': '2022', 'Total Sales': 4000.0},
      ];

      // Act
      state.changeReportType('Month');
      List<SalesData> monthlyData = await state.salesData;

      // Assert
      expect(state.selectedReportType, 'Month');
      expect(monthlyData.length, 2);
      expect(monthlyData[0].day, 'June 2023');
      expect(monthlyData[0].totalSales, 1000.0);

      // Act
      state.changeReportType('Year');
      List<SalesData> yearlyData = await state.salesData;

      // Assert
      expect(state.selectedReportType, 'Year');
      expect(yearlyData.length, 2);
      expect(yearlyData[0].day, '2023');
      expect(yearlyData[0].totalSales, 5000.0);
    });
  });
}

class _SalesReportPageState {
  late Future<List<SalesData>> salesData;
  late String selectedReportType;
  late String _loggedInUsername;

  void initState() {
    selectedReportType = 'Week';
    _loggedInUsername = '';
    salesData = fetchSalesData(selectedReportType);
  }

  Future<List<SalesData>> fetchSalesData(String reportType) async {
    // Simulated sales data
    List<Map<String, dynamic>> salesDataList = [
      {'Day': 'Mon', 'Date': DateTime(2023, 6, 5), 'Total Sales': 100.0},
      {'Day': 'Tue', 'Date': DateTime(2023, 6, 6), 'Total Sales': 200.0},
      {'Day': 'Wed', 'Date': DateTime(2023, 6, 7), 'Total Sales': 150.0},
      {'MonthName': 'June 2023', 'Total Sales': 1000.0},
      {'MonthName': 'May 2023', 'Total Sales': 800.0},
      {'Year': '2023', 'Total Sales': 5000.0},
      {'Year': '2022', 'Total Sales': 4000.0},
    ];

    // Filter sales data based on the selected report type
    List<SalesData> filteredData = [];
    switch (reportType) {
      case 'Week':
        filteredData = salesDataList
            .where((data) => data['Day'] != null)
            .map((data) => SalesData(
                  day: data['Day'],
                  date: data['Date'],
                  totalSales: data['Total Sales'],
                ))
            .toList();
        break;
      case 'Month':
        filteredData = salesDataList
            .where((data) => data['MonthName'] != null)
            .map((data) => SalesData(
                  day: data['MonthName'],
                  totalSales: data['Total Sales'],
                ))
            .toList();
        break;
      case 'Year':
        filteredData = salesDataList
            .where((data) => data['Year'] != null)
            .map((data) => SalesData(
                  day: data['Year'],
                  totalSales: data['Total Sales'],
                ))
            .toList();
        break;
    }

    return filteredData;
  }

  void changeReportType(String newReportType) {
    selectedReportType = newReportType;
    salesData = fetchSalesData(selectedReportType);
  }
}

class SalesReportPage extends StatelessWidget {
  const SalesReportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder build method
    return Container();
  }
}

class SalesData {
  final String? day;
  final DateTime? date;
  final double? totalSales;

  SalesData({this.day, this.date, this.totalSales});
}
