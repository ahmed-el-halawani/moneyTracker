import '../models/contact.dart';
import '../services/storage_service.dart';

class ContactRepository {
  final StorageService _storage;

  ContactRepository(this._storage);

  List<Contact> getAll() {
    final data = _storage.getContacts();
    return data.map((json) => Contact.fromJson(json)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<bool> add(Contact contact) async {
    final all = _storage.getContacts();
    all.add(contact.toJson());
    return await _storage.saveContacts(all);
  }

  Future<bool> update(Contact contact) async {
    final all = _storage.getContacts();
    final index = all.indexWhere((c) => c['id'] == contact.id);
    if (index == -1) return false;

    all[index] = contact.toJson();
    return await _storage.saveContacts(all);
  }

  /// Find a contact by name (case insensitive)
  Contact? findByName(String name) {
    try {
      return getAll()
          .where((c) => c.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
    } catch (_) {
      return null;
    }
  }

  /// Search contacts by name (fuzzy match)
  List<Contact> search(String query) {
    final lower = query.toLowerCase();
    return getAll().where((c) {
      return c.name.toLowerCase().contains(lower);
    }).toList();
  }

  Future<bool> delete(String id) async {
    final all = _storage.getContacts();
    all.removeWhere((c) => c['id'] == id);
    return await _storage.saveContacts(all);
  }
}
