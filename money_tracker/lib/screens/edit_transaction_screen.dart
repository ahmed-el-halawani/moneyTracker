import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../router/app_router.dart';
import '../models/transaction.dart';
import '../providers/providers.dart';
import '../widgets/voice_mic_button.dart';
import '../widgets/glass_transaction_card.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  late Transaction _draftTransaction;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _draftTransaction = widget.transaction;

    // Initialize voice input when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceInputProvider.notifier).initialize();
    });
  }

  Future<void> _switchToKeyboard() async {
    // Pass the DRAFT to text screen
    final result = await context.push<Transaction>(
      AppRoutes.textTransaction,
      extra: _draftTransaction,
    );

    // If text screen returns a transaction (simulated save), update draft
    if (result != null && mounted) {
      setState(() {
        _draftTransaction = result;
        _hasChanges = true;
      });
    }
  }

  void _saveChanges() async {
    if (_draftTransaction.isPending) {
      ref
          .read(pendingTransactionsProvider.notifier)
          .update(_draftTransaction.id, _draftTransaction);
    } else {
      await ref.read(transactionsProvider.notifier).update(_draftTransaction);
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceState = ref.watch(voiceInputProvider);
    final isListening = voiceState.isListening;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark blue background
      body: Stack(
        children: [
          // Background gradient mesh (Subtle)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header - Centered Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Edit Transaction',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Transaction Context Card - Diff View
                if (_hasChanges) ...[
                  // Original Transaction (Dimmed)
                  Opacity(
                    opacity: 0.6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: GlassTransactionCard(
                        transaction: widget.transaction,
                        currencySymbol: 'SAR', // Should fetch from settings
                      ),
                    ),
                  ),

                  // Arrow Indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Icon(
                      LucideIcons.arrowDown,
                      color: const Color(0xFF3B82F6),
                      size: 32,
                    ),
                  ),

                  // New Proposed Transaction (Highlighted)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: GlassTransactionCard(
                        transaction: _draftTransaction,
                        currencySymbol: 'SAR',
                      ),
                    ),
                  ),
                ] else ...[
                  // Single Card View (No changes yet)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GlassTransactionCard(
                      transaction: widget.transaction,
                      currencySymbol: 'SAR',
                    ),
                  ),
                ],

                const Spacer(flex: 2),

                // Listening Badge
                if (isListening || voiceState.isProcessing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6), // Blue dot
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'LISTENING',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Main Voice Heading (or Confirm actions if changes made and not listening)
                if (_hasChanges && !isListening && !voiceState.isProcessing)
                  Column(
                    children: [
                      const Text(
                        'Apply changes?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Reject Button
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _draftTransaction = widget.transaction;
                                _hasChanges = false;
                              });
                            },
                            icon: const Icon(
                              LucideIcons.undo,
                              color: Colors.white70,
                            ),
                            label: const Text(
                              'Reset',
                              style: TextStyle(color: Colors.white70),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Accept Button
                          ElevatedButton.icon(
                            onPressed: _saveChanges,
                            icon: const Icon(
                              LucideIcons.check,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      if (voiceState.transcription.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            '"${voiceState.transcription}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        )
                      else
                        Text(
                          'Tap mic to make changes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),

                const Spacer(flex: 1),

                // Mic and Keyboard Controls
                // Hide if we are showing confirmation buttons? No, user might want to edit more.
                // But having two primary actions is confusing.
                // Let's keep Mic accessible to refine further.
                Column(
                  children: [
                    VoiceMicButton(
                      size: 90,
                      isListening: isListening,
                      isProcessing: voiceState.isProcessing,
                      onPressed: () async {
                        if (isListening) {
                          // Stop listening and get the file path (don't auto-process as NEW transaction)
                          final path = await ref
                              .read(voiceInputProvider.notifier)
                              .stopListening(autoProcess: false);

                          if (path != null) {
                            // Process as EDIT update
                            final notifier = ref.read(
                              voiceInputProvider.notifier,
                            );
                            final updated = await notifier.processEditAudio(
                              path,
                              _draftTransaction,
                            );

                            if (updated != null && mounted) {
                              setState(() {
                                _draftTransaction = updated;
                                _hasChanges = true;
                              });
                              // Clear transcription to ready for next
                              notifier.clearTranscription();
                            }
                          }
                        } else {
                          ref
                              .read(voiceInputProvider.notifier)
                              .startListening(autoProcess: false);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isListening ? 'Tap microphone to stop' : 'Tap to speak',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // Keyboard Button
                Column(
                  children: [
                    IconButton(
                      onPressed: _switchToKeyboard,
                      iconSize: 24,
                      icon: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.keyboard,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use Keyboard',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
