import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('SalesOrderPage', () {
    test('load sales orders and filter by customer', () {
      // Create a list of customers
      List<Customer> customers = [
        Customer(id: 1, companyName: 'ABC Company'),
        Customer(id: 2, companyName: 'XYZ Corporation'),
        Customer(id: 3, companyName: '123 Industries'),
      ];

      // Create sales orders for each customer
      List<SalesOrder> salesOrders = [
        SalesOrder(
            id: 1,
            customerId: 1,
            total: 100.0,
            createdDate: DateTime(2023, 1, 1),
            status: 'Confirm'),
        SalesOrder(
            id: 2,
            customerId: 1,
            total: 200.0,
            createdDate: DateTime(2023, 2, 1),
            status: 'Pending'),
        SalesOrder(
            id: 3,
            customerId: 2,
            total: 150.0,
            createdDate: DateTime(2023, 3, 1),
            status: 'Void'),
        SalesOrder(
            id: 4,
            customerId: 2,
            total: 300.0,
            createdDate: DateTime(2023, 4, 1),
            status: 'Confirm'),
        SalesOrder(
            id: 5,
            customerId: 3,
            total: 250.0,
            createdDate: DateTime(2023, 5, 1),
            status: 'Pending'),
      ];

      // Create an instance of _SalesOrderPageState
      _SalesOrderPageState state = _SalesOrderPageState();

      // Set the initial state
      state.orders = salesOrders;
      state.isLoading = false;

      // Verify the initial state
      expect(state.orders.length, 5);
      expect(state.isLoading, false);

      // Load customer details
      state.selectedCustomer = customers[0];
      state._loadSalesOrders();

      // Verify the loaded sales orders for the selected customer
      expect(state.orders.length, 2);

      // Select a different customer
      state._updateSelectedCustomer(customers[1]);

      // Verify the loaded sales orders for the newly selected customer
      expect(state.orders.length, 2);
      expect(state.orders[0].customerId, 2);
      expect(state.orders[1].customerId, 2);

      // Filter sales orders by date range
      state._selectDateRange(
        DateTimeRange(start: DateTime(2023, 3, 1), end: DateTime(2023, 5, 31)),
      );

      // Verify the filtered sales orders
      expect(state.orders.length, 2);
      expect(state.orders[0].id, 3);
      expect(state.orders[1].id, 4);
    });
  });
}

class Customer {
  final int id;
  final String companyName;

  Customer({required this.id, required this.companyName});
}

class SalesOrder {
  final int id;
  final int customerId;
  final double total;
  final DateTime createdDate;
  final String status;

  SalesOrder({
    required this.id,
    required this.customerId,
    required this.total,
    required this.createdDate,
    required this.status,
  });
}

class _SalesOrderPageState {
  List<SalesOrder> orders = [];
  bool isLoading = true;
  Customer? selectedCustomer;

  void _loadSalesOrders() {
    List<SalesOrder> filteredOrders = orders;
    if (selectedCustomer != null) {
      filteredOrders = orders
          .where((order) => order.customerId == selectedCustomer!.id)
          .toList();
    }
    orders = filteredOrders;
  }

  void _updateSelectedCustomer(Customer customer) {
    selectedCustomer = customer;
    _loadSalesOrders();
  }

  void _selectDateRange(DateTimeRange dateRange) {
    orders = orders.where((order) {
      return order.createdDate
              .isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
          order.createdDate
              .isBefore(dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }
}
