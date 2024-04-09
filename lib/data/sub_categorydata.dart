import 'package:mysql1/mysql1.dart';

class SubCategoryData {
  final int id;
  final int categoryId;
  final String subCategory;

  SubCategoryData(
      {required this.id, required this.categoryId, required this.subCategory});
}

Future<List<List<SubCategoryData>>> fetchSubCategories(
    MySqlConnection conn) async {
  final results = await conn.query('SELECT * FROM sub_category');
  return results.map<List<SubCategoryData>>((row) {
    return [
      SubCategoryData(
        id: row['id'] as int,
        categoryId: row['category'] as int,
        subCategory: row['sub_category'] as String,
      ),
    ];
  }).toList();
}
