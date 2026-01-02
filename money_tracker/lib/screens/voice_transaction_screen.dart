import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../widgets/voice_mic_button.dart';
import '../core/theme/glassmorphism.dart';
import '../router/app_router.dart';

/// Full-screen voice input experience for creating transactions
/// Features large centered microphone with animated ripples and real-time transcription
class VoiceTransactionScreen extends ConsumerStatefulWidget {
  const VoiceTransactionScreen({super.key});

  @override
  ConsumerState<VoiceTransactionScreen> createState() =>
      _VoiceTransactionScreenState();
}

class _VoiceTransactionScreenState
    extends ConsumerState<VoiceTransactionScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize voice service when screen opens
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final voiceState = ref.watch(voiceInputProvider);
    final pendingTransactions = ref.watch(pendingTransactionsProvider);

    // Navigate to review screen when transactions are pending
    if (pendingTransactions.isNotEmpty &&
        !voiceState.isListening &&
        !voiceState.isProcessing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement(AppRoutes.reviewTransactions);
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
                    const SizedBox(width: 40), // Spacer for balance
                    Text(
                      'New Transaction',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _GlassIconButton(
                      icon: LucideIcons.x,
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),

              // Main content area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status badge
                    _StatusBadge(
                      isListening: voiceState.isListening,
                      isProcessing: voiceState.isProcessing,
                    ),
                    const SizedBox(height: 24),

                    // Transcription text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        voiceState.transcription.isNotEmpty
                            ? '"${voiceState.transcription}"'
                            : voiceState.isListening
                            ? '"I spent 50 riyals on groceries..."'
                            : 'Tap to start speaking',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: voiceState.transcription.isNotEmpty
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Hint text
                    Text(
                      voiceState.isListening
                          ? 'Say "I spent 50 riyals on groceries"'
                          : 'Use natural language to describe your transaction',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Error message
                    if (voiceState.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          voiceState.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),

                    // Large mic button
                    VoiceMicButton(
                      isListening: voiceState.isListening,
                      isProcessing: voiceState.isProcessing,
                      soundLevel: voiceState.soundLevel,
                      onPressed: _handleMicPressed,
                      onLongPressStart: _startListening,
                      onLongPressEnd: _stopListening,
                    ),

                    const SizedBox(height: 24),

                    // Tap hint
                    Text(
                      voiceState.isListening
                          ? 'Tap microphone to stop'
                          : 'Tap to speak',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom action - Use Keyboard
              Padding(
                padding: const EdgeInsets.all(24),
                child: _KeyboardToggleButton(
                  onPressed: () => context.push(AppRoutes.textTransaction),
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

/// Status badge showing listening/processing state
class _StatusBadge extends StatelessWidget {
  final bool isListening;
  final bool isProcessing;

  const _StatusBadge({required this.isListening, required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (!isListening && !isProcessing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isProcessing ? 'PROCESSING' : 'LISTENING',
            style: TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Button to toggle to keyboard input
class _KeyboardToggleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _KeyboardToggleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade200,
              ),
            ),
            child: Icon(
              LucideIcons.keyboard,
              color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use Keyboard',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
