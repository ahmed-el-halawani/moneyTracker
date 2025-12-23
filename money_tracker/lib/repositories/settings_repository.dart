import '../models/user_settings.dart';
import '../services/storage_service.dart';

/// Repository for user settings
class SettingsRepository {
  final StorageService _storage;
  
  SettingsRepository(this._storage);
  
  /// Get current settings
  UserSettings getSettings() {
    final data = _storage.getSettings();
    if (data == null) return UserSettings.defaults;
    return UserSettings.fromJson(data);
  }
  
  /// Save settings
  Future<bool> saveSettings(UserSettings settings) async {
    return await _storage.saveSettings(settings.toJson());
  }
  
  /// Update currency
  Future<bool> updateCurrency(Currency currency) async {
    final current = getSettings();
    return await saveSettings(current.copyWith(currency: currency));
  }
  
  /// Update voice language
  Future<bool> updateVoiceLanguage(VoiceLanguage language) async {
    final current = getSettings();
    return await saveSettings(current.copyWith(voiceLanguage: language));
  }
  
  /// Update theme mode
  Future<bool> updateThemeMode(dynamic themeMode) async {
    final current = getSettings();
    return await saveSettings(current.copyWith(themeMode: themeMode));
  }
  
  /// Update AI configuration
  Future<bool> updateAIConfig({String? endpoint, String? apiKey}) async {
    final current = getSettings();
    return await saveSettings(current.copyWith(
      aiEndpoint: endpoint,
      aiApiKey: apiKey,
    ));
  }
  
  /// Reset to defaults
  Future<bool> resetToDefaults() async {
    return await saveSettings(UserSettings.defaults);
  }
}
