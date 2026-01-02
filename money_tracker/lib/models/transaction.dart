import 'package:uuid/uuid.dart';

/// Transaction type enum
enum TransactionType {
  income,
  expense,
  transferOut,
  transferIn;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transferOut:
        return 'Transfer Out';
      case TransactionType.transferIn:
        return 'Transfer In';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer_out':
      case 'transferout':
        return TransactionType.transferOut;
      case 'transfer_in':
      case 'transferin':
        return TransactionType.transferIn;
      default:
        return TransactionType.expense;
    }
  }
}

/// Split payment member
class SplitMember {
  final String name;
  final double amount;
  final bool isCurrentUser;
  final bool isPayer;
  final String? note; // Contextual note like "lived next door"
  final String? email;
  final String? phone;

  SplitMember({
    required this.name,
    required this.amount,
    this.isCurrentUser = false,
    this.isPayer = false,
    this.note,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'isCurrentUser': isCurrentUser,
      'isPayer': isPayer,
      'note': note,
      'email': email,
      'phone': phone,
    };
  }

  factory SplitMember.fromJson(Map<String, dynamic> json) {
    return SplitMember(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      isPayer: json['isPayer'] as bool? ?? false,
      note: json['note'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  /// Helper to check if member is resolved (has contact info or is me)
  bool get isResolved =>
      isCurrentUser ||
      (email != null && email!.isNotEmpty) ||
      (phone != null && phone!.isNotEmpty);

  @override
  String toString() =>
      'SplitMember(name: $name, amount: $amount, isMe: $isCurrentUser, resolved: $isResolved)';
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
  final bool isIncrease;
  final String? emoji;
  final List<SplitMember>? splitMembers;
  final List<String> voiceHistory;

  Transaction({
    String? id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    DateTime? createdAt,
    this.isPending = false,
    bool? isIncrease,
    this.emoji,
    this.splitMembers,
    List<String>? voiceHistory,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       isIncrease =
           isIncrease ??
           (type == TransactionType.income ||
               type == TransactionType.transferIn),
       voiceHistory = voiceHistory ?? [];

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
    bool? isIncrease,
    String? emoji,
    List<SplitMember>? splitMembers,
    List<String>? voiceHistory,
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
      isIncrease: isIncrease ?? this.isIncrease,
      emoji: emoji ?? this.emoji,
      splitMembers: splitMembers ?? this.splitMembers,
      voiceHistory: voiceHistory ?? this.voiceHistory,
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
      'isIncrease': isIncrease,
      'emoji': emoji,
      'splitMembers': splitMembers?.map((e) => e.toJson()).toList(),
      'voiceHistory': voiceHistory,
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
      isIncrease: json['isIncrease'] as bool?,
      emoji: json['emoji'] as String?,
      splitMembers: (json['splitMembers'] as List<dynamic>?)
          ?.map((e) => SplitMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      voiceHistory: (json['voiceHistory'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Create from AI parsed response
  factory Transaction.fromAIResponse(Map<String, dynamic> json) {
    final t = Transaction(
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.fromString(json['type'] as String? ?? 'expense'),
      category: json['category'] as String? ?? 'Other',
      isPending: true,
      isIncrease: json['is_increase'] as bool?,
      emoji: json['emoji'] as String?,
      // Handle both snake_case (AI Prompt) and camelCase (Modify Input) keys
      splitMembers:
          ((json['split_members'] ?? json['splitMembers']) as List<dynamic>?)
              ?.map(
                (e) => SplitMember(
                  name: e['name'],
                  amount: (e['amount'] as num).toDouble(),
                  isCurrentUser:
                      e['is_current_user'] ?? e['isCurrentUser'] ?? false,
                  isPayer: e['is_payer'] ?? e['isPayer'] ?? false,
                  note: e['note'],
                  email: e['email'],
                  phone: e['phone'],
                ),
              )
              .toList(),
    );
    return t;
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
    return 'Transaction(id: $id, title: $title, amount: $amount, type: ${type.name}, isIncrease: $isIncrease, splitMembers: $splitMembers)';
  }
}
