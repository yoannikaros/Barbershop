class TransactionDetail {
  final int? id;
  final int transactionId;
  final String itemType;
  final int itemId;
  final int quantity;
  final int price;
  final int subtotal;

  // For UI display (not stored in database)
  final String? itemName;

  TransactionDetail({
    this.id,
    required this.transactionId,
    required this.itemType,
    required this.itemId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.itemName,
  });

  factory TransactionDetail.fromMap(Map<String, dynamic> map) {
    return TransactionDetail(
      id: map['id'],
      transactionId: map['transaction_id'],
      itemType: map['item_type'],
      itemId: map['item_id'],
      quantity: map['quantity'],
      price: map['price'],
      subtotal: map['subtotal'],
      itemName: map['item_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'item_type': itemType,
      'item_id': itemId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  TransactionDetail copyWith({
    int? id,
    int? transactionId,
    String? itemType,
    int? itemId,
    int? quantity,
    int? price,
    int? subtotal,
    String? itemName,
  }) {
    return TransactionDetail(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      itemName: itemName ?? this.itemName,
    );
  }
}
