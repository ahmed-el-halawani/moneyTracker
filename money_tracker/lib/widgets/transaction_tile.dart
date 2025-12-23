import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../core/theme/app_colors.dart';

/// Transaction list tile widget
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showDate;
  final String currencySymbol;
  
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showDate = true,
    this.currencySymbol = 'ر.س',
  });
  
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
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = Categories.getByName(transaction.category);
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? AppColors.incomeColor : AppColors.expenseColor;
    final amountPrefix = isIncome ? '+' : '-';
    
    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete != null 
          ? DismissDirection.endToStart 
          : DismissDirection.none,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.trash2, color: AppColors.error),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(transaction.category),
                    color: category.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              transaction.category,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: category.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (showDate) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(transaction.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Amounts and Edit
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountPrefix$currencySymbol ${transaction.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (transaction.isPending)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Pending',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        if (onEdit != null)
                          GestureDetector(
                            onTap: onEdit,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4),
                              child: Icon(
                                LucideIcons.edit2,
                                size: 16,
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
