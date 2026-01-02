import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service using SharedPreferences
class StorageService {
  static const String _transactionsKey = 'transactions';
  static const String _settingsKey = 'user_settings';
  static const String _contactsKey = 'contacts';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Get all saved transactions as JSON list
  List<Map<String, dynamic>> getTransactions() {
    final String? data = _prefs.getString(_transactionsKey);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Save transactions to local storage
  Future<bool> saveTransactions(List<Map<String, dynamic>> transactions) async {
    final String encoded = json.encode(transactions);
    return await _prefs.setString(_transactionsKey, encoded);
  }

  /// Get user settings as JSON
  Map<String, dynamic>? getSettings() {
    final String? data = _prefs.getString(_settingsKey);
    if (data == null || data.isEmpty) return null;

    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Save user settings
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    final String encoded = json.encode(settings);
    return await _prefs.setString(_settingsKey, encoded);
  }

  /// Get contacts as JSON list
  List<Map<String, dynamic>> getContacts() {
    final String? data = _prefs.getString(_contactsKey);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Save contacts to local storage
  Future<bool> saveContacts(List<Map<String, dynamic>> contacts) async {
    final String encoded = json.encode(contacts);
    return await _prefs.setString(_contactsKey, encoded);
  }

  /// Clear all data
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  /// Clear transactions only
  Future<bool> clearTransactions() async {
    return await _prefs.remove(_transactionsKey);
  }
}
