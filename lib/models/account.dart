class AccountModel {
  final int? id;
  final String name;
  final String accountType; // 'cash', 'bank', 'credit_card', 'savings', 'investment'
  final double initialBalance;
  final double currentBalance;
  final String currency;
  final bool isActive;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountModel({
    this.id,
    required this.name,
    required this.accountType,
    this.initialBalance = 0,
    this.currentBalance = 0,
    this.currency = 'EUR',
    this.isActive = true,
    this.color,
    this.icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Icône par défaut selon le type
  String get defaultIcon {
    switch (accountType) {
      case 'cash':
        return '💵';
      case 'bank':
        return '🏦';
      case 'credit_card':
        return '💳';
      case 'savings':
        return '🏛️';
      case 'investment':
        return '📈';
      default:
        return '💰';
    }
  }

  // Couleur par défaut selon le type
  String get defaultColor {
    switch (accountType) {
      case 'cash':
        return '#2ECC71'; // Vert
      case 'bank':
        return '#3498DB'; // Bleu
      case 'credit_card':
        return '#E74C3C'; // Rouge
      case 'savings':
        return '#F39C12'; // Orange
      case 'investment':
        return '#9B59B6'; // Violet
      default:
        return '#95A5A6'; // Gris
    }
  }

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'account_type': accountType,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'currency': currency,
      'is_active': isActive ? 1 : 0,
      'color': color ?? defaultColor,
      'icon': icon ?? defaultIcon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Créer depuis Map SQLite
  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      accountType: map['account_type'] as String,
      initialBalance: (map['initial_balance'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      currency: map['currency'] as String,
      isActive: (map['is_active'] as int) == 1,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Copier avec modifications
  AccountModel copyWith({
    int? id,
    String? name,
    String? accountType,
    double? initialBalance,
    double? currentBalance,
    String? currency,
    bool? isActive,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Account{id: $id, name: $name, balance: $currentBalance $currency}';
  }
}
