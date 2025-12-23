import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../models/transaction.dart';
import '../core/theme/glassmorphism.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/balance_card.dart';
import '../router/app_router.dart';

/// Transactions list screen with filters
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _searchQuery = '';
  TransactionType? _typeFilter;
  String? _categoryFilter;
  
  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((t) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!t.title.toLowerCase().contains(query) &&
            !t.description.toLowerCase().contains(query) &&
            !t.category.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Type filter
      if (_typeFilter != null && t.type != _typeFilter) {
        return false;
      }
      
      // Category filter
      if (_categoryFilter != null && t.category != _categoryFilter) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final transactions = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);
    final categories = ref.watch(categoriesProvider);
    final balance = ref.watch(balanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expenses = ref.watch(totalExpensesProvider);
    
    final filteredTransactions = _filterTransactions(transactions);
    
    // Group by date
    final grouped = _groupByDate(filteredTransactions);
    
    return Scaffold(
      body: Container(
        decoration: Glassmorphism.meshBackground(isDark: isDark),
        child: SafeArea(
          child: Column(
            children: [
              // Header with menu button
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    Text(
                      'Transactions',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              // Balance Card at top
              BalanceCard(
                balance: balance,
                income: income,
                expenses: expenses,
                currencySymbol: currency.symbol,
              ),
              // Search and filters
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Search bar
                    TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 20),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Type filters
                          FilterChip(
                            label: const Text('All'),
                            selected: _typeFilter == null,
                            onSelected: (_) => setState(() => _typeFilter = null),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Income'),
                            selected: _typeFilter == TransactionType.income,
                            onSelected: (_) => setState(() {
                              _typeFilter = _typeFilter == TransactionType.income 
                                  ? null 
                                  : TransactionType.income;
                            }),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Expense'),
                            selected: _typeFilter == TransactionType.expense,
                            onSelected: (_) => setState(() {
                              _typeFilter = _typeFilter == TransactionType.expense 
                                  ? null 
                                  : TransactionType.expense;
                            }),
                          ),
                          const SizedBox(width: 16),
                          // Category dropdown
                          PopupMenuButton<String?>(
                            initialValue: _categoryFilter,
                            onSelected: (value) => setState(() => _categoryFilter = value),
                            child: Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_categoryFilter ?? 'Category'),
                                  const SizedBox(width: 4),
                                  const Icon(LucideIcons.chevronDown, size: 16),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: null,
                                child: Text('All Categories'),
                              ),
                              ...categories.map((c) => PopupMenuItem(
                                value: c.name,
                                child: Text(c.name),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Transactions list
              Expanded(
                child: filteredTransactions.isEmpty
                    ? EmptyState.noTransactions()
                    : ListView.builder(
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final date = grouped.keys.elementAt(index);
                          final dayTransactions = grouped[date]!;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  date,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                              // Transactions for this date
                              ...dayTransactions.map((t) => TransactionTile(
                                transaction: t,
                                currencySymbol: currency.symbol,
                                showDate: false,
                                onEdit: () {
                                  context.push(AppRoutes.editTransaction, extra: t);
                                },
                                onDelete: () async {
                                  await ref.read(transactionsProvider.notifier).delete(t.id);
                                },
                              )),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    
    for (final t in transactions) {
      final date = _formatDateHeader(t.createdAt);
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(t);
    }
    
    return grouped;
  }
  
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
