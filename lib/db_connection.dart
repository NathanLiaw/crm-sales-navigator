import 'dart:convert';
import 'package:mysql1/mysql1.dart';

Future<MySqlConnection> connectToDatabase() async {
  final settings = ConnectionSettings(
    host: '10.0.2.2',
    port: 3306, // Default MySQL port
    user: 'root',
    password: '1234',
    db: 'fyh',
  );

  try {
    final conn = await MySqlConnection.connect(settings);
    await Future.delayed(Duration(seconds: 2));
    print('Connected to MySQL database');
    return conn;
  } catch (e) {
    print('Failed to connect to MySQL database: $e');
    throw Exception('Failed to connect to MySQL database');
  }
}

Future<List<Map<String, dynamic>>> readData(
  MySqlConnection connection,
  String tableName,
  String condition,
  String order,
  String field,
) async {
  String sqlQuery = '';
  String sqlOrder = '';
  if (condition.isNotEmpty) {
    sqlQuery = 'WHERE $condition';
  }
  if (order.isNotEmpty) {
    sqlOrder = 'ORDER BY $order';
  }
  final query = await connection.query(
    'SELECT $field FROM $tableName $sqlQuery $sqlOrder',
  );
  final results = <Map<String, dynamic>>[];
  for (var row in query) {
    final rowMap = Map<String, dynamic>.from(row.fields);
    // Convert Blob to string if necessary
    rowMap.forEach((key, value) {
      if (value is Blob) {
        final blob = value as Blob;
        // Convert Blob data to List<int>
        final bytes = blob.toString().codeUnits;
        // Decode bytes to String
        final stringValue = utf8.decode(bytes);
        rowMap[key] = stringValue;
      }
      // Convert DateTime to String
      if (value is DateTime) {
        final dateString =
            value.toString(); // Using toString() to get default format
        rowMap[key] = dateString;
      }
    });
    results.add(rowMap);
  }
  return results;
}
