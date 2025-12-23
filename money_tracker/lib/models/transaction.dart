import 'package:uuid/uuid.dart';

/// Transaction type enum
enum TransactionType {
  income,
  expense;
  
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }


  
  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        return TransactionType.expense;
    }
  }
}

/// Transaction model
class Transaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime createdAt;
  final bool isPending;
  
  Transaction({
    String? id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    DateTime? createdAt,
    this.isPending = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
  
  /// Create a copy with updated fields
  Transaction copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? createdAt,
    bool? isPending,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isPending: isPending ?? this.isPending,
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isPending': isPending,
    };
  }
  
  /// Create from JSON map
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.fromString(json['type'] as String),
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPending: json['isPending'] as bool? ?? false,
    );
  }
  
  /// Create from AI parsed response
  factory Transaction.fromAIResponse(Map<String, dynamic> json) {
    return Transaction(
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.fromString(json['type'] as String? ?? 'expense'),
      category: json['category'] as String? ?? 'Other',
      isPending: true,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'Transaction(id: $id, title: $title, amount: $amount, type: ${type.name}, category: $category)';
  }
}
