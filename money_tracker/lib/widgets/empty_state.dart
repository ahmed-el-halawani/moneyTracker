import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Empty state widget for lists
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
  
  /// Preset for no transactions
  factory EmptyState.noTransactions({VoidCallback? onAddPressed}) {
    return EmptyState(
      icon: LucideIcons.receipt,
      title: 'No transactions yet',
      subtitle: 'Start tracking your finances by adding your first transaction.',
      action: onAddPressed != null
          ? ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Transaction'),
            )
          : null,
    );
  }
  
  /// Preset for no pending transactions
  factory EmptyState.noPending() {
    return const EmptyState(
      icon: LucideIcons.checkCircle,
      title: 'All caught up!',
      subtitle: 'No pending transactions to review.',
    );
  }
  
  /// Preset for search no results
  factory EmptyState.noResults() {
    return const EmptyState(
      icon: LucideIcons.searchX,
      title: 'No results found',
      subtitle: 'Try adjusting your search or filters.',
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
