import 'package:flutter_test/flutter_test.dart';
import 'package:sales_navigator/data/brand_data.dart';
import 'package:sales_navigator/data/sub_category_data.dart';
import 'package:sales_navigator/model/items_widget.dart';

void main() {
  group('ProductScreen tests', () {
    test('ItemsWidget should have correct subCategoryIds', () {
      // Test Data (act as DATABASE)
      List<SubCategoryData> subcategoryData = [
        SubCategoryData(id: 27, categoryId: 47, subCategory: "Sprayer"),
        SubCategoryData(id: 47, categoryId: 10, subCategory: "Painter"),
        SubCategoryData(id: 89, categoryId: 15, subCategory: "Lock"),
      ];

      List<int> subcategoryIds =
          subcategoryData.map((data) => data.id).toList();

      // Create an instance of ItemsWidget
      final itemsWidget = ItemsWidget(
        subCategoryIds: subcategoryIds,
        isFeatured: false,
        sortOrder: 'By Name (A to Z)',
      );

      // Assert that the subCategoryIds in ItemsWidget match the expected values
      expect(itemsWidget.subCategoryIds, equals([27, 47, 89]));
    });

    test('ItemsWidget should have correct brandIds', () {
      // Test Data
      List<BrandData> brandData = [
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

      List<int> brandIds = brandData.map((data) => data.id).toList();

      // Create an instance of ItemsWidget
      final itemsWidget = ItemsWidget(
        brandIds: brandIds,
        isFeatured: false,
        sortOrder: 'By Name (A to Z)',
      );

      // Assert that the brandIds in ItemsWidget match the expected values
      expect(itemsWidget.brandIds, equals([27, 28, 29]));
    });

    test('ItemsWidget should have correct sortOrder', () {
      // Test Data
      String expectedSortOrder = 'By Price (Low to High)';

      // Create an instance of ItemsWidget
      final itemsWidget = ItemsWidget(
        subCategoryIds: [],
        brandIds: [],
        isFeatured: false,
        sortOrder: expectedSortOrder,
      );

      // Assert that the sortOrder in ItemsWidget matches the expected value
      expect(itemsWidget.sortOrder, equals(expectedSortOrder));
    });

    test('ItemsWidget should have correct isFeatured value', () {
      // Test Data
      bool expectedIsFeatured = true;

      // Create an instance of ItemsWidget
      final itemsWidget = ItemsWidget(
        subCategoryIds: [],
        brandIds: [],
        isFeatured: expectedIsFeatured,
        sortOrder: 'By Name (A to Z)',
      );

      // Assert that the isFeatured value in ItemsWidget matches the expected value
      expect(itemsWidget.isFeatured, equals(expectedIsFeatured));
    });
  });
}
