import 'package:flutter_test/flutter_test.dart';
import 'package:sales_navigator/cart_item.dart';
import 'package:intl/intl.dart';

void main() {
  group('ItemVariationsScreen', () {
    test('insertItemIntoCart should insert or update cart item correctly',
        () async {
      // Arrange
      final List<Map<String, dynamic>> cartItems = [];

      Future<void> insertItemIntoCart(CartItem cartItem) async {
        int itemId = cartItem.productId;
        String uom = cartItem.uom;

        final condition =
            "product_id = $itemId AND uom = '$uom' AND status = 'in progress'";

        // Read data from the cartItems list based on the provided condition
        final result = cartItems
            .where((item) => condition.contains(item['product_id'].toString()))
            .toList();

        // Check if the result contains any existing items
        if (result.isNotEmpty) {
          // Item already exists, update the quantity
          final existingItem = result.first;
          final updatedQuantity = existingItem['qty'] + cartItem.quantity;

          // Update the quantity in the cartItems list
          final itemIndex = cartItems.indexWhere(
              (item) => item['product_id'] == itemId && item['uom'] == uom);
          if (itemIndex != -1) {
            cartItems[itemIndex]['qty'] = updatedQuantity;
            cartItems[itemIndex]['modified'] = DateTime.now();
          }
        } else {
          // Item does not exist, insert it as a new item
          final cartItemMap = cartItem.toMap(excludeId: true);
          cartItems.add(cartItemMap);
        }
      }

      // Create mock functions and variables
      int getUserId() => 1;
      String getCurrentDateTime() =>
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Create a CartItem
      final cartItem = CartItem(
        buyerId: getUserId(),
        productId: 1,
        productName: 'Product 1',
        uom: 'pcs',
        quantity: 2,
        discount: 0,
        originalUnitPrice: 10.0,
        unitPrice: 10.0,
        total: 20.0,
        cancel: null,
        remark: null,
        status: 'in progress',
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      // Act
      await insertItemIntoCart(cartItem);

      // Assert
      expect(cartItems.length, 1);
      expect(cartItems[0]['product_id'], 1);
      expect(cartItems[0]['qty'], 2);

      // Act (update existing item)
      final updatedCartItem = CartItem(
        buyerId: getUserId(),
        productId: 1,
        productName: 'Product 1',
        uom: 'pcs',
        quantity: 3,
        discount: 0,
        originalUnitPrice: 10.0,
        unitPrice: 10.0,
        total: 30.0,
        cancel: null,
        remark: null,
        status: 'in progress',
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      await insertItemIntoCart(updatedCartItem);

      // Assert
      expect(cartItems.length, 1);
      expect(cartItems[0]['product_id'], 1);
      expect(cartItems[0]['qty'], 5);
    });

    test('quantity updates should reflect in the cart', () {
      // Arrange
      final Map<String, int> quantityMap = {'pcs': 1, 'box': 2};

      // Act
      quantityMap['pcs'] = 3;

      // Assert
      expect(quantityMap['pcs'], 3);

      // Act
      quantityMap['box'] = 5;

      // Assert
      expect(quantityMap['box'], 5);
    });
  });
}
