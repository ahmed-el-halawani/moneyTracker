import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/user_settings.dart';

/// Voice input state
class VoiceInputState {
  final bool isListening;
  final bool isAvailable;
  final String transcription;
  final String? error;
  final double soundLevel;
  
  const VoiceInputState({
    this.isListening = false,
    this.isAvailable = false,
    this.transcription = '',
    this.error,
    this.soundLevel = 0.0,
  });
  
  VoiceInputState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? transcription,
    String? error,
    double? soundLevel,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      transcription: transcription ?? this.transcription,
      error: error,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

/// Speech to text service
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  
  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          print('Speech error: ${error.errorMsg}');
        },
        onStatus: (status) {
          print('Speech status: $status');
        },
      );
      return _isInitialized;
    } catch (e) {
      print('Speech initialization error: $e');
      return false;
    }
  }
  
  /// Check if speech is available
  bool get isAvailable => _isInitialized && _speech.isAvailable;
  
  /// Check if currently listening
  bool get isListening => _speech.isListening;
  
  /// Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) await initialize();
    return _speech.locales();
  }
  
  /// Start listening for speech
  Future<void> startListening({
    required Function(SpeechRecognitionResult) onResult,
    required Function(double) onSoundLevel,
    VoiceLanguage language = VoiceLanguage.englishUS,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }
    
    await _speech.listen(
      onResult: onResult,
      onSoundLevelChange: onSoundLevel,
      localeId: language.code,
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 10),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    await _speech.stop();
  }
  
  /// Cancel listening
  Future<void> cancelListening() async {
    await _speech.cancel();
  }
  
  /// Check if a specific locale is available
  Future<bool> isLocaleAvailable(VoiceLanguage language) async {
    final locales = await getLocales();
    return locales.any((l) => l.localeId.startsWith(language.code.split('-').first));
  }
}
