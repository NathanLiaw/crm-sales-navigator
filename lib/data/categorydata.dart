import 'package:mysql1/mysql1.dart';

class CategoryData {
  final int id;
  final String category;
  bool isExpanded;

  CategoryData(
      {required this.id, required this.category, this.isExpanded = false});
}

Future<List<CategoryData>> fetchCategories(MySqlConnection conn) async {
  final results =
      await conn.query('SELECT * FROM category WHERE id NOT IN(18)');
  return results.map<CategoryData>((row) {
    return CategoryData(
      id: row['id'] as int,
      category: row['category'] as String,
    );
  }).toList();
}
