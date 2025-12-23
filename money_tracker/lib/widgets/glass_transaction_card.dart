import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction.dart';
import '../models/category.dart';

/// Glass-style transaction card for the new design
/// Features glassmorphism styling, category icon, and edit/delete actions
class GlassTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String currencySymbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  
  const GlassTransactionCard({
    super.key,
    required this.transaction,
    this.currencySymbol = 'SAR',
    this.onEdit,
    this.onDelete,
    this.onTap,
  });
  
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return LucideIcons.shoppingCart;
      case 'transport':
        return LucideIcons.car;
      case 'shopping':
        return LucideIcons.shoppingBag;
      case 'entertainment':
        return LucideIcons.film;
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
      case 'coffee':
        return LucideIcons.coffee;
      case 'fuel':
        return LucideIcons.fuel;
      default:
        return LucideIcons.moreHorizontal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = Categories.getByName(transaction.category);
    
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
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(LucideIcons.trash2, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap ?? onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: category.color.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  _getCategoryIcon(transaction.category),
                  color: category.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transaction.description.isNotEmpty)
                      Text(
                        transaction.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark 
                              ? Colors.grey[400] 
                              : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount and edit button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${transaction.amount.toStringAsFixed(2)} $currencySymbol',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        LucideIcons.edit2,
                        size: 18,
                        color: isDark 
                            ? Colors.grey[500] 
                            : Colors.grey[400],
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
