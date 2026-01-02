import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../widgets/glass_transaction_card.dart';
import '../widgets/voice_mic_button.dart';
import '../core/theme/glassmorphism.dart';
import '../router/app_router.dart';

/// Review pending transactions screen
/// Shows "Just Added" transactions with accept all, edit, and delete options
class ReviewTransactionsScreen extends ConsumerStatefulWidget {
  const ReviewTransactionsScreen({super.key});

  @override
  ConsumerState<ReviewTransactionsScreen> createState() =>
      _ReviewTransactionsScreenState();
}

class _ReviewTransactionsScreenState
    extends ConsumerState<ReviewTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceInputProvider.notifier).initialize();
    });
  }

  void _handleMicPressed() {
    final voiceState = ref.read(voiceInputProvider);
    if (voiceState.isListening) {
      ref.read(voiceInputProvider.notifier).stopListening();
    } else {
      ref.read(voiceInputProvider.notifier).startListening();
    }
  }

  void _startListening() {
    final voiceState = ref.read(voiceInputProvider);
    if (!voiceState.isListening) {
      ref.read(voiceInputProvider.notifier).startListening();
    }
  }

  void _stopListening() {
    final voiceState = ref.read(voiceInputProvider);
    if (voiceState.isListening) {
      ref.read(voiceInputProvider.notifier).stopListening();
    }
  }

  Future<void> _acceptAll() async {
    final pending = ref.read(pendingTransactionsProvider);
    for (final t in pending) {
      await ref
          .read(transactionsProvider.notifier)
          .add(t.copyWith(isPending: false));
    }
    ref.read(pendingTransactionsProvider.notifier).clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pending.length} transactions added!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final voiceState = ref.watch(voiceInputProvider);
    final pendingTransactions = ref.watch(pendingTransactionsProvider);
    final currency = ref.watch(currencyProvider);

    // Go back to voice screen if no pending
    if (pendingTransactions.isEmpty &&
        !voiceState.isListening &&
        !voiceState.isProcessing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
      });
    }

    return Scaffold(
      body: Container(
        decoration: Glassmorphism.meshBackground(isDark: isDark),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Text(
                      'Review Transactions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _GlassIconButton(
                      icon: LucideIcons.x,
                      onPressed: () {
                        // ref.read(pendingTransactionsProvider.notifier).clear();
                        context.pop();
                      },
                    ),
                  ],
                ),
              ),

              // Just Added label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'JUST ADDED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${pendingTransactions.length} items',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Transaction list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: pendingTransactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final transaction = pendingTransactions[index];
                    return GlassTransactionCard(
                      transaction: transaction,
                      currencySymbol: currency.symbol,
                      onEdit: () {
                        context.push(
                          AppRoutes.editTransaction,
                          extra: transaction,
                        );
                      },
                      onDelete: () {
                        ref
                            .read(pendingTransactionsProvider.notifier)
                            .remove(transaction.id);
                      },
                    );
                  },
                ),
              ),

              // Bottom section with Accept All and voice input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? const Color(0xFF101622) : Colors.white)
                          .withOpacity(0),
                      isDark ? const Color(0xFF101622) : Colors.white,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Accept All button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _acceptAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Accept All',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pendingTransactions.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Voice input bar - Clean transparent style
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side - Status and transcription
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (voiceState.isListening) ...[
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.green[400],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'LISTENING',
                                        style: TextStyle(
                                          color: Colors.green[400],
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  voiceState.transcription.isNotEmpty
                                      ? '"${voiceState.transcription}"'
                                      : voiceState.isListening
                                      ? '"Add taxi ride for 25..."'
                                      : 'Add more transactions',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Right side - Mic and keyboard buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mic button (Large & Glowing)
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: VoiceMicButton(
                                  isListening: voiceState.isListening,
                                  isProcessing: voiceState.isProcessing,
                                  soundLevel: voiceState.soundLevel,
                                  onPressed: _handleMicPressed,
                                  onLongPressStart: _startListening,
                                  onLongPressEnd: _stopListening,
                                  size: 64,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Keyboard button (Circular)
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.textTransaction),
                                  icon: const Icon(
                                    LucideIcons.keyboard,
                                    size: 22,
                                    color: Colors.white70,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass-style icon button
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.shade200,
            ),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
