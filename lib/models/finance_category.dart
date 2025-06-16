class FinanceCategory {
  final int? id;
  final String name;
  final String type; // 'income' atau 'expense'
  final String? description;
  final int isActive;

  FinanceCategory({
    this.id,
    required this.name,
    required this.type,
    this.description,
    this.isActive = 1,
  });

  factory FinanceCategory.fromMap(Map<String, dynamic> map) {
    return FinanceCategory(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      description: map['description'],
      isActive: map['is_active'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'is_active': isActive,
    };
  }

  FinanceCategory copyWith({
    int? id,
    String? name,
    String? type,
    String? description,
    int? isActive,
  }) {
    return FinanceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
