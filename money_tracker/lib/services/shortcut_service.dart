import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/services/ai_service.dart';
import 'package:money_tracker/providers/providers.dart';

/// Service to handle interactions with Siri Shortcuts via MethodChannel.
/// 
/// This service listens for text input from Siri and uses the [AIService]
/// to process it into a transaction.
/// 
/// The native iOS side calls the 'receiveTextFromSiri' method on the
/// 'com.moneytracker.siri/text' channel.
class ShortcutService {
  static const platform = MethodChannel('com.moneytracker.siri/text');
  final ProviderContainer container;

  ShortcutService(this.container) {
    _initialize();
  }

  void _initialize() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'receiveTextFromSiri') {
        final String text = call.arguments as String;
        await _handleSiriText(text);
      }
    });
  }

  Future<void> _handleSiriText(String text) async {
    try {
      final aiService = container.read(aiServiceProvider);
      // We use the existing addTransaction method which parses natural language
      await aiService.addTransaction(text);
      
      // Optionally, we could trigger a UI refresh or navigation here if the app is open
      // The provider update in addTransaction should already trigger UI updates
      
    } catch (e) {
      print('Error processing Siri text: $e');
    }
  }
}

// Global provider for the ShortcutService
final shortcutServiceProvider = Provider<ShortcutService>((ref) {
  // We pass the container to allow accessing other providers without a build context
  return ShortcutService(ref.container);
});
