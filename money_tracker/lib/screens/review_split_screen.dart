import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction.dart';
import '../models/contact.dart';
import '../providers/providers.dart';
import '../core/theme/glassmorphism.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voice_mic_button.dart';
import 'package:uuid/uuid.dart';

class ReviewSplitScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const ReviewSplitScreen({super.key, required this.transaction});

  @override
  ConsumerState<ReviewSplitScreen> createState() => _ReviewSplitScreenState();
}

class _ReviewSplitScreenState extends ConsumerState<ReviewSplitScreen> {
  late Transaction _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;

    // Initialize voice input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceInputProvider.notifier).initialize();
      _resolveContacts();
    });
  }

  void _resolveContacts() {
    final contactsRepo = ref.read(contactRepositoryProvider);
    final members = _transaction.splitMembers;
    if (members == null) return;

    bool changed = false;
    final updatedMembers = members.map((member) {
      if (member.isResolved) return member;

      // Try to find matching contact by name
      final contact = contactsRepo.findByName(member.name);
      if (contact != null) {
        changed = true;
        // Apply contact details
        return SplitMember(
          name: member.name,
          amount: member.amount,
          isCurrentUser: member.isCurrentUser,
          note: member.note,
          email: contact.email,
          phone: contact.phone,
        );
      }
      return member;
    }).toList();

    if (changed) {
      setState(() {
        _transaction = _transaction.copyWith(splitMembers: updatedMembers);
      });

      // Update pending immediately so it's persisted if app closes
      ref
          .read(pendingTransactionsProvider.notifier)
          .update(_transaction.id, _transaction);
    }
  }

  Future<void> _processVoiceEdit(String text) async {
    final aiService = ref.read(aiServiceProvider);

    // Accumulate history
    final currentHistory = List<String>.from(_transaction.voiceHistory);
    currentHistory.add(text);

    // Use updated modifyTransaction with history context
    final updated = await aiService.modifyTransaction(
      _transaction,
      text,
      history: currentHistory,
    );

    if (updated != null) {
      if (mounted) {
        setState(() {
          // Preserve history in the updated transaction object
          _transaction = updated.copyWith(voiceHistory: currentHistory);
        });

        // Update pending immediately
        ref
            .read(pendingTransactionsProvider.notifier)
            .update(_transaction.id, _transaction);

        // Re-resolve contacts in case new members were added
        _resolveContacts();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Split updated!')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not understand update.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final splitMembers = _transaction.splitMembers ?? [];

    // Find Payer
    final payer = splitMembers.where((m) => m.isPayer).firstOrNull;

    // Monitor voice state for processing
    ref.listen(voiceInputProvider, (previous, next) {
      if (previous?.isProcessing == true &&
          next.isProcessing == false &&
          next.error == null &&
          next.transcription.isNotEmpty) {
        // This logic is usually for NEW transactions.
        // For EDIT, we need to manually trigger the "process edit" logic or
        // check if voiceInputProvider supports an "Edit Mode".
        // Current VoiceInputNotifier processes text into NEW transactions on stopListening(autoProcess: true).
        // We might need to handle the voice recording manually here.
      }
    });

    // We'll override the standard VoiceInput behavior for this screen
    // similar to how EditTransactionScreen does it (using processEditAudio or similar).

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
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      'Review Split',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance spacing
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Total Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              payer == null || payer.isCurrentUser
                                  ? 'Total Amount (You Paid)'
                                  : 'Total Amount (${payer.name} Paid)',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_transaction.amount.toStringAsFixed(2)}',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            // Me vs Others
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _SummaryItem(
                                  title: 'Your Share',
                                  amount: _calculateMyShare(splitMembers),
                                  color: AppColors.expenseColor,
                                ),
                                if (payer == null || payer.isCurrentUser)
                                  _SummaryItem(
                                    title: 'To Collect',
                                    amount: _calculateOthersShare(splitMembers),
                                    color: AppColors.incomeColor,
                                  )
                                else
                                  _SummaryItem(
                                    title: 'You Owe',
                                    amount: _calculateMyShare(splitMembers),
                                    color: AppColors.warning,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Participants List
                      Text(
                        'Participants',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...splitMembers.map(
                        (member) => _ParticipantTile(
                          member: member,
                          total: _transaction.amount,
                          isDark: isDark,
                          onResolve: (updatedMember) async {
                            // Save to Contact Repo
                            if (updatedMember.isResolved &&
                                !updatedMember.isCurrentUser) {
                              final contact = Contact(
                                id: const Uuid().v4(),
                                name: updatedMember.name,
                                email: updatedMember.email,
                                phone: updatedMember.phone,
                                createdAt: DateTime.now(),
                              );

                              final contactsRepo = ref.read(
                                contactRepositoryProvider,
                              );
                              final existing = contactsRepo.findByName(
                                updatedMember.name,
                              );
                              if (existing != null) {
                                await contactsRepo.update(
                                  Contact(
                                    id: existing.id,
                                    name: updatedMember.name,
                                    email: updatedMember.email,
                                    phone: updatedMember.phone,
                                    createdAt: existing.createdAt,
                                  ),
                                );
                              } else {
                                await contactsRepo.add(contact);
                              }
                            }

                            setState(() {
                              final index = _transaction.splitMembers!.indexOf(
                                member,
                              );
                              if (index != -1) {
                                // Create new list to ensure immutability
                                final newMembers = List<SplitMember>.from(
                                  _transaction.splitMembers!,
                                );
                                newMembers[index] = updatedMember;
                                _transaction = _transaction.copyWith(
                                  splitMembers: newMembers,
                                );
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Voice Edit Bar
              _VoiceEditBar(onVoiceResult: _processVoiceEdit),

              // Confirm Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Save changes
                      ref
                          .read(transactionsProvider.notifier)
                          .add(_transaction.copyWith(isPending: false));
                      ref
                          .read(pendingTransactionsProvider.notifier)
                          .remove(_transaction.id);
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Split confirmed!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Confirm Split',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  double _calculateMyShare(List<SplitMember> members) {
    return members
        .where((m) => m.isCurrentUser)
        .fold(0.0, (sum, m) => sum + m.amount);
  }

  double _calculateOthersShare(List<SplitMember> members) {
    return members
        .where((m) => !m.isCurrentUser)
        .fold(0.0, (sum, m) => sum + m.amount);
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          amount.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ParticipantTile extends ConsumerWidget {
  final SplitMember member;
  final double total;
  final bool isDark;
  final Function(SplitMember) onResolve;

  const _ParticipantTile({
    required this.member,
    required this.total,
    required this.isDark,
    required this.onResolve,
  });

  void _showParticipantOptions(BuildContext context, WidgetRef ref) {
    // Search for fuzzy matches
    final contactsRepo = ref.read(contactRepositoryProvider);
    final matches = contactsRepo.search(member.name); // Search by name

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      member.name[0],
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Resolve "${member.name}"',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (matches.isNotEmpty) ...[
                Text(
                  "Found ${matches.length} matches:",
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: matches
                        .map(
                          (contact) => ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.success,
                              radius: 16,
                              child: Icon(
                                LucideIcons.user,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(contact.name),
                            subtitle: Text(
                              [contact.email, contact.phone]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join(" • "),
                            ),
                            trailing: const Icon(LucideIcons.check),
                            onTap: () {
                              // Apply this contact
                              final updated = SplitMember(
                                name: contact
                                    .name, // Use contact name (capitalization etc)
                                amount: member.amount,
                                isCurrentUser: member.isCurrentUser,
                                note: member.note,
                                email: contact.email,
                                phone: contact.phone,
                              );
                              onResolve(updated);
                              Navigator.pop(context);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.grey.withOpacity(0.2)),
                const SizedBox(height: 16),
              ],

              // Options
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.plus, color: AppColors.primary),
                ),
                title: const Text('Create New Contact'),
                subtitle: const Text('Save details for future matches'),
                onTap: () {
                  Navigator.pop(context);
                  _showContactInputSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactInputSheet(BuildContext context) {
    final emailController = TextEditingController(text: member.email);
    final phoneController = TextEditingController(text: member.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add details for ${member.name}",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: const Icon(LucideIcons.mail),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: const Icon(LucideIcons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final updated = SplitMember(
                      name: member.name,
                      amount: member.amount,
                      isCurrentUser: member.isCurrentUser,
                      note: member.note,
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      phone: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                    );
                    onResolve(updated);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save Contact",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = total > 0 ? (member.amount / total) : 0.0;
    final isResolved = member.isResolved;

    return InkWell(
      onTap: () => _showParticipantOptions(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isResolved
                ? AppColors.warning.withOpacity(0.5)
                : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: member.isCurrentUser
                      ? AppColors.primary
                      : (!isResolved
                            ? AppColors.warning.withOpacity(0.2)
                            : Colors.grey.shade300),
                  foregroundColor: member.isCurrentUser
                      ? Colors.white
                      : (!isResolved ? AppColors.warning : Colors.black87),
                  child: Text(member.name[0].toUpperCase()),
                ),
                if (!isResolved)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.alertCircle,
                        size: 14,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                if (member.isPayer)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Text(
                        'PAYER',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isResolved && !member.isCurrentUser)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.checkCircle2,
                        size: 14,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (member.isCurrentUser)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (member.note != null)
                    Text(
                      member.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  if (!isResolved)
                    Text(
                      "Tap to resolve",
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (!member.isCurrentUser)
                    Text(
                      "Resolved",
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  member.amount.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceEditBar extends ConsumerStatefulWidget {
  final Function(String) onVoiceResult;

  const _VoiceEditBar({required this.onVoiceResult});

  @override
  ConsumerState<_VoiceEditBar> createState() => _VoiceEditBarState();
}

class _VoiceEditBarState extends ConsumerState<_VoiceEditBar> {
  Future<void> _handleStop(String? path) async {
    if (path == null) return;

    // Show local processing state
    // We can't easily change provider state here without method, so we trust UI

    final aiService = ref.read(aiServiceProvider);
    final text = await aiService.transcribeAudio(path);
    if (text != null && text.isNotEmpty) {
      widget.onVoiceResult(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              voiceState.isListening
                  ? "Listening..."
                  : voiceState.isProcessing
                  ? "Updating split..."
                  : "Tap mic to edit (e.g. 'Ali pays 50')",
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 16),
          VoiceMicButton(
            isListening: voiceState.isListening,
            isProcessing: voiceState.isProcessing,
            size: 56,
            onPressed: () async {
              final notifier = ref.read(voiceInputProvider.notifier);
              if (voiceState.isListening) {
                final path = await notifier.stopListening(autoProcess: false);
                await _handleStop(path);
              } else {
                notifier.startListening(autoProcess: false);
              }
            },
            onLongPressStart: () {
              ref
                  .read(voiceInputProvider.notifier)
                  .startListening(autoProcess: false);
            },
            onLongPressEnd: () async {
              final path = await ref
                  .read(voiceInputProvider.notifier)
                  .stopListening(autoProcess: false);
              await _handleStop(path);
            },
          ),
        ],
      ),
    );
  }
}
