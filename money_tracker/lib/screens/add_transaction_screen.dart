import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../core/theme/app_colors.dart';

/// Screen for adding/editing transactions manually
class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  
  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _aiInputController = TextEditingController();
  
  TransactionType _type = TransactionType.expense;
  String _category = 'Other';
  bool _isLoading = false;
  bool _isAIProcessing = false;
  bool _showAIInput = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _descriptionController.text = widget.transaction!.description;
      _amountController.text = widget.transaction!.amount.toString();
      _type = widget.transaction!.type;
      _category = widget.transaction!.category;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _aiInputController.dispose();
    super.dispose();
  }
  
  /// Process AI text input to update form fields
  Future<void> _processAIInput(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() => _isAIProcessing = true);
    
    final aiService = ref.read(aiServiceProvider);
    final result = await aiService.parseTransaction(text);
    
    if (result.success && result.transactions.isNotEmpty) {
      final parsed = result.transactions.first;
      setState(() {
        _titleController.text = parsed.title;
        _descriptionController.text = parsed.description;
        _amountController.text = parsed.amount.toString();
        _type = parsed.type;
        _category = parsed.category;
        _aiInputController.clear();
        _showAIInput = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI updated transaction details!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Could not parse input'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    
    setState(() => _isAIProcessing = false);
  }
  
  
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final transaction = Transaction(
      id: widget.transaction?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      amount: double.parse(_amountController.text),
      type: _type,
      category: _category,
      createdAt: widget.transaction?.createdAt,
    );
    
    bool success;
    if (widget.transaction != null) {
      success = await ref.read(transactionsProvider.notifier).update(transaction);
    } else {
      success = await ref.read(transactionsProvider.notifier).add(transaction);
    }
    
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.transaction != null 
              ? 'Transaction updated!' 
              : 'Transaction added!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _type == TransactionType.income
        ? Categories.incomeCategories
        : Categories.expenseCategories;
    
    // Ensure selected category is valid for current type
    if (!categories.any((c) => c.name == _category)) {
      _category = categories.first.name;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI Input Section
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with toggle
                  InkWell(
                    onTap: () => setState(() => _showAIInput = !_showAIInput),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.sparkles,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Assistant',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Describe with voice or text',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _showAIInput ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expandable AI input area
                  if (_showAIInput) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _aiInputController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'e.g., "Change amount to 50 for groceries"',
                              prefixIcon: const Icon(LucideIcons.messageSquare),
                              suffixIcon: _isAIProcessing
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        LucideIcons.send,
                                        color: theme.colorScheme.primary,
                                      ),
                                      onPressed: () => _processAIInput(_aiInputController.text),
                                    ),
                            ),
                            onSubmitted: _processAIInput,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Describe the transaction in natural language',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Expense',
                      icon: LucideIcons.trendingDown,
                      color: AppColors.expenseColor,
                      isSelected: _type == TransactionType.expense,
                      onTap: () => setState(() => _type = TransactionType.expense),
                    ),
                  ),
                  Expanded(
                    child: _TypeButton(
                      label: 'Income',
                      icon: LucideIcons.trendingUp,
                      color: AppColors.incomeColor,
                      isSelected: _type == TransactionType.income,
                      onTap: () => setState(() => _type = TransactionType.income),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    ref.watch(currencyProvider).symbol,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(),
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Grocery Shopping',
                prefixIcon: Icon(LucideIcons.type),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add more details...',
                prefixIcon: Icon(LucideIcons.alignLeft),
              ),
            ),
            const SizedBox(height: 24),
            
            // Category
            Text(
              'Category',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) {
                final isSelected = _category == c.name;
                return ChoiceChip(
                  label: Text(c.name),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _category = c.name),
                  avatar: isSelected ? null : CircleAvatar(
                    backgroundColor: c.color.withOpacity(0.2),
                    child: Icon(
                      _getCategoryIcon(c.name),
                      size: 16,
                      color: c.color,
                    ),
                  ),
                  selectedColor: c.color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? c.color : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            
            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _type == TransactionType.income 
                    ? AppColors.incomeColor 
                    : AppColors.primaryLight,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.transaction != null ? 'Update Transaction' : 'Add Transaction',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return LucideIcons.utensils;
      case 'transport':
        return LucideIcons.car;
      case 'shopping':
        return LucideIcons.shoppingBag;
      case 'entertainment':
        return LucideIcons.gamepad2;
      case 'bills':
        return LucideIcons.receipt;
      case 'salary':
        return LucideIcons.wallet;
      case 'healthcare':
        return LucideIcons.heartPulse;
      case 'education':
        return LucideIcons.graduationCap;
      case 'investment':
        return LucideIcons.trendingUp;
      case 'gifts':
        return LucideIcons.gift;
      default:
        return LucideIcons.moreHorizontal;
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
