import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    test('should create a transaction with all required fields', () {
      final transaction = Transaction(
        title: 'Grocery Shopping',
        description: 'Weekly groceries',
        amount: 150.50,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      expect(transaction.title, 'Grocery Shopping');
      expect(transaction.description, 'Weekly groceries');
      expect(transaction.amount, 150.50);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.category, 'Food');
      expect(transaction.isPending, false);
      expect(transaction.id, isNotEmpty);
      expect(transaction.createdAt, isNotNull);
    });
    
    test('should generate unique IDs for different transactions', () {
      final transaction1 = Transaction(
        title: 'Transaction 1',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Other',
      );
      
      final transaction2 = Transaction(
        title: 'Transaction 2',
        description: '',
        amount: 200,
        type: TransactionType.income,
        category: 'Salary',
      );
      
      expect(transaction1.id, isNot(transaction2.id));
    });
    
    test('should create a copy with updated fields', () {
      final original = Transaction(
        title: 'Original',
        description: 'Original description',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      final updated = original.copyWith(
        title: 'Updated',
        amount: 200,
        isPending: true,
      );
      
      expect(updated.id, original.id);
      expect(updated.title, 'Updated');
      expect(updated.description, 'Original description');
      expect(updated.amount, 200);
      expect(updated.isPending, true);
    });
    
    test('should convert to JSON and back', () {
      final original = Transaction(
        id: 'test-id-123',
        title: 'Test Transaction',
        description: 'Test description',
        amount: 99.99,
        type: TransactionType.income,
        category: 'Salary',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        isPending: true,
      );
      
      final json = original.toJson();
      final restored = Transaction.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.amount, original.amount);
      expect(restored.type, original.type);
      expect(restored.category, original.category);
      expect(restored.createdAt, original.createdAt);
      expect(restored.isPending, original.isPending);
    });
    
    test('should create from AI response with defaults', () {
      final aiResponse = {
        'title': 'Lunch',
        'amount': 25,
        'type': 'expense',
        'category': 'Food',
      };
      
      final transaction = Transaction.fromAIResponse(aiResponse);
      
      expect(transaction.title, 'Lunch');
      expect(transaction.description, '');
      expect(transaction.amount, 25.0);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.category, 'Food');
      expect(transaction.isPending, true);
    });
    
    test('should handle missing fields in AI response gracefully', () {
      final aiResponse = <String, dynamic>{};
      
      final transaction = Transaction.fromAIResponse(aiResponse);
      
      expect(transaction.title, 'Untitled');
      expect(transaction.description, '');
      expect(transaction.amount, 0.0);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.category, 'Other');
    });
  });
  
  group('TransactionType', () {
    test('should parse type from string', () {
      expect(TransactionType.fromString('income'), TransactionType.income);
      expect(TransactionType.fromString('expense'), TransactionType.expense);
      expect(TransactionType.fromString('INCOME'), TransactionType.income);
      expect(TransactionType.fromString('EXPENSE'), TransactionType.expense);
      expect(TransactionType.fromString('unknown'), TransactionType.expense);
    });
    
    test('should have correct display names', () {
      expect(TransactionType.income.displayName, 'Income');
      expect(TransactionType.expense.displayName, 'Expense');
    });
  });
  
  group('Transaction Equality', () {
    test('transactions with same ID should be equal', () {
      final t1 = Transaction(
        id: 'same-id',
        title: 'Title 1',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      final t2 = Transaction(
        id: 'same-id',
        title: 'Title 2',
        description: 'Different',
        amount: 200,
        type: TransactionType.income,
        category: 'Salary',
      );
      
      expect(t1, t2);
      expect(t1.hashCode, t2.hashCode);
    });
    
    test('transactions with different IDs should not be equal', () {
      final t1 = Transaction(
        id: 'id-1',
        title: 'Same Title',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      final t2 = Transaction(
        id: 'id-2',
        title: 'Same Title',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      expect(t1, isNot(t2));
    });
  });
}
