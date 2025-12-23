import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/user_settings.dart';
import '../models/transaction.dart';
import '../services/speech_service.dart';
import '../services/ai_service.dart';
import 'providers.dart';

/// Voice input state
class VoiceInputState {
  final bool isListening;
  final bool isProcessing;
  final bool isAvailable;
  final String transcription;
  final String? error;
  final double soundLevel;
  
  const VoiceInputState({
    this.isListening = false,
    this.isProcessing = false,
    this.isAvailable = false,
    this.transcription = '',
    this.error,
    this.soundLevel = 0.0,
  });
  
  VoiceInputState copyWith({
    bool? isListening,
    bool? isProcessing,
    bool? isAvailable,
    String? transcription,
    String? error,
    double? soundLevel,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      isAvailable: isAvailable ?? this.isAvailable,
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
  
  /// Initialize speech recognition
  Future<void> initialize() async {
    final speechService = ref.read(speechServiceProvider);
    final available = await speechService.initialize();
    state = state.copyWith(isAvailable: available);
  }
  
  /// Start listening for voice input
  Future<void> startListening() async {
    if (!state.isAvailable) {
      await initialize();
      if (!state.isAvailable) {
        state = state.copyWith(error: 'Speech recognition not available');
        return;
      }
    }
    
    final speechService = ref.read(speechServiceProvider);
    final language = ref.read(voiceLanguageProvider);
    
    state = state.copyWith(
      isListening: true,
      transcription: '',
      error: null,
    );
    
    await speechService.startListening(
      onResult: _onSpeechResult,
      onSoundLevel: _onSoundLevel,
      language: language,
    );
  }
  
  void _onSpeechResult(SpeechRecognitionResult result) {
    state = state.copyWith(transcription: result.recognizedWords);
    
    if (result.finalResult) {
      _processTranscription(result.recognizedWords);
    }
  }
  
  void _onSoundLevel(double level) {
    state = state.copyWith(soundLevel: level);
  }
  
  /// Process the transcribed text
  Future<void> _processTranscription(String text) async {
    if (text.trim().isEmpty) {
      state = state.copyWith(isListening: false, isProcessing: false);
      return;
    }
    
    state = state.copyWith(isListening: false, isProcessing: true);
    
    final aiService = ref.read(aiServiceProvider);
    final result = await aiService.parseTransaction(text);
    
    if (result.success && result.transactions.isNotEmpty) {
      // Add to pending transactions
      ref.read(pendingTransactionsProvider.notifier).addMultiple(result.transactions);
      state = state.copyWith(isProcessing: false, transcription: '');
    } else {
      state = state.copyWith(
        isProcessing: false,
        error: result.error ?? 'Could not parse transaction',
      );
    }
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    final speechService = ref.read(speechServiceProvider);
    await speechService.stopListening();
    state = state.copyWith(isListening: false);
  }
  
  /// Cancel listening
  Future<void> cancelListening() async {
    final speechService = ref.read(speechServiceProvider);
    await speechService.cancelListening();
    state = state.copyWith(
      isListening: false,
      transcription: '',
    );
  }
  
  /// Process manual text input
  Future<void> processText(String text) async {
    if (text.trim().isEmpty) return;
    
    state = state.copyWith(isProcessing: true, error: null);
    
    final aiService = ref.read(aiServiceProvider);
    final result = await aiService.parseTransaction(text);
    
    if (result.success && result.transactions.isNotEmpty) {
      ref.read(pendingTransactionsProvider.notifier).addMultiple(result.transactions);
      state = state.copyWith(isProcessing: false);
    } else {
      state = state.copyWith(
        isProcessing: false,
        error: result.error ?? 'Could not parse transaction',
      );
    }
  }
  
  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Clear transcription
  void clearTranscription() {
    state = state.copyWith(transcription: '');
  }
}

/// Voice input provider
final voiceInputProvider = NotifierProvider<VoiceInputNotifier, VoiceInputState>(() {
  return VoiceInputNotifier();
});

/// Is listening provider
final isListeningProvider = Provider<bool>((ref) {
  return ref.watch(voiceInputProvider).isListening;
});

/// Transcription provider
final transcriptionProvider = Provider<String>((ref) {
  return ref.watch(voiceInputProvider).transcription;
});

/// Is processing provider
final isProcessingProvider = Provider<bool>((ref) {
  return ref.watch(voiceInputProvider).isProcessing;
});
