class Product {
  final int? id;
  final String name;
  final String? description;
  final int price;
  final int stock;
  final String unit;
  final int isActive;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.stock = 0,
    this.unit = 'pcs',
    this.isActive = 1,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      stock: map['stock'],
      unit: map['unit'],
      isActive: map['is_active'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'unit': unit,
      'is_active': isActive,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    int? price,
    int? stock,
    String? unit,
    int? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
    );
  }
}
