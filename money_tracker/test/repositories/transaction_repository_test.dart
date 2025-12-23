import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/services/storage_service.dart';
import 'package:money_tracker/repositories/transaction_repository.dart';
import 'package:money_tracker/models/transaction.dart';

void main() {
  group('TransactionRepository', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late TransactionRepository repository;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      repository = TransactionRepository(storage);
    });
    
    test('should return empty list when no transactions exist', () {
      final transactions = repository.getAllTransactions();
      expect(transactions, isEmpty);
    });
    
    test('should add a transaction', () async {
      final transaction = Transaction(
        title: 'Test Transaction',
        description: 'Test',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      final result = await repository.addTransaction(transaction);
      expect(result, true);
      
      final transactions = repository.getAllTransactions();
      expect(transactions.length, 1);
      expect(transactions.first.title, 'Test Transaction');
    });
    
    test('should add multiple transactions', () async {
      final transactions = [
        Transaction(
          title: 'Transaction 1',
          description: '',
          amount: 100,
          type: TransactionType.expense,
          category: 'Food',
        ),
        Transaction(
          title: 'Transaction 2',
          description: '',
          amount: 200,
          type: TransactionType.income,
          category: 'Salary',
        ),
      ];
      
      final result = await repository.addTransactions(transactions);
      expect(result, true);
      
      final all = repository.getAllTransactions();
      expect(all.length, 2);
    });
    
    test('should update a transaction', () async {
      final transaction = Transaction(
        title: 'Original',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      await repository.addTransaction(transaction);
      
      final updated = transaction.copyWith(
        title: 'Updated',
        amount: 200,
      );
      
      final result = await repository.updateTransaction(updated);
      expect(result, true);
      
      final transactions = repository.getAllTransactions();
      expect(transactions.first.title, 'Updated');
      expect(transactions.first.amount, 200);
    });
    
    test('should delete a transaction', () async {
      final transaction = Transaction(
        title: 'To Delete',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      await repository.addTransaction(transaction);
      expect(repository.getAllTransactions().length, 1);
      
      final result = await repository.deleteTransaction(transaction.id);
      expect(result, true);
      
      expect(repository.getAllTransactions(), isEmpty);
    });
    
    test('should get transaction by ID', () async {
      final transaction = Transaction(
        title: 'Find Me',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      await repository.addTransaction(transaction);
      
      final found = repository.getById(transaction.id);
      expect(found, isNotNull);
      expect(found!.title, 'Find Me');
    });
    
    test('should return null for non-existent ID', () {
      final found = repository.getById('non-existent-id');
      expect(found, isNull);
    });
    
    test('should filter by type', () async {
      await repository.addTransactions([
        Transaction(
          title: 'Expense 1',
          description: '',
          amount: 100,
          type: TransactionType.expense,
          category: 'Food',
        ),
        Transaction(
          title: 'Income 1',
          description: '',
          amount: 1000,
          type: TransactionType.income,
          category: 'Salary',
        ),
        Transaction(
          title: 'Expense 2',
          description: '',
          amount: 50,
          type: TransactionType.expense,
          category: 'Transport',
        ),
      ]);
      
      final expenses = repository.getByType(TransactionType.expense);
      expect(expenses.length, 2);
      
      final income = repository.getByType(TransactionType.income);
      expect(income.length, 1);
    });
    
    test('should filter by category', () async {
      await repository.addTransactions([
        Transaction(
          title: 'Food 1',
          description: '',
          amount: 100,
          type: TransactionType.expense,
          category: 'Food',
        ),
        Transaction(
          title: 'Food 2',
          description: '',
          amount: 50,
          type: TransactionType.expense,
          category: 'Food',
        ),
        Transaction(
          title: 'Transport',
          description: '',
          amount: 30,
          type: TransactionType.expense,
          category: 'Transport',
        ),
      ]);
      
      final foodTransactions = repository.getByCategory('Food');
      expect(foodTransactions.length, 2);
      
      final transportTransactions = repository.getByCategory('Transport');
      expect(transportTransactions.length, 1);
    });
    
    test('should calculate total income', () async {
      await repository.addTransactions([
        Transaction(
          title: 'Salary',
          description: '',
          amount: 5000,
          type: TransactionType.income,
          category: 'Salary',
        ),
        Transaction(
          title: 'Bonus',
          description: '',
          amount: 1000,
          type: TransactionType.income,
          category: 'Salary',
        ),
        Transaction(
          title: 'Expense',
          description: '',
          amount: 100,
          type: TransactionType.expense,
          category: 'Food',
        ),
      ]);
      
      final totalIncome = repository.getTotalIncome();
      expect(totalIncome, 6000);
    });
    
    test('should calculate total expenses', () async {
      await repository.addTransactions([
        Transaction(
          title: 'Food',
          description: '',
          amount: 100,
          type: TransactionType.expense,
          category: 'Food',
        ),
        Transaction(
          title: 'Transport',
          description: '',
          amount: 50,
          type: TransactionType.expense,
          category: 'Transport',
        ),
        Transaction(
          title: 'Income',
          description: '',
          amount: 5000,
          type: TransactionType.income,
          category: 'Salary',
        ),
      ]);
      
      final totalExpenses = repository.getTotalExpenses();
      expect(totalExpenses, 150);
    });
    
    test('should calculate balance', () async {
      await repository.addTransactions([
        Transaction(
          title: 'Salary',
          description: '',
          amount: 5000,
          type: TransactionType.income,
          category: 'Salary',
        ),
        Transaction(
          title: 'Rent',
          description: '',
          amount: 1500,
          type: TransactionType.expense,
          category: 'Bills',
        ),
        Transaction(
          title: 'Food',
          description: '',
          amount: 500,
          type: TransactionType.expense,
          category: 'Food',
        ),
      ]);
      
      final balance = repository.getBalance();
      expect(balance, 3000); // 5000 - 1500 - 500
    });
    
    test('should get spending by category', () async {
      await repository.addTransactions([
        Transaction(
          title: 'Food 1',
          description: '',
          amount: 100,
          type: TransactionType.expense,
          category: 'Food',
        ),
        Transaction(
          title: 'Food 2',
          description: '',
          amount: 50,
          type: TransactionType.expense,
          category: 'Food',
        ),
        Transaction(
          title: 'Transport',
          description: '',
          amount: 75,
          type: TransactionType.expense,
          category: 'Transport',
        ),
      ]);
      
      final spending = repository.getSpendingByCategory();
      expect(spending['Food'], 150);
      expect(spending['Transport'], 75);
    });
    
    test('should clear all transactions', () async {
      await repository.addTransactions([
        Transaction(
          title: 'Transaction 1',
          description: '',
          amount: 100,
          type: TransactionType.expense,
          category: 'Food',
        ),
        Transaction(
          title: 'Transaction 2',
          description: '',
          amount: 200,
          type: TransactionType.income,
          category: 'Salary',
        ),
      ]);
      
      expect(repository.getAllTransactions().length, 2);
      
      final result = await repository.clearAll();
      expect(result, true);
      
      expect(repository.getAllTransactions(), isEmpty);
    });
    
    test('should sort transactions by date (newest first)', () async {
      final oldTransaction = Transaction(
        title: 'Old',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
        createdAt: DateTime(2024, 1, 1),
      );
      
      final newTransaction = Transaction(
        title: 'New',
        description: '',
        amount: 200,
        type: TransactionType.expense,
        category: 'Food',
        createdAt: DateTime(2024, 12, 31),
      );
      
      // Add old first, then new
      await repository.addTransaction(oldTransaction);
      await repository.addTransaction(newTransaction);
      
      final transactions = repository.getAllTransactions();
      expect(transactions.first.title, 'New');
      expect(transactions.last.title, 'Old');
    });
  });
}
