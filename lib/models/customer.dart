class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? birthDate;
  final String? notes;
  final int points;
  final String? referralCode;
  final String? referredBy;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.birthDate,
    this.notes,
    this.points = 0,
    this.referralCode,
    this.referredBy,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      birthDate: map['birth_date'],
      notes: map['notes'],
      points: map['points'],
      referralCode: map['referral_code'],
      referredBy: map['referred_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'birth_date': birthDate,
      'notes': notes,
      'points': points,
      'referral_code': referralCode,
      'referred_by': referredBy,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? birthDate,
    String? notes,
    int? points,
    String? referralCode,
    String? referredBy,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      notes: notes ?? this.notes,
      points: points ?? this.points,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
    );
  }
}
