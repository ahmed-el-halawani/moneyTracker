import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/shortcut_service.dart';
import 'providers/providers.dart';


/// Main application widget
class FinancialTrackerApp extends ConsumerWidget {
  const FinancialTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Initialize ShortcutService to listen for Siri commands
    ref.watch(shortcutServiceProvider);
    
    return MaterialApp.router(
      title: 'Financial Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.themeMode,
      routerConfig: appRouter,
    );
  }
}
