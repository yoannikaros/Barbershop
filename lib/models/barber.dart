class Barber {
  final int? id;
  final String name;
  final String? photo;
  final String? bio;
  final int isActive;

  Barber({
    this.id,
    required this.name,
    this.photo,
    this.bio,
    this.isActive = 1,
  });

  factory Barber.fromMap(Map<String, dynamic> map) {
    return Barber(
      id: map['id'],
      name: map['name'],
      photo: map['photo'],
      bio: map['bio'],
      isActive: map['is_active'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photo': photo,
      'bio': bio,
      'is_active': isActive,
    };
  }

  Barber copyWith({
    int? id,
    String? name,
    String? photo,
    String? bio,
    int? isActive,
  }) {
    return Barber(
      id: id ?? this.id,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
    );
  }
}
