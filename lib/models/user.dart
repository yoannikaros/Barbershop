class User {
  final int? id;
  final String username;
  final String password;
  final String? fullName;
  final String? email;
  final String role;
  final int? outletId;
  final int isActive;
  final String? photo;

  User({
    this.id,
    required this.username,
    required this.password,
    this.fullName,
    this.email,
    required this.role,
    this.outletId,
    this.isActive = 1,
    this.photo,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      fullName: map['full_name'],
      email: map['email'],
      role: map['role'],
      outletId: map['outlet_id'],
      isActive: map['is_active'],
      photo: map['photo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'email': email,
      'role': role,
      'outlet_id': outletId,
      'is_active': isActive,
      'photo': photo,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? fullName,
    String? email,
    String? role,
    int? outletId,
    int? isActive,
    String? photo,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      outletId: outletId ?? this.outletId,
      isActive: isActive ?? this.isActive,
      photo: photo ?? this.photo,
    );
  }
}
