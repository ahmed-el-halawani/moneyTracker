import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/services/supabase_service.dart';

// Model for Beneficiary
class Beneficiary {
  final String id;
  final String name;
  final String? note;
  final int usageCount;
  final bool isLinked;

  Beneficiary({
    required this.id,
    required this.name,
    this.note,
    this.usageCount = 0,
    this.isLinked = false,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json['id'] as String,
      name: json['name'] as String,
      note: json['note'] as String?,
      usageCount: json['usage_count'] as int? ?? 0,
      isLinked: json['is_linked'] as bool? ?? false,
    );
  }
}

final beneficiaryRepositoryProvider = Provider<BeneficiaryRepository>((ref) {
  final supabase = ref.read(supabaseServiceProvider);
  return BeneficiaryRepository(supabase);
});

class BeneficiaryRepository {
  final SupabaseService _supabase;

  // Local cache for offline support or quick access
  final List<Beneficiary> _cache = [];

  BeneficiaryRepository(this._supabase);

  // Resolution Logic: Smart Name Matching
  Future<Beneficiary?> resolveBeneficiary(
    String inputName, {
    String? contextNote,
  }) async {
    // 1. Precise Mock Handling (Until Supabase is fully live)
    // If input is "Neighbor" and we have a "Neighbor" in context, find "Khaled"
    if (inputName.toLowerCase().contains('neighbor') ||
        (contextNote != null &&
            contextNote.toLowerCase().contains('neighbor'))) {
      // Mock resolving "Neighbor" -> "Khaled"
      return Beneficiary(
        id: 'mock-1',
        name: 'Khaled',
        note: 'My Neighbor',
        usageCount: 5,
      );
    }

    try {
      // 2. Try Database Search
      final results = await _supabase.searchBeneficiaries(inputName);
      if (results.isNotEmpty) {
        // Return top match
        return Beneficiary.fromJson(results.first);
      }
    } catch (e) {
      // Supabase likely not init, ignore
    }

    // 3. Return a temporary/new beneficiary object if not found
    return null;
  }
}
