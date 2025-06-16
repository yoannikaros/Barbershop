class Transaction {
  final int? id;
  final String date;
  final int? customerId;
  final int? userId;
  final int? outletId;
  final int total;
  final String? paymentMethod;
  final int? promoId;
  final String? notes;

  // For UI display (not stored in database)
  final String? customerName;
  final String? userName;
  final String? outletName;
  final String? promoName;

  Transaction({
    this.id,
    required this.date,
    this.customerId,
    this.userId,
    this.outletId,
    required this.total,
    this.paymentMethod = 'cash',
    this.promoId,
    this.notes,
    this.customerName,
    this.userName,
    this.outletName,
    this.promoName,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: map['date'],
      customerId: map['customer_id'],
      userId: map['user_id'],
      outletId: map['outlet_id'],
      total: map['total'],
      paymentMethod: map['payment_method'],
      promoId: map['promo_id'],
      notes: map['notes'],
      customerName: map['customer_name'],
      userName: map['user_name'],
      outletName: map['outlet_name'],
      promoName: map['promo_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'customer_id': customerId,
      'user_id': userId,
      'outlet_id': outletId,
      'total': total,
      'payment_method': paymentMethod,
      'promo_id': promoId,
      'notes': notes,
    };
  }

  Transaction copyWith({
    int? id,
    String? date,
    int? customerId,
    int? userId,
    int? outletId,
    int? total,
    String? paymentMethod,
    int? promoId,
    String? notes,
    String? customerName,
    String? userName,
    String? outletName,
    String? promoName,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      outletId: outletId ?? this.outletId,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      promoId: promoId ?? this.promoId,
      notes: notes ?? this.notes,
      customerName: customerName ?? this.customerName,
      userName: userName ?? this.userName,
      outletName: outletName ?? this.outletName,
      promoName: promoName ?? this.promoName,
    );
  }
}
