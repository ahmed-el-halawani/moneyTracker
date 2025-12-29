import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../core/theme/glassmorphism.dart';
import '../router/app_router.dart';
import '../models/transaction.dart';

/// Text input screen for creating transactions with keyboard
/// Features large textarea with AI parsing and example prompts
class TextTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final String? initialText;

  const TextTransactionScreen({
    super.key,
    this.transaction,
    this.initialText,
  });

  @override
  ConsumerState<TextTransactionScreen> createState() => _TextTransactionScreenState();
}

class _TextTransactionScreenState extends ConsumerState<TextTransactionScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      
      // Auto-process if initial text is provided
      if (widget.initialText != null && widget.initialText!.isNotEmpty) {
        _processWithAI();
      }
    });
    
    // Pre-fill if editing
    if (widget.transaction != null) {
      _textController.text = "Update ${widget.transaction!.title}: ";
    } else if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  Future<void> _processWithAI() async {
    if (_textController.text.trim().isEmpty) return;
    
    // Dismiss keyboard
    _focusNode.unfocus();
    
    setState(() => _isProcessing = true);
    
    setState(() => _isProcessing = true);
    
    final notifier = ref.read(voiceInputProvider.notifier);
    
    if (widget.transaction != null) {
      // Handle update
      final updated = await notifier.processUpdate(
        _textController.text, 
        widget.transaction!,
      );
      
      setState(() => _isProcessing = false);
      
      if (updated != null && mounted) {
        // Return updated object to parent (Edit Screen)
        // If we are in Edit mode, we don't save globally here, we let the parent handle it
        // UNLESS we are not coming from EditScreen (unlikely given current flow)
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes applied'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        context.pop(updated); 
      }
    } else {
      // Handle new transaction
      await notifier.processText(_textController.text);
      
      setState(() => _isProcessing = false);
      
      final pendingTransactions = ref.read(pendingTransactionsProvider);
      if (pendingTransactions.isNotEmpty && mounted) {
        context.pushReplacement(AppRoutes.reviewTransactions);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.transaction != null;
    
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
                      isEditing ? 'Edit Transaction' : 'New Transaction',
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
              
              // Content - Scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        isEditing ? 'Describe\nchanges' : 'Type your\nexpense',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use natural language. Our AI will automatically extract details like amount, category, and merchant.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Text input area
                      Container(
                        constraints: const BoxConstraints(minHeight: 200),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withOpacity(0.03)
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withOpacity(0.08)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Stack(
                          children: [
                            TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              maxLines: null,
                              minLines: 6,
                              textAlignVertical: TextAlignVertical.top,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _processWithAI(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g., I spent 50 riyals on groceries...',
                                hintStyle: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                            ),
                            // AI Parsing indicator
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'AI PARSING',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    LucideIcons.sparkles,
                                    size: 18,
                                    color: theme.colorScheme.onSurface.withOpacity(0.3),
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
              
              // Process button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processWithAI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Process with AI',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.arrowRight, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example text chip in private class
class _ExampleChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback onTap;
  
  const _ExampleChip({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ... same implementation as before ...
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withOpacity(0.03)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

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
