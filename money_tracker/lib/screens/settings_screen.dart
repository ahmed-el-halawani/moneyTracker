import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../models/user_settings.dart';
import '../core/theme/glassmorphism.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    
    return Scaffold(
      body: Container(
        decoration: Glassmorphism.meshBackground(isDark: isDark),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header with menu button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Currency section
              _SettingsSection(
                title: 'Currency',
                icon: LucideIcons.wallet,
                children: [
                  _CurrencySelector(
                    currentCurrency: settings.currency,
                    onChanged: (currency) {
                      ref.read(settingsProvider.notifier).updateCurrency(currency);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Voice Language section
              _SettingsSection(
                title: 'Voice Language',
                icon: LucideIcons.mic,
                children: [
                  _LanguageSelector(
                    currentLanguage: settings.voiceLanguage,
                    onChanged: (language) {
                      ref.read(settingsProvider.notifier).updateVoiceLanguage(language);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Theme section
              _SettingsSection(
                title: 'Appearance',
                icon: LucideIcons.palette,
                children: [
                  _ThemeSelector(
                    currentTheme: settings.themeMode,
                    onChanged: (themeMode) {
                      ref.read(settingsProvider.notifier).updateThemeMode(themeMode);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Data section
              _SettingsSection(
                title: 'Data',
                icon: LucideIcons.database,
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.download),
                    title: const Text('Export Transactions'),
                    subtitle: const Text('Coming soon'),
                    enabled: false,
                    trailing: const Icon(LucideIcons.chevronRight),
                  ),
                  ListTile(
                    leading: Icon(LucideIcons.trash2, color: theme.colorScheme.error),
                    title: Text(
                      'Clear All Data',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: const Text('Delete all transactions'),
                    onTap: () => _showClearDataDialog(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // About section
              _SettingsSection(
                title: 'About',
                icon: LucideIcons.info,
                children: [
                  const ListTile(
                    leading: Icon(LucideIcons.sparkles),
                    title: Text('Financial Tracker AI'),
                    subtitle: Text('Version 1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.github),
                    title: const Text('Open Source'),
                    subtitle: const Text('View on GitHub'),
                    trailing: const Icon(LucideIcons.externalLink),
                    onTap: () {
                      // TODO: Open GitHub link
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your transactions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(transactionsProvider.notifier).clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final Currency currentCurrency;
  final ValueChanged<Currency> onChanged;
  
  const _CurrencySelector({
    required this.currentCurrency,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: Currency.values.map((currency) {
          final isSelected = currency == currentCurrency;
          return ChoiceChip(
            label: Text('${currency.symbol} ${currency.code}'),
            selected: isSelected,
            onSelected: (_) => onChanged(currency),
          );
        }).toList(),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final VoiceLanguage currentLanguage;
  final ValueChanged<VoiceLanguage> onChanged;
  
  const _LanguageSelector({
    required this.currentLanguage,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: VoiceLanguage.values.map((language) {
        final isSelected = language == currentLanguage;
        return RadioListTile<VoiceLanguage>(
          title: Text(language.displayName),
          subtitle: Text(language.code),
          value: language,
          groupValue: currentLanguage,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        );
      }).toList(),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onChanged;
  
  const _ThemeSelector({
    required this.currentTheme,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(LucideIcons.laptop),
            label: Text('System'),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(LucideIcons.sun),
            label: Text('Light'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(LucideIcons.moon),
            label: Text('Dark'),
          ),
        ],
        selected: {currentTheme},
        onSelectionChanged: (selection) {
          onChanged(selection.first);
        },
      ),
    );
  }
}
