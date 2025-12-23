import 'package:flutter/material.dart';

/// Supported voice languages
enum VoiceLanguage {
  englishUS('en-US', 'English (US)'),
  arabicSA('ar-SA', 'Arabic (Saudi)'),
  arabicEG('ar-EG', 'Arabic (Egypt)');


  final String code;
  final String displayName;
  
  const VoiceLanguage(this.code, this.displayName);


  static VoiceLanguage fromCode(String code) {
    return VoiceLanguage.values.firstWhere(
      (v) => v.code == code,

      orElse: () => VoiceLanguage.englishUS,
    );
  }
}

/// Supported currencies
enum Currency {
  sar('SAR', 'ر.س', 'Saudi Riyal'),
  usd('USD', '\$', 'US Dollar'),
  eur('EUR', '€', 'Euro'),
  egp('EGP', 'ج.م', 'Egyptian Pound'),
  aed('AED', 'د.إ', 'UAE Dirham');
  
  final String code;
  final String symbol;
  final String displayName;
  
  const Currency(this.code, this.symbol, this.displayName);
  
  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency.sar,
    );
  }
}

/// User settings model
class UserSettings {
  final Currency currency;
  final VoiceLanguage voiceLanguage;
  final ThemeMode themeMode;
  final String? aiEndpoint;
  final String? aiApiKey;
  
  const UserSettings({
    this.currency = Currency.sar,
    this.voiceLanguage = VoiceLanguage.englishUS,
    this.themeMode = ThemeMode.system,
    this.aiEndpoint,
    this.aiApiKey,
  });
  
  UserSettings copyWith({
    Currency? currency,
    VoiceLanguage? voiceLanguage,
    ThemeMode? themeMode,
    String? aiEndpoint,
    String? aiApiKey,
  }) {
    return UserSettings(
      currency: currency ?? this.currency,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      themeMode: themeMode ?? this.themeMode,
      aiEndpoint: aiEndpoint ?? this.aiEndpoint,
      aiApiKey: aiApiKey ?? this.aiApiKey,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'currency': currency.code,
      'voiceLanguage': voiceLanguage.code,
      'themeMode': themeMode.name,
      'aiEndpoint': aiEndpoint,
      'aiApiKey': aiApiKey,
    };
  }
  
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      currency: Currency.fromCode(json['currency'] as String? ?? 'SAR'),
      voiceLanguage: VoiceLanguage.fromCode(json['voiceLanguage'] as String? ?? 'en-US'),
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == (json['themeMode'] as String? ?? 'system'),
        orElse: () => ThemeMode.system,
      ),
      aiEndpoint: json['aiEndpoint'] as String?,
      aiApiKey: json['aiApiKey'] as String?,
    );
  }
  
  /// Format amount with currency symbol
  String formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(2);
    return '${currency.symbol} $formatted';
  }
  
  static const UserSettings defaults = UserSettings();
}
