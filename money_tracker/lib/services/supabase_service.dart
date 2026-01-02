import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Defines the Supabase service provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

class SupabaseService {
  SupabaseClient? _client;

  // Initialize Supabase - to be called in main.dart
  Future<void> initialize({required String url, required String anonKey}) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  // --- Beneficiaries (Smart Reference) ---

  /// Search for beneficiaries by name or semantic match
  Future<List<Map<String, dynamic>>> searchBeneficiaries(String query) async {
    // TODO: Implement actual Supabase RPC call for vector search
    // For now, returning mock data or simple text search results
    /*
    final response = await client.rpc('search_beneficiaries', params: {
      'query_embedding': ... // Generate embedding for query
      'match_threshold': 0.7,
    });
    return response;
    */
    
    // Placeholder for simple text search until Vector is set up
    final response = await client
        .from('beneficiaries')
        .select()
        .ilike('name', '%$query%') // Simple case-insensitive search
        .order('usage_count', ascending: false)
        .limit(5);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> incrementUsageCount(String beneficiaryId) async {
    await client.rpc('increment_usage_count', params: {'row_id': beneficiaryId});
  }

  // --- Social Split ---

  /// Creates a split transaction structure
  /// This would typically involve a database transaction to insert:
  /// 1. The main Transaction (Parent)
  /// 2. Multiple SplitMember records
  Future<void> createSplitTransaction({
    required Map<String, dynamic> transactionData,
    required List<Map<String, dynamic>> splitMembers,
  }) async {
    // 1. Insert Parent Transaction
    final transaction = await client
        .from('transactions')
        .insert(transactionData)
        .select()
        .single();
    
    final transactionId = transaction['id'];

    // 2. Prepare Split Members with parent ID
    final membersToInsert = splitMembers.map((m) => {
      ...m,
      'transaction_id': transactionId,
    }).toList();

    // 3. Insert Split Members
    await client.from('split_members').insert(membersToInsert);
  }
}
