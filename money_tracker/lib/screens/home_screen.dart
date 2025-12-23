import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../core/theme/glassmorphism.dart';
import '../router/app_router.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/pending_transaction_card.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/empty_state.dart';

/// Home screen with dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textController = TextEditingController();
  String _lastTranscription = '';
  
  @override
  void initState() {
    super.initState();
    // Initialize voice input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceInputProvider.notifier).initialize();
    });
  }
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  void _syncTranscriptionToTextField(String transcription) {
    // Only update if transcription changed and is not empty
    if (transcription.isNotEmpty && transcription != _lastTranscription) {
      _lastTranscription = transcription;
      _textController.text = transcription;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: transcription.length),
      );
    }
  }
  
  void _handleVoiceButton() {
    final voiceState = ref.read(voiceInputProvider);
    if (voiceState.isListening) {
      ref.read(voiceInputProvider.notifier).stopListening();
    } else {
      // Clear text field when starting new voice input
      _textController.clear();
      _lastTranscription = '';
      ref.read(voiceInputProvider.notifier).startListening();
    }
  }
  
  void _handleTextSubmit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(voiceInputProvider.notifier).processText(text);
      _textController.clear();
      _lastTranscription = '';
    }
  }
  
  void _confirmPending(String id) async {
    final pending = ref.read(pendingTransactionsProvider);
    final transaction = pending.firstWhere((t) => t.id == id);
    
    await ref.read(transactionsProvider.notifier).add(transaction);
    ref.read(pendingTransactionsProvider.notifier).remove(id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _deletePending(String id) {
    ref.read(pendingTransactionsProvider.notifier).remove(id);
  }
  
  void _editPending(String id) {
    // TODO: Open edit dialog or screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final balance = ref.watch(balanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expenses = ref.watch(totalExpensesProvider);
    final currency = ref.watch(currencyProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final pendingTransactions = ref.watch(pendingTransactionsProvider);
    final voiceState = ref.watch(voiceInputProvider);
    
    // Sync transcription to text field when voice input changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTranscriptionToTextField(voiceState.transcription);
    });
    
    return Scaffold(
      body: Container(
        decoration: Glassmorphism.meshBackground(isDark: isDark),
        child: SafeArea(
          child: Stack(
            children: [
              // Scrollable content
              CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(LucideIcons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Tracker',
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  
                  // Pending Transactions
                  if (pendingTransactions.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Row(
                          children: [
                            Icon(LucideIcons.clock, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Pending Review',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${pendingTransactions.length} item${pendingTransactions.length > 1 ? 's' : ''}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final transaction = pendingTransactions[index];
                            return PendingTransactionCard(
                              transaction: transaction,
                              currencySymbol: currency.symbol,
                              onConfirm: () => _confirmPending(transaction.id),
                              onDelete: () => _deletePending(transaction.id),
                              onEdit: () => _editPending(transaction.id),
                            );
                          },
                          childCount: pendingTransactions.length,
                        ),
                      ),
                    ),
                  ],
                  
                  // Recent Transactions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        children: [
                          Icon(LucideIcons.history, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Transactions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.transactions),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (recentTransactions.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState.noTransactions(
                        onAddPressed: () => context.push(AppRoutes.addTransaction),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final transaction = recentTransactions[index];
                          return TransactionTile(
                            transaction: transaction,
                            currencySymbol: currency.symbol,
                            onDelete: () async {
                              await ref.read(transactionsProvider.notifier).delete(transaction.id);
                            },
                          );
                        },
                        childCount: recentTransactions.length,
                      ),
                    ),
                  
                  // Bottom padding for fixed input bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 200),
                  ),
                ],
              ),
              
              // Fixed bottom voice input bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _FixedVoiceInputBar(
                  voiceState: voiceState,
                  textController: _textController,
                  onVoicePressed: _handleVoiceButton,
                  onTextSubmit: _handleTextSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }
}

class _FixedVoiceInputBar extends StatelessWidget {
  final VoiceInputState voiceState;
  final TextEditingController textController;
  final VoidCallback onVoicePressed;
  final VoidCallback onTextSubmit;
  
  const _FixedVoiceInputBar({
    required this.voiceState,
    required this.textController,
    required this.onVoicePressed,
    required this.onTextSubmit,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        // Gradient fade at top
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F7)).withOpacity(0.8),
            isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F7),
          ],
          stops: const [0.0, 0.15, 0.3],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          // Glass card background
          color: isDark 
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.12)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, -8),
              spreadRadius: 0,
            ),
            if (!isDark)
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status text - above the button
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                color: voiceState.isListening 
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color,
                fontWeight: voiceState.isListening 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
              child: Text(
                voiceState.isListening
                    ? 'Listening...'
                    : voiceState.isProcessing
                        ? 'Processing with AI...'
                        : 'Tap to speak or type below',
              ),
            ),
            // Show transcription above the button when listening
            if (voiceState.transcription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  voiceState.transcription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Voice button - centered and prominent
            VoiceInputButton(
              isListening: voiceState.isListening,
              isProcessing: voiceState.isProcessing,
              soundLevel: voiceState.soundLevel,
              onPressed: onVoicePressed,
            ),
            // Show error if any
            if (voiceState.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  voiceState.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Text input row with enhanced styling
            Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    LucideIcons.pencil, 
                    size: 18,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: 'Or type: "Spent 50 on groceries"',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      onSubmitted: (_) => onTextSubmit(),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withBlue(230),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: onTextSubmit,
                      icon: const Icon(LucideIcons.send, size: 18),
                      color: Colors.white,
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

