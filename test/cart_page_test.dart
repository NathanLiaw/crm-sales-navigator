import 'package:flutter_test/flutter_test.dart';
import 'package:sales_navigator/cart_item.dart';

void main() {
  group('CartPage', () {
    test(
        'calculateTotalAndSubTotal should calculate total and subtotal correctly',
        () {
      // Arrange
      List<CartItem> cartItems = [
        CartItem(
          id: 1,
          productName: 'Item 1',
          unitPrice: 10.0,
          quantity: 2,
          buyerId: 1,
          productId: 1,
          uom: 'pcs',
          total: 20.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
        CartItem(
          id: 2,
          productName: 'Item 2',
          unitPrice: 15.0,
          quantity: 1,
          buyerId: 1,
          productId: 2,
          uom: 'pcs',
          total: 15.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
        CartItem(
          id: 3,
          productName: 'Item 3',
          unitPrice: 20.0,
          quantity: 3,
          buyerId: 1,
          productId: 3,
          uom: 'pcs',
          total: 60.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
      ];
      double gst = 0.1;
      double sst = 0.05;

      // Act
      double subtotal = 0;
      double total = 0;

      void calculateTotalAndSubTotal() {
        double calculatedSubtotal = 0;

        for (CartItem item in cartItems) {
          calculatedSubtotal += item.unitPrice * item.quantity;
        }

        double finalTotal = calculatedSubtotal * (1 + gst + sst);

        subtotal = calculatedSubtotal;
        total = finalTotal;
      }

      calculateTotalAndSubTotal();

      // Assert
      expect(subtotal, 95.0);
      expect(
          total,
          closeTo(109.25,
              0.000000000001)); // Use closeTo matcher with a small tolerance
    });

    test('deleteSelectedCartItems should delete selected cart items', () {
      // Arrange
      List<CartItem> cartItems = [
        CartItem(
          id: 1,
          productName: 'Item 1',
          unitPrice: 10.0,
          quantity: 2,
          buyerId: 1,
          productId: 1,
          uom: 'pcs',
          total: 20.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
        CartItem(
          id: 2,
          productName: 'Item 2',
          unitPrice: 15.0,
          quantity: 1,
          buyerId: 1,
          productId: 2,
          uom: 'pcs',
          total: 15.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
        CartItem(
          id: 3,
          productName: 'Item 3',
          unitPrice: 20.0,
          quantity: 3,
          buyerId: 1,
          productId: 3,
          uom: 'pcs',
          total: 60.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
      ];
      List<CartItem> selectedCartItems = [
        CartItem(
          id: 1,
          productName: 'Item 1',
          unitPrice: 10.0,
          quantity: 2,
          buyerId: 1,
          productId: 1,
          uom: 'pcs',
          total: 20.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
        CartItem(
          id: 3,
          productName: 'Item 3',
          unitPrice: 20.0,
          quantity: 3,
          buyerId: 1,
          productId: 3,
          uom: 'pcs',
          total: 60.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
      ];

      // Act
      void deleteSelectedCartItems() {
        List<int?> cartItemIds =
            selectedCartItems.map((item) => item.id).toList();

        cartItems.removeWhere((item) => cartItemIds.contains(item.id));
        selectedCartItems.clear();
      }

      deleteSelectedCartItems();

      // Assert
      expect(cartItems.length, 1);
      expect(cartItems[0].id, 2);
      expect(selectedCartItems.length, 0);
    });

    test('updateItemQuantity should update item quantity', () {
      // Arrange
      List<CartItem> cartItems = [
        CartItem(
          id: 1,
          productName: 'Item 1',
          unitPrice: 10.0,
          quantity: 2,
          buyerId: 1,
          productId: 1,
          uom: 'pcs',
          total: 20.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
        CartItem(
          id: 2,
          productName: 'Item 2',
          unitPrice: 15.0,
          quantity: 1,
          buyerId: 1,
          productId: 2,
          uom: 'pcs',
          total: 15.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
        CartItem(
          id: 3,
          productName: 'Item 3',
          unitPrice: 20.0,
          quantity: 3,
          buyerId: 1,
          productId: 3,
          uom: 'pcs',
          total: 60.0,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
      ];

      // Act
      void updateItemQuantity(int? id, int quantity) {
        CartItem? item = cartItems.firstWhere((item) => item.id == id);
        if (item != null) {
          item.quantity = quantity;
        }
      }

      updateItemQuantity(2, 5);

      // Assert
      expect(cartItems[1].quantity, 5);
    });
  });
}
