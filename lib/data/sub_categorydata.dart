import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/data/categorydata.dart';

class SubCategoryData {
  final int id;
  final int categoryId;
  final String subCategory;

  SubCategoryData(
      {required this.id, required this.categoryId, required this.subCategory});
}

Future<List<List<SubCategoryData>>> fetchSubCategories(
    MySqlConnection conn) async {
  final categories = await fetchCategories(conn);
  final subCategories = <List<SubCategoryData>>[];

  for (var category in categories) {
    final results = await conn
        .query('SELECT * FROM sub_category WHERE category = ?', [category.id]);
    final subCategoryList = results.map<SubCategoryData>((row) {
      return SubCategoryData(
        id: row['id'] as int,
        categoryId: row['category'] as int,
        subCategory: row['sub_category'] as String,
      );
    }).toList();
    subCategories.add(subCategoryList);
  }

  return subCategories;
}
