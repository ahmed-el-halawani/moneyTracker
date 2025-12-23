import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/speech_service.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';
import '../models/transaction.dart';
import '../models/user_settings.dart';
import '../models/category.dart';

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});


/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

/// Transaction repository provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TransactionRepository(storage);
});

/// Settings repository provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsRepository(storage);
});

/// AI service provider
final aiServiceProvider = Provider<AIService>((ref) {
  final settings = ref.watch(settingsProvider);
  return AIService(
    endpoint: settings.aiEndpoint,
    apiKey: settings.aiApiKey,
  );
});

/// Speech service provider
final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

// ============ Settings Providers ============

/// User settings state notifier
class SettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    final repository = ref.watch(settingsRepositoryProvider);
    return repository.getSettings();
  }
  
  Future<void> updateCurrency(Currency currency) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.updateCurrency(currency);
    state = state.copyWith(currency: currency);
  }
  
  Future<void> updateVoiceLanguage(VoiceLanguage language) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.updateVoiceLanguage(language);
    state = state.copyWith(voiceLanguage: language);
  }
  
  Future<void> updateThemeMode(dynamic themeMode) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.updateThemeMode(themeMode);
    state = state.copyWith(themeMode: themeMode);
  }
  
  Future<void> updateAIConfig({String? endpoint, String? apiKey}) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.updateAIConfig(endpoint: endpoint, apiKey: apiKey);
    state = state.copyWith(aiEndpoint: endpoint, aiApiKey: apiKey);
  }
  
  Future<void> resetToDefaults() async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.resetToDefaults();
    state = UserSettings.defaults;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, UserSettings>(() {
  return SettingsNotifier();
});

/// Currency provider
final currencyProvider = Provider<Currency>((ref) {
  return ref.watch(settingsProvider).currency;
});

/// Voice language provider
final voiceLanguageProvider = Provider<VoiceLanguage>((ref) {
  return ref.watch(settingsProvider).voiceLanguage;
});

// ============ Transactions Providers ============

/// Transactions state notifier
class TransactionsNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getAllTransactions();
  }
  
  void refresh() {
    final repository = ref.read(transactionRepositoryProvider);
    state = repository.getAllTransactions();
  }
  
  Future<bool> add(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.addTransaction(transaction);
    if (result) refresh();
    return result;
  }
  
  Future<bool> addMultiple(List<Transaction> transactions) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.addTransactions(transactions);
    if (result) refresh();
    return result;
  }
  
  Future<bool> update(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.updateTransaction(transaction);
    if (result) refresh();
    return result;
  }
  
  Future<bool> delete(String id) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.deleteTransaction(id);
    if (result) refresh();
    return result;
  }
  
  Future<bool> deleteMultiple(List<String> ids) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.deleteTransactions(ids);
    if (result) refresh();
    return result;
  }
  
  Future<bool> clearAll() async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.clearAll();
    if (result) state = [];
    return result;
  }
}

final transactionsProvider = NotifierProvider<TransactionsNotifier, List<Transaction>>(() {
  return TransactionsNotifier();
});

// ============ Pending Transactions ============

/// Pending transactions state notifier (for voice input staging)
class PendingTransactionsNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() => [];
  
  void add(Transaction transaction) {
    state = [...state, transaction.copyWith(isPending: true)];
  }
  
  void addMultiple(List<Transaction> transactions) {
    state = [
      ...state, 
      ...transactions.map((t) => t.copyWith(isPending: true))
    ];
  }
  
  void update(String id, Transaction updated) {
    state = state.map((t) => t.id == id ? updated.copyWith(isPending: true) : t).toList();
  }
  
  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }
  
  void clear() {
    state = [];
  }
  
  Transaction? getById(String id) {
    return state.where((t) => t.id == id).firstOrNull;
  }
}

final pendingTransactionsProvider = NotifierProvider<PendingTransactionsNotifier, List<Transaction>>(() {
  return PendingTransactionsNotifier();
});

// ============ Computed Providers ============

