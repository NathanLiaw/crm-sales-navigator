import 'dart:convert';
import 'package:http/http.dart' as http;
import 'category_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SubCategoryData {
  final int id;
  final int categoryId;
  final String subCategory;

  SubCategoryData({
    required this.id,
    required this.categoryId,
    required this.subCategory,
  });

  factory SubCategoryData.fromJson(Map<String, dynamic> json) {
    return SubCategoryData(
      id: json['id'],
      categoryId: json['category_id'],
      subCategory: json['sub_category'],
    );
  }
}

// Fetch subcategories for multiple categories in parallel
Future<List<List<SubCategoryData>>> fetchAllSubCategories() async {
  final categories = await fetchCategories();

  // Create a list of Futures for fetching each category's subcategories
  final subCategoryFutures = categories.map((category) {
    final url = '${dotenv.env['API_URL']}/sub_category/get_sub_categories.php?category_id=${category.id}';
    return http.get(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((json) => SubCategoryData.fromJson(json))
              .toList();
        } else {
          throw Exception('Failed to load sub-categories: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load sub-categories');
      }
    });
  }).toList();

  // Wait for all requests to complete
  return Future.wait(subCategoryFutures);
}
