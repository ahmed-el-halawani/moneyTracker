import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/voice_transaction_screen.dart';
import '../screens/review_transactions_screen.dart';
import '../screens/text_transaction_screen.dart';
import '../widgets/app_shell.dart';
import '../models/transaction.dart';

import '../screens/edit_transaction_screen.dart';

/// App routes
class AppRoutes {
  static const String home = '/';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add';
  static const String editTransaction = '/edit';
  static const String voiceTransaction = '/voice';
  static const String reviewTransactions = '/review';
  static const String textTransaction = '/text';
  static const String settings = '/settings';
}

/// Global navigator key
final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

/// App router configuration
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
    // Shell route for drawer navigation
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.transactions,
          name: 'transactions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TransactionsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    // Full screen routes
    GoRoute(
      path: AppRoutes.addTransaction,
      name: 'addTransaction',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AddTransactionScreen(),
    ),
    GoRoute(
      path: AppRoutes.editTransaction,
      name: 'editTransaction',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final transaction = state.extra as Transaction;
        return EditTransactionScreen(transaction: transaction);
      },
    ),
    GoRoute(
      path: AppRoutes.voiceTransaction,
      name: 'voiceTransaction',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const VoiceTransactionScreen(),
    ),
    GoRoute(
      path: AppRoutes.reviewTransactions,
      name: 'reviewTransactions',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ReviewTransactionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.textTransaction,
      name: 'textTransaction',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final transaction = state.extra as Transaction?;
        final initialText = state.uri.queryParameters['q'];
        return TextTransactionScreen(
          transaction: transaction,
          initialText: initialText,
        );
      },
    ),
  ],
);
