import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/user_settings.dart';

void main() {
  group('UserSettings Model', () {
    test('should have correct defaults', () {
      const settings = UserSettings();
      
      expect(settings.currency, Currency.sar);
      expect(settings.voiceLanguage, VoiceLanguage.englishUS);
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.aiEndpoint, isNull);
      expect(settings.aiApiKey, isNull);
    });
    
    test('should create a copy with updated fields', () {
      const original = UserSettings();
      
      final updated = original.copyWith(
        currency: Currency.usd,
        voiceLanguage: VoiceLanguage.arabicSA,
        themeMode: ThemeMode.dark,
      );
      
      expect(updated.currency, Currency.usd);
      expect(updated.voiceLanguage, VoiceLanguage.arabicSA);
      expect(updated.themeMode, ThemeMode.dark);
    });
    
    test('should convert to JSON and back', () {
      final original = UserSettings(
        currency: Currency.eur,
        voiceLanguage: VoiceLanguage.arabicEG,
        themeMode: ThemeMode.light,
        aiEndpoint: 'http://localhost:11434',
        aiApiKey: 'test-key',
      );
      
      final json = original.toJson();
      final restored = UserSettings.fromJson(json);
      
      expect(restored.currency, original.currency);
      expect(restored.voiceLanguage, original.voiceLanguage);
      expect(restored.themeMode, original.themeMode);
      expect(restored.aiEndpoint, original.aiEndpoint);
      expect(restored.aiApiKey, original.aiApiKey);
    });
    
    test('should format amount with currency symbol', () {
      const sarSettings = UserSettings(currency: Currency.sar);
      expect(sarSettings.formatAmount(100.50), 'ر.س 100.50');
      
      const usdSettings = UserSettings(currency: Currency.usd);
      expect(usdSettings.formatAmount(100.50), '\$ 100.50');
      
      const eurSettings = UserSettings(currency: Currency.eur);
      expect(eurSettings.formatAmount(100.50), '€ 100.50');
    });
  });
  
  group('Currency Enum', () {
    test('should have correct properties', () {
      expect(Currency.sar.code, 'SAR');
      expect(Currency.sar.symbol, 'ر.س');
      expect(Currency.sar.displayName, 'Saudi Riyal');
      
      expect(Currency.usd.code, 'USD');
      expect(Currency.usd.symbol, '\$');
      expect(Currency.usd.displayName, 'US Dollar');
      
      expect(Currency.eur.code, 'EUR');
      expect(Currency.eur.symbol, '€');
      expect(Currency.eur.displayName, 'Euro');
    });
    
    test('should parse from code', () {
      expect(Currency.fromCode('SAR'), Currency.sar);
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode('EUR'), Currency.eur);
      expect(Currency.fromCode('EGP'), Currency.egp);
      expect(Currency.fromCode('AED'), Currency.aed);
      expect(Currency.fromCode('INVALID'), Currency.sar); // Default
    });
  });
  
  group('VoiceLanguage Enum', () {
    test('should have correct properties', () {
      expect(VoiceLanguage.englishUS.code, 'en-US');
      expect(VoiceLanguage.englishUS.displayName, 'English (US)');
      
      expect(VoiceLanguage.arabicSA.code, 'ar-SA');
      expect(VoiceLanguage.arabicSA.displayName, 'Arabic (Saudi)');
      
      expect(VoiceLanguage.arabicEG.code, 'ar-EG');
      expect(VoiceLanguage.arabicEG.displayName, 'Arabic (Egypt)');
    });
    
    test('should parse from code', () {
      expect(VoiceLanguage.fromCode('en-US'), VoiceLanguage.englishUS);
      expect(VoiceLanguage.fromCode('ar-SA'), VoiceLanguage.arabicSA);
      expect(VoiceLanguage.fromCode('ar-EG'), VoiceLanguage.arabicEG);
      expect(VoiceLanguage.fromCode('INVALID'), VoiceLanguage.englishUS); // Default
    });
  });
}
