import '../models/transaction.dart';
import '../services/storage_service.dart';

/// Repository for transaction CRUD operations
class TransactionRepository {
  final StorageService _storage;

  TransactionRepository(this._storage);

  /// Get all saved transactions (excluding pending)
  List<Transaction> getAllTransactions() {
    final data = _storage.getTransactions();
    return data
        .map((json) => Transaction.fromJson(json))
        .where((t) => !t.isPending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get pending transactions
  List<Transaction> getPendingTransactions() {
    final data = _storage.getTransactions();
    return data
        .map((json) => Transaction.fromJson(json))
        .where((t) => t.isPending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Add a new transaction
  Future<bool> addTransaction(Transaction transaction) async {
    final all = _storage.getTransactions();
    all.add(transaction.toJson());
    return await _storage.saveTransactions(all);
  }

  /// Add multiple transactions
  Future<bool> addTransactions(List<Transaction> transactions) async {
    final all = _storage.getTransactions();
    for (final t in transactions) {
      all.add(t.toJson());
    }
    return await _storage.saveTransactions(all);
  }

  /// Update an existing transaction
  Future<bool> updateTransaction(Transaction transaction) async {
    final all = _storage.getTransactions();
    final index = all.indexWhere((t) => t['id'] == transaction.id);
    if (index == -1) return false;

    all[index] = transaction.toJson();
    return await _storage.saveTransactions(all);
  }

  /// Delete a transaction by ID
  Future<bool> deleteTransaction(String id) async {
    final all = _storage.getTransactions();
    all.removeWhere((t) => t['id'] == id);
    return await _storage.saveTransactions(all);
  }

  /// Delete multiple transactions
  Future<bool> deleteTransactions(List<String> ids) async {
    final all = _storage.getTransactions();
    all.removeWhere((t) => ids.contains(t['id']));
    return await _storage.saveTransactions(all);
  }

  /// Get transaction by ID
  Transaction? getById(String id) {
    final all = _storage.getTransactions();
    final found = all.where((t) => t['id'] == id).firstOrNull;
    return found != null ? Transaction.fromJson(found) : null;
  }

  /// Get transactions by type
  List<Transaction> getByType(TransactionType type) {
    return getAllTransactions().where((t) => t.type == type).toList();
  }

  /// Get transactions by category
  List<Transaction> getByCategory(String category) {
    return getAllTransactions().where((t) => t.category == category).toList();
  }

  /// Get transactions within date range
  List<Transaction> getByDateRange(DateTime start, DateTime end) {
    return getAllTransactions()
        .where((t) => t.createdAt.isAfter(start) && t.createdAt.isBefore(end))
        .toList();
  }

  /// Get total income
  double getTotalIncome() {
    return getAllTransactions()
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get total expenses
  double getTotalExpenses() {
    return getAllTransactions()
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get balance
  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
  }

  /// Get spending by category
  Map<String, double> getSpendingByCategory() {
    final expenses = getAllTransactions().where(
      (t) => t.type == TransactionType.expense,
    );

    final Map<String, double> result = {};
    for (final t in expenses) {
      result[t.category] = (result[t.category] ?? 0) + t.amount;
    }
    return result;
  }

  /// Clear all transactions
  Future<bool> clearAll() async {
    return await _storage.clearTransactions();
  }
}
