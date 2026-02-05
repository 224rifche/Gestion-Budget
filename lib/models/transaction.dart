class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final int categoryId;
  final String transactionType; // 'income' ou 'expense'
  final String? paymentMethod;
  final String? description;
  final String? location;
  final bool isRecurring;
  final String? recurringPattern;
  final DateTime? nextOccurrence;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.transactionType,
    this.paymentMethod,
    this.description,
    this.location,
    this.isRecurring = false,
    this.recurringPattern,
    this.nextOccurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'transaction_type': transactionType,
      'payment_method': paymentMethod,
      'description': description,
      'location': location,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_pattern': recurringPattern,
      'next_occurrence': nextOccurrence?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Créer depuis Map SQLite
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as int,
      transactionType: map['transaction_type'] as String,
      paymentMethod: map['payment_method'] as String?,
      description: map['description'] as String?,
      location: map['location'] as String?,
      isRecurring: (map['is_recurring'] as int) == 1,
      recurringPattern: map['recurring_pattern'] as String?,
      nextOccurrence: map['next_occurrence'] != null
          ? DateTime.parse(map['next_occurrence'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Copier avec modifications
  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    int? categoryId,
    String? transactionType,
    String? paymentMethod,
    String? description,
    String? location,
    bool? isRecurring,
    String? recurringPattern,
    DateTime? nextOccurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      transactionType: transactionType ?? this.transactionType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Transaction{id: $id, title: $title, amount: $amount, type: $transactionType}';
  }
}
