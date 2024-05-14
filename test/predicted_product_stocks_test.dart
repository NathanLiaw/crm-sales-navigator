import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PredictedProductsTarget', () {
    test(
        'predictSalesAndStock should calculate predicted sales and stock correctly',
        () {
      // Arrange
      final products = [
        Product('Product 1', 100, 1000.0, 0, 0),
        Product('Product 2', 200, 2000.0, 0, 0),
        Product('Product 3', 150, 1500.0, 0, 0),
      ];

      final predictedProductsTarget = _PredictedProductsTargetState();
      predictedProductsTarget.products = products;

      // Act
      predictedProductsTarget.predictSalesAndStock();

      // Assert
      expect(predictedProductsTarget.products[0].predictedSales, 525);
      expect(predictedProductsTarget.products[0].predictedStock, 63);
      expect(predictedProductsTarget.products[1].predictedSales, 1050);
      expect(predictedProductsTarget.products[1].predictedStock, 126);
      expect(predictedProductsTarget.products[2].predictedSales, 788);
      expect(predictedProductsTarget.products[2].predictedStock, 95);
    });
  });
}

class _PredictedProductsTargetState {
  List<Product> products = [];
  String loggedInUsername = '';

  void predictSalesAndStock() {
    int period = 2; // We have 2 months of historical data

    for (var product in products) {
      // Calculate average monthly sales and quantity
      double avgMonthlySales = product.salesOrder / period;
      double avgMonthlyQuantity = product.quantity / period;

      // Assuming a growth rate based on some business logic or previous trend analysis; here a placeholder of 5% growth
      double growthRate = 1.05; // 5% growth

      // Project next month's sales and quantity based on the average and assumed growth
      product.predictedSales = (avgMonthlySales * growthRate).round();
      product.predictedStock = (avgMonthlyQuantity * growthRate * 1.2)
          .round(); // 20% buffer on top of the predicted sales
    }
  }
}

class PredictedProductsTarget {
  // Empty class definition
}

class Product {
  String name;
  int quantity;
  double salesOrder;
  int predictedSales;
  int predictedStock;

  Product(this.name, this.quantity, this.salesOrder, this.predictedSales,
      this.predictedStock);
}
