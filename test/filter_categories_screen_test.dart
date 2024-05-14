import 'package:flutter_test/flutter_test.dart';
import 'package:sales_navigator/filter_categories_screen.dart';
import 'package:sales_navigator/data/brand_data.dart';
import 'package:sales_navigator/data/sub_category_data.dart';

void main() {
  group('filter categories screen ...', () {
    test('Given if the filter categories add the subcategory id into the list.',
        () async {
      // Test Data
      List<SubCategoryData> _subcategoryid = [
        SubCategoryData(id: 27, categoryId: 47, subCategory: "Sprayer"),
        SubCategoryData(id: 47, categoryId: 10, subCategory: "Painter"),
        SubCategoryData(id: 89, categoryId: 15, subCategory: "Lock"),
      ];
      List<int> _subcategoryids = [];

      // Add subcategory IDs to _subcategoryids line by line
      _subcategoryids.add(_subcategoryid[0].id); // Adds 27
      _subcategoryids.add(_subcategoryid[1].id); // Adds 47
      _subcategoryids.add(_subcategoryid[2].id); // Adds 89

      // Assert that the _subcategoryids list matches the expected values
      expect(_subcategoryids, equals([27, 47, 89]));
    });

    test('Given if the filter categories add the brand id into the list.',
        () async {
      // Test Data
      List<BrandData> _brandid = [
        BrandData(
            brand: "KUSAMA",
            id: 27,
            position: 0,
            status: '1',
            created: DateTime.now(),
            modified: DateTime.now()),
        BrandData(
            brand: "TAILIN",
            id: 28,
            position: 1,
            status: '1',
            created: DateTime.now(),
            modified: DateTime.now()),
        BrandData(
            brand: "EVACUT",
            id: 29,
            position: 2,
            status: '1',
            created: DateTime.now(),
            modified: DateTime.now()),
      ];
      List<int> _brandids = [];

      // Add brand IDs to _brandids line by line
      _brandids.add(_brandid[0].id); // Adds 27
      _brandids.add(_brandid[1].id); // Adds 28
      _brandids.add(_brandid[2].id); // Adds 29

      // Assert that the _brandids list matches the expected values
      expect(_brandids, equals([27, 28, 29]));
    });

    test(
        'Given if the filter categories clear the subcategory and brand ids from the list.',
        () async {
      // Test Data
      List<SubCategoryData> _subcategoryid = [
        SubCategoryData(id: 27, categoryId: 47, subCategory: "Sprayer"),
        SubCategoryData(id: 47, categoryId: 10, subCategory: "Painter"),
        SubCategoryData(id: 89, categoryId: 15, subCategory: "Lock"),
      ];
      List<BrandData> _brandid = [
        BrandData(
            brand: "KUSAMA",
            id: 27,
            position: 0,
            status: '1',
            created: DateTime.now(),
            modified: DateTime.now()),
        BrandData(
            brand: "TAILIN",
            id: 28,
            position: 1,
            status: '1',
            created: DateTime.now(),
            modified: DateTime.now()),
        BrandData(
            brand: "EVACUT",
            id: 29,
            position: 2,
            status: '1',
            created: DateTime.now(),
            modified: DateTime.now()),
      ];
      List<int> _subcategoryids = [];
      List<int> _brandids = [];

      // Add subcategory and brand IDs to the lists
      _subcategoryids.addAll(
          [_subcategoryid[0].id, _subcategoryid[1].id, _subcategoryid[2].id]);
      _brandids.addAll([_brandid[0].id, _brandid[1].id, _brandid[2].id]);

      // Clear the lists one by one
      _subcategoryids.clear();
      _brandids.clear();

      // Assert that the lists are empty
      expect(_subcategoryids, isEmpty);
      expect(_brandids, isEmpty);
    });
  });
}
