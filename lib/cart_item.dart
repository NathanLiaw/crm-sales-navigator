class CartItem {
  int? id; // Database-assigned ID
  int? cartId; // ID of the cart to which this item belongs
  final int? buyerId; // ID of the buyer (required)
  final int? customerId; // ID of the customer (required)
  final int productId; // ID of the product (required)
  final String productName;
  final String uom; // Unit of measurement
  int quantity;
  final int discount;
  final double originalUnitPrice;
  final double unitPrice;
  final double total;
  final String cancel;
  final String remark;
  final String status;
  final DateTime created;
  final DateTime modified;

  CartItem({
    this.id,
    this.cartId,
    required this.buyerId,
    this.customerId,
    required this.productId,
    required this.productName,
    required this.uom,
    this.quantity = 0,
    this.discount = 0,
    this.originalUnitPrice = 0.0,
    required this.unitPrice,
    required this.total,
    this.cancel = '',
    this.remark = '',
    this.status = '',
    required this.created,
    required this.modified,
  });

  // Factory constructor to create CartItem from map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      cartId: map['cart_id'],
      buyerId: map['buyer_id'] ?? 0,
      customerId: map['customer_id'] ?? 0,
      productId: map['product_id'] ?? 0,
      productName: map['product_name'] ?? '',
      uom: map['uom'] ?? '',
      quantity: map['qty'] ?? 0,
      discount: map['discount'] ?? 0,
      originalUnitPrice: map['ori_unit_price'] ?? 0.0,
      unitPrice: map['unit_price'] ?? 0.0,
      total: map['total'] ?? 0.0,
      cancel: map['cancel'] ?? '',
      remark: map['remark'] ?? '',
      status: map['status'] ?? '',
      created: DateTime.parse(map['created'] ?? ''),
      modified: DateTime.parse(map['modified'] ?? ''),
    );
  }

  // Convert CartItem instance to a map
  Map<String, dynamic> toMap({bool excludeId = false}) {
    Map<String, dynamic> map = {
      'buyer_id': buyerId,
      'customer_id': customerId,
      'product_id': productId,
      'product_name': productName,
      'uom': uom,
      'qty': quantity,
      'discount': discount,
      'ori_unit_price': originalUnitPrice,
      'unit_price': unitPrice,
      'total': total,
      'cancel': cancel,
      'remark': remark,
      'status': status,
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
    };

    if (!excludeId) {
      map['id'] = id;
    }

    return map;
  }
}
