
import 'package:mysql1/mysql1.dart';

Future<MySqlConnection> connectToDatabase() async {
  final settings = ConnectionSettings(
    host: '10.0.2.2',
    port: 3306, // Default MySQL port
    user: 'root',
    password: '4611',
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

Future<List<Map<String, dynamic>>> executeQuery(String query) async {
  MySqlConnection? conn;
  try {
    conn = await connectToDatabase();
    var results = await conn.query(query);
    return results.map((row) => row.fields).toList();
  } catch (e) {
    print('Error executing query: $e');
    throw e;
  } finally {
    await conn?.close();
  }
}

