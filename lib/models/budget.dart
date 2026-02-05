class BudgetModel {
  final int? id;
  final int categoryId;
  final double amountLimit;
  final String periodType; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final double currentSpent;
  final bool isActive;
  final bool notificationsEnabled;
  final double notificationThreshold; // Pourcentage
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    this.id,
    required this.categoryId,
    required this.amountLimit,
    required this.periodType,
    required this.startDate,
    this.endDate,
    this.currentSpent = 0,
    this.isActive = true,
    this.notificationsEnabled = true,
    this.notificationThreshold = 80,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Calcul du pourcentage utilisé
  double get percentageUsed {
    if (amountLimit == 0) return 0;
    return (currentSpent / amountLimit * 100).clamp(0, 100);
  }

  // Montant restant
  double get remainingAmount {
    return (amountLimit - currentSpent).clamp(0, double.infinity);
  }

  // Est-ce que le budget est dépassé ?
  bool get isExceeded => currentSpent > amountLimit;

  // Est-ce qu'on approche du seuil d'alerte ?
  bool get isNearThreshold => percentageUsed >= notificationThreshold;

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount_limit': amountLimit,
      'period_type': periodType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'current_spent': currentSpent,
      'is_active': isActive ? 1 : 0,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'notification_threshold': notificationThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Créer depuis Map SQLite
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      amountLimit: (map['amount_limit'] as num).toDouble(),
      periodType: map['period_type'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      currentSpent: (map['current_spent'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
      notificationsEnabled: (map['notifications_enabled'] as int) == 1,
      notificationThreshold:
          (map['notification_threshold'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Copier avec modifications
  BudgetModel copyWith({
    int? id,
    int? categoryId,
    double? amountLimit,
    String? periodType,
    DateTime? startDate,
    DateTime? endDate,
    double? currentSpent,
    bool? isActive,
    bool? notificationsEnabled,
    double? notificationThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amountLimit: amountLimit ?? this.amountLimit,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentSpent: currentSpent ?? this.currentSpent,
      isActive: isActive ?? this.isActive,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationThreshold:
          notificationThreshold ?? this.notificationThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Budget{id: $id, limit: $amountLimit, spent: $currentSpent, percentage: ${percentageUsed.toStringAsFixed(1)}%}';
  }
}
