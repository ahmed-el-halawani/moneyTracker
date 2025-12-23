import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
//20 sar on food
/// Result of AI parsing
class AIParseResult {
  final List<Transaction> transactions;
  final String? error;
  final bool success;
  
  const AIParseResult({
    required this.transactions,
    this.error,
    required this.success,
  });
  
  factory AIParseResult.success(List<Transaction> transactions) {
    return AIParseResult(transactions: transactions, success: true);
  }
  
  factory AIParseResult.failure(String error) {
    return AIParseResult(transactions: [], error: error, success: false);
  }
}

/// AI service for parsing natural language to transactions
class AIService {
  final String endpoint;
  final String apiKey;
  
  // Default Ollama cloud endpoint
  static const String defaultEndpoint = 'https://ollama.com';
  static const String defaultModel = 'gpt-oss:120b-cloud';
  static const String defaultApiKey = '3560275d6e044a96b4abaf3a87d62e98.Q5pUTZouCUDpOEfcSLdaku3d';
  
  AIService({
    String? endpoint,
    String? apiKey,
  }) : endpoint = endpoint ?? defaultEndpoint,
       apiKey = apiKey ?? defaultApiKey;
  
  /// Parse natural language text into transaction(s)
  Future<AIParseResult> parseTransaction(String text) async {
    if (text.trim().isEmpty) {
      return AIParseResult.failure('Input text is empty');
    }
    
    final prompt = _buildParsePrompt(text);
    
    try {
      final response = await _callOllama(prompt);
      if (response == null || response.isEmpty) {
        // Fallback to mock when AI is unavailable
        final mockResponse = _getMockResponse(prompt);
        if (mockResponse != null) {
          final transactions = _parseResponse(mockResponse);
          if (transactions.isNotEmpty) {
            return AIParseResult.success(transactions);
          }
        }
        return AIParseResult.failure('Failed to get AI response');
      }
      
      final transactions = _parseResponse(response);
      if (transactions.isEmpty) {
        return AIParseResult.failure('Could not parse transaction from text');
      }
      
      return AIParseResult.success(transactions);
    } catch (e) {
      // Fallback to mock for demo/testing
      try {
        final mockResponse = _getMockResponse(prompt);
        if (mockResponse != null) {
          final transactions = _parseResponse(mockResponse);
          if (transactions.isNotEmpty) {
            return AIParseResult.success(transactions);
          }
        }
      } catch (_) {}
      return AIParseResult.failure('AI parsing error: $e');
    }
  }
  
  /// Modify an existing transaction based on instruction
  Future<Transaction?> modifyTransaction(
    Transaction current,
    String instruction,
  ) async {
    if (instruction.trim().isEmpty) return current;
    
    final prompt = _buildModifyPrompt(current, instruction);
    
    try {
      final response = await _callOllama(prompt);
      if (response == null) {
        // Fallback to local parsing when AI is unavailable
        return _mockModifyTransaction(current, instruction);
      }
      
      final parsed = _parseSingleTransaction(response);
      return parsed?.copyWith(id: current.id, createdAt: current.createdAt);
    } catch (e) {
      // Fallback to local parsing
      return _mockModifyTransaction(current, instruction);
    }
  }
  
  /// Mock modify transaction for demo/testing
  Transaction _mockModifyTransaction(Transaction current, String instruction) {
    final lower = instruction.toLowerCase();
    Transaction updated = current;
    
    // Parse amount changes: "change amount to 50", "make it 100", "set to 25"
    final amountMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(dollar|sar|riyal|ريال)?').firstMatch(lower);
    if (amountMatch != null && 
        (lower.contains('amount') || lower.contains('مبلغ') || 
         lower.contains('to ') || lower.contains('set'))) {
      final newAmount = double.tryParse(amountMatch.group(1)!) ?? current.amount;
      updated = updated.copyWith(amount: newAmount);
    }
    
    // Parse title changes: "change title to Lunch", "rename to Coffee"
    final titleRegex = RegExp(r'(?:title|name|rename)\s+to\s+(.+)', caseSensitive: false);
    final titleMatch = titleRegex.firstMatch(instruction);
    if (titleMatch != null) {
      updated = updated.copyWith(title: titleMatch.group(1)!.trim());
    }
    
    // Parse category changes: "change category to Food", "make it entertainment"
    final categories = ['food', 'transport', 'shopping', 'entertainment', 'bills', 'salary', 'healthcare', 'education', 'investment', 'gifts', 'other'];
    for (final cat in categories) {
      if (lower.contains(cat)) {
        updated = updated.copyWith(category: cat[0].toUpperCase() + cat.substring(1));
        break;
      }
    }
    
    // Parse type changes: "make it income", "change to expense"
    if (lower.contains('income') || lower.contains('دخل')) {
      updated = updated.copyWith(type: TransactionType.income);
    } else if (lower.contains('expense') || lower.contains('مصروف')) {
      updated = updated.copyWith(type: TransactionType.expense);
    }
    
    return updated;
  }
  
