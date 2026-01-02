import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/providers/providers.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FinancialTrackerApp(),
      ),
    );

    // Verify that the app title or home screen is present
    // Since we can't easily check for text without knowing exact home screen state,
    // we'll just check if the MaterialApp is built.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

