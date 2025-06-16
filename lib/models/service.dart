class Service {
  final int? id;
  final String name;
  final String? description;
  final int price;
  final int durationMinutes;
  final int isActive;

  Service({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.durationMinutes = 30,
    this.isActive = 1,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      durationMinutes: map['duration_minutes'],
      isActive: map['is_active'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration_minutes': durationMinutes,
      'is_active': isActive,
    };
  }

  Service copyWith({
    int? id,
    String? name,
    String? description,
    int? price,
    int? durationMinutes,
    int? isActive,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
    );
  }
}
