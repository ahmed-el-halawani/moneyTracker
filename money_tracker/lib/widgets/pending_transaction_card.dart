import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../core/theme/app_colors.dart';
import 'glass_card.dart';

/// Pending transaction card for staging area
class PendingTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currencySymbol;

  const PendingTransactionCard({
    super.key,
    required this.transaction,
    required this.onConfirm,
    required this.onEdit,
    required this.onDelete,
    this.currencySymbol = 'ر.س',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = Categories.getByName(transaction.category);
    final isIncome = transaction.type == TransactionType.income;
    final hasSplit =
        transaction.splitMembers != null &&
        transaction.splitMembers!.isNotEmpty;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderColor: hasSplit
          ? AppColors.primary.withOpacity(0.5)
          : AppColors.warning.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unified Header for both Split and Standard
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(category.icon),
                  color: category.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.category} • ${_formatDate(transaction.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : ''} ${transaction.amount.toStringAsFixed(0)} $currencySymbol',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: hasSplit
                              ? AppColors.primary
                              : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasSplit ? 'SPLIT' : 'PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: hasSplit
                              ? AppColors.primary
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          if (hasSplit) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.05), height: 1),
            const SizedBox(height: 16),

            // Split Footer
            Row(
              children: [
                // Avatars Stack
                Expanded(
                  child: Row(
                    children: [
                      // Stacked Avatars
                      SizedBox(
                        height: 32,
                        width:
                            (transaction.splitMembers!.take(3).length) * 20.0 +
                            14,
                        child: Stack(
                          children: [
                            for (
                              int i = 0;
                              i < transaction.splitMembers!.take(3).length;
                              i++
                            )
                              Positioned(
                                left: i * 20.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        transaction
                                            .splitMembers![i]
                                            .isCurrentUser
                                        ? AppColors.primary
                                        : Colors.grey.shade800,
                                    child: Text(
                                      transaction.splitMembers![i].name[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Member Names Truncated
                      Expanded(
                        child: Text(
                          transaction.splitMembers!
                                  .take(3)
                                  .map(
                                    (m) => m.isCurrentUser
                                        ? 'Me'
                                        : m.name.split(' ').first,
                                  )
                                  .join(', ') +
                              (transaction.splitMembers!.length > 3
                                  ? ' +${transaction.splitMembers!.length - 3}'
                                  : ''),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Split Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        LucideIcons.users,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Split Bill",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'utensils':
        return LucideIcons.utensils;
      case 'car':
        return LucideIcons.car;
      case 'shopping-bag':
        return LucideIcons.shoppingBag;
      case 'gamepad-2':
        return LucideIcons.gamepad2;
      case 'receipt':
        return LucideIcons.receipt;
      case 'wallet':
        return LucideIcons.wallet;
      case 'heart-pulse':
        return LucideIcons.heartPulse;
      case 'graduation-cap':
        return LucideIcons.graduationCap;
      case 'trending-up':
        return LucideIcons.trendingUp;
      case 'gift':
        return LucideIcons.gift;
      case 'more-horizontal':
      default:
        return LucideIcons.moreHorizontal;
    }
  }

  String _formatDate(DateTime date) {
    // Simple formatter if intl not available
    // HH:mm a
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return 'Today, $hour:$minute $period'; // Simplifying to "Today" for now as these are recent
  }
}
