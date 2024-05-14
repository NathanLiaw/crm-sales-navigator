import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('ProductReport', () {
    late _ProductReportState state;

    setUp(() {
      state = _ProductReportState();
      state.loggedInUsername = 'testuser';
    });

    test('fetchProducts should return products based on date range', () async {
      // Arrange
      final products = [
        Product(
          id: 1,
          brandId: 1,
          productName: 'Product 1',
          brandName: 'Brand 1',
          totalSales: 1000.0,
          totalQuantitySold: 10,
          lastSold: DateTime(2023, 6, 1),
        ),
        Product(
          id: 2,
          brandId: 1,
          productName: 'Product 2',
          brandName: 'Brand 1',
          totalSales: 2000.0,
          totalQuantitySold: 20,
          lastSold: DateTime(2023, 6, 5),
        ),
        Product(
          id: 3,
          brandId: 2,
          productName: 'Product 3',
          brandName: 'Brand 2',
          totalSales: 1500.0,
          totalQuantitySold: 15,
          lastSold: DateTime(2023, 6, 10),
        ),
      ];

      // Act
      state.products = Future.value(products);
      List<Product> allProducts = await state.fetchProducts(null);
      List<Product> filteredProducts = await state.fetchProducts(
        DateTimeRange(
          start: DateTime(2023, 6, 1),
          end: DateTime(2023, 6, 7),
        ),
      );

      // Assert
      expect(allProducts.length, 3);
      expect(filteredProducts.length, 2);
    });

    test('toggleSortOrder should update the sort order', () {
      // Arrange
      state.isSortedAscending = false;

      // Act
      state.toggleSortOrder();

      // Assert
      expect(state.isSortedAscending, true);
    });

    test('setDateRange should update the selected date range', () {
      // Arrange
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();

      // Act
      state.setDateRange(30, 1);

      // Assert
      expect(state.selectedButtonIndex, 1);
      expect(state._selectedDateRange!.start.difference(startDate).inDays, 0);
      expect(state._selectedDateRange!.end.difference(endDate).inDays, 0);
    });
  });
}

class _ProductReportState extends State<ProductReport> {
  Future<List<Product>> products = Future.value([]);
  DateTimeRange? _selectedDateRange;
  int selectedButtonIndex = -1;
  bool isSortedAscending = false;
  String loggedInUsername = '';

  Future<List<Product>> fetchProducts(DateTimeRange? dateRange) async {
    // Simulated product data
    final products = [
      Product(
        id: 1,
        brandId: 1,
        productName: 'Product 1',
        brandName: 'Brand 1',
        totalSales: 1000.0,
        totalQuantitySold: 10,
        lastSold: DateTime(2023, 6, 1),
      ),
      Product(
        id: 2,
        brandId: 1,
        productName: 'Product 2',
        brandName: 'Brand 1',
        totalSales: 2000.0,
        totalQuantitySold: 20,
        lastSold: DateTime(2023, 6, 5),
      ),
      Product(
        id: 3,
        brandId: 2,
        productName: 'Product 3',
        brandName: 'Brand 2',
        totalSales: 1500.0,
        totalQuantitySold: 15,
        lastSold: DateTime(2023, 6, 10),
      ),
    ];

    // Filter products based on date range
    if (dateRange != null) {
      products.retainWhere((product) =>
          !product.lastSold.isBefore(dateRange.start) &&
          !product.lastSold.isAfter(dateRange.end));
    }

    // Sort products based on the sort order
    if (isSortedAscending) {
      products
          .sort((a, b) => a.totalQuantitySold.compareTo(b.totalQuantitySold));
    } else {
      products
          .sort((a, b) => b.totalQuantitySold.compareTo(a.totalQuantitySold));
    }

    return products;
  }

  void toggleSortOrder() {
    isSortedAscending = !isSortedAscending;
    products = fetchProducts(_selectedDateRange);
  }

  void setDateRange(int days, int selectedIndex) {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(days: days));
    _selectedDateRange = DateTimeRange(start: start, end: now);
    isSortedAscending = false;
    products = fetchProducts(_selectedDateRange);
    selectedButtonIndex = selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Placeholder build method
    return Container();
  }
}

class ProductReport extends StatefulWidget {
  const ProductReport({super.key});

  @override
  State<ProductReport> createState() => _ProductReportState();
}

class Product {
  final int id;
  final int brandId;
  final String productName;
  final String brandName;
  final double totalSales;
  final int totalQuantitySold;
  final DateTime lastSold;

  Product({
    required this.id,
    required this.brandId,
    required this.productName,
    required this.brandName,
    required this.totalSales,
    required this.totalQuantitySold,
    required this.lastSold,
  });
}
