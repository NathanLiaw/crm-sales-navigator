import 'package:mysql1/mysql1.dart';
import 'dart:convert';

Future<MySqlConnection> connectToDatabase() async {
  final settings = ConnectionSettings(
    host: '10.0.2.2',
    port: 3306,
    user: 'root',
    password: '123456',
    db: 'fyh',
  );

  try {
    final conn = await MySqlConnection.connect(settings);
    await Future.delayed(const Duration(seconds: 1));
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

  print('SELECT $field FROM $tableName $sqlQuery $sqlOrder');

  final results = <Map<String, dynamic>>[];
  for (var row in query) {
    final rowMap = Map<String, dynamic>.from(row.fields);
    // Convert Blob to string if necessary
    rowMap.forEach((key, value) {
      if (value is Blob) {
        final blob = value;
        // Convert Blob data to List<int>
        final bytes = blob.toString().codeUnits;
        // Decode bytes to String
        final stringValue = utf8.decode(bytes);
        rowMap[key] = stringValue;
      }

      // Convert DateTime to String
      if (value is DateTime) {
        final dateString = value.toString();
        rowMap[key] = dateString;
      }
    });
    results.add(rowMap);
  }

  return results;
}

Future<int> countData(
    MySqlConnection connection, String tableName, String condition) async {
  String sqlQuery = '';

  if (condition.isNotEmpty) {
    sqlQuery = ' WHERE $condition';
  }

  try {
    final queryResult = await connection
        .query('SELECT COUNT(*) AS count FROM $tableName $sqlQuery');
    final rowCount = queryResult.first['count'] as int;
    return rowCount;
  } catch (e) {
    print('Error counting data: $e');
    return 0; // Return 0 if an error occurs
  }
}

Future<Map<String, dynamic>> readFirst(MySqlConnection connection,
    String tableName, String condition, String order) async {
  String sqlQuery = '';
  String sqlOrder = '';

  if (condition.isNotEmpty) {
    sqlQuery = ' WHERE $condition';
  }

  if (order.isNotEmpty) {
    sqlOrder = ' ORDER BY $order';
  }

  try {
    final queryResult = await connection
        .query('SELECT * FROM $tableName $sqlQuery $sqlOrder LIMIT 1');
    if (queryResult.isNotEmpty) {
      return Map<String, dynamic>.from(queryResult.first.fields);
    } else {
      return {}; // Return an empty map if no rows are found
    }
  } catch (e) {
    print('Error reading first row: $e');
    return {}; // Return an empty map if an error occurs
  }
}

Future<bool> saveData(MySqlConnection connection, String tableName,
    Map<String, dynamic> data) async {
  try {
    final columnsResult = await connection.query('SHOW COLUMNS FROM $tableName');
    final columns = columnsResult.map((row) => row['Field'] as String).toList();

    final List<String> filteredColumns = [];
    final List<dynamic> filteredValues = [];

    for (String column in columns) {
      if (data.containsKey(column)) {
        filteredColumns.add(column);
        filteredValues.add(data[column]);
      }
    }

    final String strColumns = filteredColumns.join(', ');
    final String placeholders = List.filled(filteredColumns.length, '?').join(', ');

    String sql;
    List<dynamic> params;
    if (data.containsKey('id')) {
      final id = data['id'];
      final List<String> updates = filteredColumns.map((column) => '$column = ?').toList();
      final String strUpdates = updates.join(', ');
      sql = 'UPDATE $tableName SET $strUpdates WHERE id = ?';
      params = [...filteredValues, id];
    } else {
      sql = 'INSERT INTO $tableName ($strColumns) VALUES ($placeholders)';
      params = filteredValues;
    }
    print(sql);
    final result = await connection.query(sql, params);
    return result.affectedRows == 1;
  } catch (e) {
    print('Error saving data: $e');
    return false;
  }
}

Future<bool> deleteData(
    MySqlConnection connection, String tableName, String condition) async {
  String sqlQuery = '';

  if (condition.isNotEmpty) {
    sqlQuery = ' WHERE $condition';
  }

  try {
    final result = await connection.query('DELETE FROM $tableName $sqlQuery');
    if (result.affectedRows != null && result.affectedRows! > 0) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    print('Error deleting data: $e');
    return false;
  }
}

Future<List<Map<String, dynamic>>> executeQuery(String query) async {
  MySqlConnection? conn;
  try {
    conn = await connectToDatabase();
    var results = await conn.query(query);
    return results.map((row) => row.fields).toList();
  } catch (e) {
    print('Error executing query: $e');
    rethrow;
  } finally {
    await conn?.close();
  }
}