/// Total income provider
final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Total expenses provider
final totalExpensesProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Balance provider
final balanceProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final expenses = ref.watch(totalExpensesProvider);
  return income - expenses;
});

/// Spending by category provider
final spendingByCategoryProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final expenses = transactions.where((t) => t.type == TransactionType.expense);
  
  final Map<String, double> result = {};
  for (final t in expenses) {
    result[t.category] = (result[t.category] ?? 0) + t.amount;
  }
  return result;
});

/// Recent transactions provider (last 5)
final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions.take(5).toList();
});

/// Categories provider
final categoriesProvider = Provider<List<Category>>((ref) {
  return Categories.all;
});

// ============ Voice Input Provider ============

/// Voice input state
class VoiceInputState {
  final bool isListening;
  final bool isProcessing;
  final String transcription;
  final String? error;
  final double soundLevel;
  
  const VoiceInputState({
    this.isListening = false,
    this.isProcessing = false,
    this.transcription = '',
    this.error,
    this.soundLevel = 0.0,
  });
  
  VoiceInputState copyWith({
    bool? isListening,
    bool? isProcessing,
    String? transcription,
    String? error,
    double? soundLevel,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      transcription: transcription ?? this.transcription,
      error: error,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

/// Voice input state notifier
class VoiceInputNotifier extends Notifier<VoiceInputState> {
  @override
  VoiceInputState build() => const VoiceInputState();
  
  Future<void> initialize() async {
    final speechService = ref.read(speechServiceProvider);
    await speechService.initialize();
  }
  
  Future<void> startListening({bool autoProcess = true}) async {
    final speechService = ref.read(speechServiceProvider);
    final settings = ref.read(settingsProvider);
    
    state = state.copyWith(
      isListening: true,
      transcription: '',
      error: null,
    );
    
    await speechService.startListening(
      language: settings.voiceLanguage,
      onResult: (result) {
        state = state.copyWith(transcription: result.recognizedWords);
        if (autoProcess && result.finalResult && result.recognizedWords.isNotEmpty) {
          _processTranscription(result.recognizedWords);
        }
      },
      onSoundLevel: (level) {
        state = state.copyWith(soundLevel: level);
      },
    );
  }
  
  Future<void> stopListening({bool autoProcess = true}) async {
    final speechService = ref.read(speechServiceProvider);
    await speechService.stopListening();
    state = state.copyWith(isListening: false);
    
    // Process transcription if any
    if (autoProcess && state.transcription.isNotEmpty) {
      await _processTranscription(state.transcription);
    }
  }
  
  Future<void> processText(String text) async {
    state = state.copyWith(transcription: text);
    await _processTranscription(text);
  }
  
  Future<void> _processTranscription(String text) async {
    state = state.copyWith(
      isListening: false,
      isProcessing: true,
    );
    
    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.parseTransaction(text);
      
      if (result.success && result.transactions.isNotEmpty) {
        ref.read(pendingTransactionsProvider.notifier).addMultiple(result.transactions);
        state = state.copyWith(
          isProcessing: false,
          transcription: '',
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: result.error ?? 'Could not parse transaction',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Error processing: $e',
      );
    }
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  void clearTranscription() {
    state = state.copyWith(transcription: '');
  }

  Future<Transaction?> processUpdate(String text, Transaction current) async {
    state = state.copyWith(
      isListening: false,
      isProcessing: true,
      transcription: text,
    );
    
    try {
      final aiService = ref.read(aiServiceProvider);
      // Ensure we have valid text
      if (text.trim().isEmpty) {
        state = state.copyWith(isProcessing: false);
        return null;
      }

      final updated = await aiService.modifyTransaction(current, text);
      
      state = state.copyWith(isProcessing: false);
      
      if (updated != null) {
        return updated;
      } else {
        state = state.copyWith(error: 'Could not understand update instruction');
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Error updating: $e',
      );
      return null;
    }
  }
}

final voiceInputProvider = NotifierProvider<VoiceInputNotifier, VoiceInputState>(() {
  return VoiceInputNotifier();
});

