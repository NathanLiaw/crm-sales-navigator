import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BrandData {
  final int id;
  final String brand;

  BrandData({
    required this.id,
    required this.brand,
  });

  factory BrandData.fromJson(Map<String, dynamic> json) {
    return BrandData(
      id: json['id'] as int,
      brand: json['brand'] as String,
    );
  }
}

Future<List<BrandData>> fetchBrands() async {
  final response = await http.get(
    Uri.parse('${dotenv.env['API_URL']}/brand/get_brands.php'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      List<dynamic> brandList = data['data'];

      return brandList.map((json) => BrandData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load brands: ${data['message']}');
    }
  } else {
    throw Exception('Failed to load brands');
  }
}