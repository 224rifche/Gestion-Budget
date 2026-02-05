class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final String categoryType; // 'income' ou 'expense'
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.categoryType,
    this.isDefault = true,
    this.isActive = true,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'category_type': categoryType,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer depuis Map SQLite
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      categoryType: map['category_type'] as String,
      isDefault: (map['is_default'] as int) == 1,
      isActive: (map['is_active'] as int) == 1,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Copier avec modifications
  CategoryModel copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    String? categoryType,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      categoryType: categoryType ?? this.categoryType,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, type: $categoryType}';
  }
}
