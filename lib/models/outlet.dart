class Outlet {
  final int? id;
  final String name;
  final String? address;
  final String? phone;

  Outlet({
    this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory Outlet.fromMap(Map<String, dynamic> map) {
    return Outlet(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
    };
  }

  Outlet copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
  }) {
    return Outlet(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }
}
