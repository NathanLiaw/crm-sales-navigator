import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:convert';

class DatabaseHelper {
  static Database? _database;
  static const String productTableName = 'product';
  static const String cartTableName = 'cart';
  static const String cartItemTableName = 'cart_item';
  static const String cartActiveTableName = 'cart_active';

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    // If the database is null, initialize it
    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'salesNavigator.db');

    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        // Create the products table
        // await db.execute(
        //   '''CREATE TABLE $productTableName(
        //     id INTEGER PRIMARY KEY,
        //     sub_category INTEGER,
        //     brand INTEGER,
        //     product_name TEXT,
        //     product_code TEXT,
        //     price_guide TEXT,
        //     photo1 TEXT,
        //     photo2 TEXT,
        //     photo3 TEXT,
        //     photo4 TEXT,
        //     featured TEXT,
        //     stock TEXT,
        //     status TEXT,
        //     description BLOB,
        //     uom TEXT,
        //     price_by_uom BLOB,
        //     stock_by_uom BLOB,
        //     discount BLOB
        //   )''',
        // );

        // Create the cart table
        await db.execute(
          '''CREATE TABLE $cartTableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_type TEXT,
            expiration_date TEXT,
            gst REAL,
            sst REAL,
            final_total REAL,
            total REAL,
            remark TEXT,
            order_option TEXT,
            buyer_user_group TEXT,
            buyer_area_id INTEGER,
            buyer_area_name TEXT,
            buyer_id INTEGER,
            buyer_name TEXT,
            customer_id INTEGER,
            customer_company_name TEXT,
            customer_discount TEXT,
            admin_id INTEGER,
            admin_datetime TEXT,
            status TEXT,
            created TEXT,
            modified TEXT
          )''',
        );

        // Create the cart_items table
        await db.execute(
          '''CREATE TABLE $cartItemTableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cart_id INTEGER,
            buyer_id INTEGER,
            customer_id INTEGER,
            product_id INTEGER,
            product_name TEXT,
            uom TEXT,
            qty INTEGER,
            discount INTEGER,
            ori_unit_price REAL,
            unit_price REAL,
            total REAL,
            cancel TEXT,
            remark TEXT,
            status TEXT,
            created TEXT,
            modified TEXT
          )''',
        );

        // Create the cart_active table
        // await db.execute(
        //   '''CREATE TABLE $cartActiveTableName(
        //     id INTEGER PRIMARY KEY AUTOINCREMENT,
        //     cart_id INTEGER,
        //   )''',
        // );
      },
    );
  }

  static Future<int> insertData(Map<String, dynamic> data, String tableName) async {
    final db = await database;

    // Check if the data already exists in the database
    final List<Map<String, dynamic>> existingData = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [data['id']],
    );

    // If the data already exists, skip insertion
    if (existingData.isNotEmpty) {
      return 0; // Return 0 to indicate no new rows were inserted
    }

    // Flatten nested maps into JSON strings
    Map<String, dynamic> flattenedData = flattenNestedMaps(data);

    // Insert flattened data into the database
    return await db.insert(tableName, flattenedData);
  }

  // Function to flatten nested maps into JSON strings
  static Map<String, dynamic> flattenNestedMaps(Map<String, dynamic> data) {
    Map<String, dynamic> flattenedData = {};
    data.forEach((key, value) {
      if (value is Map) {
        // Convert nested map to JSON string
        flattenedData[key] = json.encode(value);
      } else {
        flattenedData[key] = value;
      }
    });
    return flattenedData;
  }


  Future<List<Map<String, dynamic>>> readData(
      Database database,
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

    // Construct the SQL query
    String sql = 'SELECT $field FROM $tableName $sqlQuery $sqlOrder';

    // Execute the query
    List<Map<String, dynamic>> queryResult = await database.rawQuery(sql);

    // Process the query result
    List<Map<String, dynamic>> results = [];
    for (var row in queryResult) {
      // Convert Blob to string if necessary
      row.forEach((key, value) {
        if (value is Blob) {
          final blob = value as Blob;
          // Convert Blob data to List<int>
          final bytes = blob.toString().codeUnits;
          // Decode bytes to String
          final stringValue = utf8.decode(bytes);
          row[key] = stringValue;
        }
      });
      results.add(row);
    }

    return results;
  }


  // Get all data from a specific table
  static Future<List<Map<String, dynamic>>> getAllData(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  // Update data in a specific table
  static Future<int> updateData(Map<String, dynamic> data, String tableName) async {
    final db = await database;
    final id = data['id'];
    return await db.update(tableName, data, where: 'id = ?', whereArgs: [id]);
  }

  // Delete data from a specific table
  static Future<int> deleteData(int id, String tableName) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
