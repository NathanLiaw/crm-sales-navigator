import 'package:mysql1/mysql1.dart';

class BrandData {
  final int id;
  final String brand;
  final int position;
  final String status;

  BrandData({
    required this.id,
    required this.brand,
    required this.position,
    required this.status,
  });

  factory BrandData.fromRow(ResultRow row) {
    return BrandData(
      id: row['id'] as int,
      brand: row['brand'] as String,
      position: row['position'] as int,
      status: row['status'] as String,
    );
  }
}

Future<List<BrandData>> fetchBrands(MySqlConnection conn) async {
  final results = await conn.query('SELECT * FROM brand WHERE status = "1"');
  return results.map<BrandData>((row) => BrandData.fromRow(row)).toList();
}
