import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Supabase (TODO: Replace with actual keys)
  // const supabaseUrl = 'YOUR_SUPABASE_URL';
  // const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  // 
  // await Supabase.initialize(
  //   url: supabaseUrl,
  //   anonKey: supabaseAnonKey,
  // );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FinancialTrackerApp(),
    ),
  );
}
