class CartItem {
  int? id;
  int? cartId;
  final int? buyerId;
  final int? customerId;
  final int productId;
  final String productName;
  final String uom;
  final int? quantity;
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
    this.buyerId = 0,
    this.customerId = 0,
    this.productId = 0,
    required this.productName,
    required this.uom,
    this.quantity = 0,
    this.discount = 0,
    this.originalUnitPrice = 0.0,
    this.unitPrice = 0.0,
    this.total = 0.0,
    this.cancel = '',
    this.remark = '',
    this.status = '',
    required this.created,
    required this.modified,
  });

  // Factory constructor to create CartItem from map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
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
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cart_id': cartId,
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
  }
}
