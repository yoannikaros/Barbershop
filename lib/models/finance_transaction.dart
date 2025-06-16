class FinanceTransaction {
  final int? id;
  final String date;
  final int categoryId;
  final int amount;
  final String? description;
  final String? paymentMethod;
  final String? referenceId;
  final int? userId;
  final int? outletId;

  // For UI display (not stored in database)
  final String? categoryName;
  final String? categoryType;
  final String? userName;
  final String? outletName;

  FinanceTransaction({
    this.id,
    required this.date,
    required this.categoryId,
    required this.amount,
    this.description,
    this.paymentMethod = 'cash',
    this.referenceId,
    this.userId,
    this.outletId,
    this.categoryName,
    this.categoryType,
    this.userName,
    this.outletName,
  });

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id'],
      date: map['date'],
      categoryId: map['category_id'],
      amount: map['amount'],
      description: map['description'],
      paymentMethod: map['payment_method'],
      referenceId: map['reference_id'],
      userId: map['user_id'],
      outletId: map['outlet_id'],
      categoryName: map['category_name'],
      categoryType: map['category_type'],
      userName: map['user_name'],
      outletName: map['outlet_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'payment_method': paymentMethod,
      'reference_id': referenceId,
      'user_id': userId,
      'outlet_id': outletId,
    };
  }

  FinanceTransaction copyWith({
    int? id,
    String? date,
    int? categoryId,
    int? amount,
    String? description,
    String? paymentMethod,
    String? referenceId,
    int? userId,
    int? outletId,
    String? categoryName,
    String? categoryType,
    String? userName,
    String? outletName,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceId: referenceId ?? this.referenceId,
      userId: userId ?? this.userId,
      outletId: outletId ?? this.outletId,
      categoryName: categoryName ?? this.categoryName,
      categoryType: categoryType ?? this.categoryType,
      userName: userName ?? this.userName,
      outletName: outletName ?? this.outletName,
    );
  }
}
