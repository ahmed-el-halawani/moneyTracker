import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/providers/providers.dart';
import 'package:money_tracker/models/transaction.dart';

void main() {
  group('TransactionsNotifier', () {
    late ProviderContainer container;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('should start with empty transactions', () {
      final transactions = container.read(transactionsProvider);
      expect(transactions, isEmpty);
    });
    
    test('should add a transaction', () async {
      final notifier = container.read(transactionsProvider.notifier);
      
      final transaction = Transaction(
        title: 'Test',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      await notifier.add(transaction);
      
      final transactions = container.read(transactionsProvider);
      expect(transactions.length, 1);
      expect(transactions.first.title, 'Test');
    });
    
    test('should delete a transaction', () async {
      final notifier = container.read(transactionsProvider.notifier);
      
      final transaction = Transaction(
        title: 'To Delete',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      await notifier.add(transaction);
      expect(container.read(transactionsProvider).length, 1);
      
      await notifier.delete(transaction.id);
      expect(container.read(transactionsProvider), isEmpty);
    });
  });
  
  group('PendingTransactionsNotifier', () {
    late ProviderContainer container;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('should start with empty pending transactions', () {
      final pending = container.read(pendingTransactionsProvider);
      expect(pending, isEmpty);
    });
    
    test('should add pending transaction', () {
      final notifier = container.read(pendingTransactionsProvider.notifier);
      
      final transaction = Transaction(
        title: 'Pending',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      notifier.add(transaction);
      
      final pending = container.read(pendingTransactionsProvider);
      expect(pending.length, 1);
      expect(pending.first.isPending, true);
    });
    
    test('should remove pending transaction', () {
      final notifier = container.read(pendingTransactionsProvider.notifier);
      
      final transaction = Transaction(
        title: 'Pending',
        description: '',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      notifier.add(transaction);
      expect(container.read(pendingTransactionsProvider).length, 1);
      
      notifier.remove(transaction.id);
      expect(container.read(pendingTransactionsProvider), isEmpty);
    });
    
    test('should clear all pending transactions', () {
      final notifier = container.read(pendingTransactionsProvider.notifier);
      
      notifier.addMultiple([
        Transaction(
          title: 'Pending 1',
          description: '',
          amount: 100,
          type: TransactionType.expense,
          category: 'Food',
        ),
        Transaction(
          title: 'Pending 2',
          description: '',
          amount: 200,
          type: TransactionType.income,
          category: 'Salary',
        ),
      ]);
      
      expect(container.read(pendingTransactionsProvider).length, 2);
      
      notifier.clear();
      expect(container.read(pendingTransactionsProvider), isEmpty);
    });
  });
  
  group('Computed Providers', () {
    late ProviderContainer container;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('should calculate total income correctly', () async {
      final notifier = container.read(transactionsProvider.notifier);
      
      await notifier.addMultiple([
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
      
      final totalIncome = container.read(totalIncomeProvider);
      expect(totalIncome, 6000);
    });
    
    test('should calculate total expenses correctly', () async {
      final notifier = container.read(transactionsProvider.notifier);
      
      await notifier.addMultiple([
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
      
      final totalExpenses = container.read(totalExpensesProvider);
      expect(totalExpenses, 150);
    });
    
    test('should calculate balance correctly', () async {
      final notifier = container.read(transactionsProvider.notifier);
      
      await notifier.addMultiple([
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
      
      final balance = container.read(balanceProvider);
      expect(balance, 3000);
    });
    
    test('should return recent transactions (max 5)', () async {
      final notifier = container.read(transactionsProvider.notifier);
      
      // Add 7 transactions
      for (int i = 1; i <= 7; i++) {
        await notifier.add(Transaction(
          title: 'Transaction $i',
          description: '',
          amount: i * 100.0,
          type: TransactionType.expense,
          category: 'Food',
        ));
      }
      
      final recent = container.read(recentTransactionsProvider);
      expect(recent.length, 5);
    });
  });
}