  String _buildParsePrompt(String text) {
    return '''You are a helpful financial assistant that outputs raw JSON.

Parse the following text into a JSON array of transaction objects.
The input text may be in English or Arabic. Treat it as a financial transaction.

Required fields for each object:
- title: string (short English header, e.g. "Grocery Run", "Salary Received"). IF INPUT IS ARABIC, TRANSLATE TITLE TO ENGLISH.
- description: string (detailed explanation). IF INPUT IS ARABIC, TRANSLATE DESCRIPTION TO ENGLISH.
- amount: number (positive value only)
- type: "income" or "expense"
- category: string (one of: Food, Transport, Shopping, Entertainment, Bills, Salary, Healthcare, Education, Investment, Gifts, Other)

Text: "$text"

Return ONLY a valid JSON array. Do not include markdown formatting, code blocks, or any other text.
Example output: [{"title":"Grocery Shopping","description":"Weekly groceries from supermarket","amount":50,"type":"expense","category":"Food"}]''';
  }
  
  String _buildModifyPrompt(Transaction current, String instruction) {
    return '''You are a helpful financial assistant that outputs raw JSON.

Update this transaction JSON object based on the user's instruction.
The instruction might be in English or Arabic. Understand the intent and update the JSON accordingly.

Current Object:
${json.encode(current.toJson())}

Instruction: "$instruction"

Return ONLY the updated JSON object. Do not include markdown formatting, code blocks, or any other text.''';
  }
  
  Future<String?> _callOllama(String prompt) async {

    try {
      final url = Uri.parse('$endpoint/api/generate');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': defaultModel,
          'prompt': prompt,
          'stream': false,
        }),
      );
      
      if (response.statusCode != 200) {
        print('Ollama API error: ${response.statusCode} - ${response.body}');
        return null;
      }
      
      final data = json.decode(response.body);
      return data['response'] as String?;
    } catch (e) {
      print('Ollama API error: $e');
      // Return null to trigger fallback
      return null;
    }

  }



  
  List<Transaction> _parseResponse(String response) {

    try {
      // Clean up the response
      String cleaned = response.trim();
      
      // Remove markdown code blocks if present
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'```\w*\n?'), '');
      }
      cleaned = cleaned.trim();
      
      // Try to find JSON array in the response
      final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
      if (arrayMatch != null) {
        cleaned = arrayMatch.group(0)!;
      }
      
      // Try parsing as array first
      if (cleaned.startsWith('[')) {
        final List<dynamic> list = json.decode(cleaned);
        return list
            .map((item) => Transaction.fromAIResponse(item as Map<String, dynamic>))
            .toList();
      }
      
      // Try parsing as single object
      if (cleaned.startsWith('{')) {
        final transaction = _parseSingleTransaction(cleaned);
        return transaction != null ? [transaction] : [];
      }
      
      return [];
    } catch (e) {
      print('Parse error: $e');
      return [];
    }
  }
  
  Transaction? _parseSingleTransaction(String response) {
    try {
      String cleaned = response.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'```\w*\n?'), '');
      }
      cleaned = cleaned.trim();
      
      // Try to find JSON object in the response
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (objectMatch != null) {
        cleaned = objectMatch.group(0)!;
      }
      
      final Map<String, dynamic> data = json.decode(cleaned);
      return Transaction.fromAIResponse(data);
    } catch (e) {
      return null;
    }
  }
  
  /// Mock response for demo/testing when AI is not available
  String? _getMockResponse(String prompt) {
    // Extract the actual text from the prompt (between Text: " and the next ")
    final textMatch = RegExp(r'Text:\s*"([^"]*)"').firstMatch(prompt);
    final text = textMatch?.group(1)?.toLowerCase() ?? prompt.toLowerCase();
    
    // Check for salary-related keywords first (income)
    if (text.contains('salary') || text.contains('راتب') || text.contains('income') || text.contains('received') || text.contains('bonus')) {
      return '[{"title":"Salary Received","description":"Monthly salary payment","amount":5000,"type":"income","category":"Salary"}]';
    }
    
    // Check for transport-related keywords
    if (text.contains('transport') || text.contains('uber') || text.contains('taxi') || text.contains('ride') || text.contains('car') || text.contains('bus')) {
      return '[{"title":"Transportation","description":"Ride service payment","amount":25,"type":"expense","category":"Transport"}]';
    }
    
    // Check for food/grocery-related keywords
    if (text.contains('grocery') || text.contains('groceries') || text.contains('food') || text.contains('بقالة') || text.contains('lunch') || text.contains('dinner')) {
      return '[{"title":"Grocery Shopping","description":"Food and groceries purchase","amount":50,"type":"expense","category":"Food"}]';
    }
    
    // Default mock response
    return '[{"title":"Transaction","description":"Parsed transaction","amount":100,"type":"expense","category":"Other"}]';
  }
}
