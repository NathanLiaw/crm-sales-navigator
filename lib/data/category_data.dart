import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CategoryData {
  final int id;
  final String category;
  bool isExpanded;

  CategoryData({
    required this.id,
    required this.category,
    this.isExpanded = false,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['id'] as int,
      category: json['category'] as String,
    );
  }
}

Future<List<CategoryData>> fetchCategories() async {
  final response = await http.get(
    Uri.parse('${dotenv.env['API_URL']}/category/get_categories.php'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      List<dynamic> categoryList = data['data'];
      return categoryList.map((json) => CategoryData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${data['message']}');
    }
  } else {
    throw Exception('Failed to load categories');
  }
}
