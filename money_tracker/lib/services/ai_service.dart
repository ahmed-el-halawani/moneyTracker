import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

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

/// AI service for parsing natural language to transactions using Groq (Llama-3.3)
class AIService {
  final String endpoint;
  final String apiKey;

  // Groq Configuration
  static const String defaultEndpoint = 'https://api.groq.com/openai/v1';
  static const String defaultModel = 'llama-3.3-70b-versatile';
  static const String defaultApiKey =
      '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';

  AIService({String? endpoint, String? apiKey})
    : endpoint = endpoint ?? defaultEndpoint,
      apiKey = apiKey ?? defaultApiKey;

  /// Parse natural language text into transaction(s)
  Future<AIParseResult> parseTransaction(
    String text, {
    String targetLanguage = 'English',
  }) async {
    if (text.trim().isEmpty) {
      return AIParseResult.failure('Input text is empty');
    }

    final prompt = _buildParsePrompt(text, targetLanguage);

    try {
      final response = await _callGroq(prompt);
      if (response == null || response.isEmpty) {
        return AIParseResult.failure('Failed to get AI response from Groq');
      }

      final transactions = _parseResponse(response);
      if (transactions.isEmpty) {
        return AIParseResult.failure('Could not parse transaction from text');
      }

      return AIParseResult.success(transactions);
    } catch (e) {
      print('AI parsing error: $e');
      return AIParseResult.failure('AI parsing error: $e');
    }
  }

  /// Modify an existing transaction based on instruction
  Future<Transaction?> modifyTransaction(
    Transaction current,
    String instruction, {
    List<String> history = const [],
  }) async {
    if (instruction.trim().isEmpty) return current;

    final prompt = _buildModifyPrompt(current, instruction, history);

    try {
      final response = await _callGroq(prompt);
      if (response == null) {
        return _mockModifyTransaction(current, instruction);
      }

      final parsed = _parseSingleTransaction(response);
      return parsed?.copyWith(id: current.id, createdAt: current.createdAt);
    } catch (e) {
      return _mockModifyTransaction(current, instruction);
    }
  }

  // --- Mock Fallback ---

  Transaction _mockModifyTransaction(Transaction current, String instruction) {
    final lower = instruction.toLowerCase();
    Transaction updated = current;

    // Parse amount changes
    final amountMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(dollar|sar|riyal|ريال)?',
    ).firstMatch(lower);
    if (amountMatch != null &&
        (lower.contains('amount') ||
            lower.contains('مبلغ') ||
            lower.contains('to ') ||
            lower.contains('set'))) {
      final newAmount =
          double.tryParse(amountMatch.group(1)!) ?? current.amount;
      updated = updated.copyWith(amount: newAmount);
    }

    // Parse title changes
    final titleRegex = RegExp(
      r'(?:title|name|rename)\s+to\s+(.+)',
      caseSensitive: false,
    );
    final titleMatch = titleRegex.firstMatch(instruction);
    if (titleMatch != null) {
      updated = updated.copyWith(title: titleMatch.group(1)!.trim());
    }

    // Parse category changes
    final categories = [
      'food',
      'transport',
      'shopping',
      'entertainment',
      'bills',
      'salary',
      'healthcare',
      'education',
      'investment',
      'gifts',
      'other',
    ];
    for (final cat in categories) {
      if (lower.contains(cat)) {
        updated = updated.copyWith(
          category: cat[0].toUpperCase() + cat.substring(1),
        );
        break;
      }
    }

    // Parse type changes
    if (lower.contains('income') || lower.contains('دخل')) {
      updated = updated.copyWith(type: TransactionType.income);
    } else if (lower.contains('expense') || lower.contains('مصروف')) {
      updated = updated.copyWith(type: TransactionType.expense);
    }

    return updated;
  }

  String _buildParsePrompt(String text, String targetLanguage) {
    return '''You are a sophisticated financial assistant (Llama 3.3).
    
Task: Parse the following text into a structured JSON array of transaction objects.
Input Language: The text uses Arabic or English.

CRITICAL RULES:
1. Return ONLY valid JSON. No markdown, no explanations.
2. If the user mentions multiple distinct expenses (e.g., "50 for food and 20 for taxi"), you MUST return multiple objects in the array.
3. TRANSACTION TYPES:
   - "income": Salary, profit, or general money increase (not from a specific person).
   - "expense": Checking, food, shopping, or general money decrease (not to a specific person).
   - "transfer_out": Money LEAVING your possession to a specific person.
     * Keywords: "Sent to", "Gave to", "Transfer to", "I gave".
     * Example: "I gave Mohamed 50" -> type: "transfer_out", beneficiary: "Mohamed".
   - "transfer_in": Money ENTERING your possession from a specific person.
     * Keywords: "Received from", "Gave me", "Transfer from", "He gave me".
     * Example: "Mohamed gave me 50" -> type: "transfer_in", beneficiary: "Mohamed".
4. Detect "Social Splits" (e.g., "I paid 300 for lunch with Khaled"):
   - You MUST identify the distinct participants.
   - If user says "I paid...", include the user as a participant (is_current_user: true).
   - If the user says "Split 300... I pay 100", use the specific amounts.
   - If no amounts specified, assume user wants the app to calculate equal split (you can return 0 or calculate it yourself).
   - "note" field should capture context like "neighbor" or "lived next door" to help identifying the user.
5. LANGUAGE REQUIREMENT: Translate 'title' and 'description' to $targetLanguage.

Schema for each object:
{
  "title": "string (Short header in $targetLanguage)",
  "description": "string (Details in $targetLanguage)",
  "amount": number,
  "type": "income" | "expense" | "transfer_out" | "transfer_in",
  "category": "Food" | "Transport" | "Shopping" | "Entertainment" | "Bills" | "Salary" | "Healthcare" | "Education" | "Investment" | "Gifts" | "Other" | "string",
  "is_increase": boolean (true if money is ENTERING my account, false if money is LEAVING),
  "emoji": "string" (A single relevant emoji, e.g. 🍔, 💰, 🚕),
  "split_members": [
    {
      "name": "string",
      "amount": number,
      "is_current_user": boolean,
      "is_payer": boolean (true if this person PAID the bill. Default false. Only ONE person can be payer),
      "note": "string (optional)"
    }
  ] (Optional, only if split),
  "beneficiary": "string" (Optional, Name of the person for transfers)
}

Examples:
Input: "I spent 50 on food"
Output: [{"title":"Food","amount":50,"type":"expense","is_increase":false,"emoji":"🍔"...}]

Input: "I gave Mohamed 50"
Output: [{"title":"Transfer to Mohamed","amount":50,"type":"transfer_out","is_increase":false,"emoji":"↗️","beneficiary":"Mohamed"...}]

Input: "Mohamed gave me 50"
Output: [{"title":"Received from Mohamed","amount":50,"type":"transfer_in","is_increase":true,"emoji":"↙️","beneficiary":"Mohamed"...}]

Input: "I paid 300 for lunch with Ali and Mohamed next door"
Output: [{
  "title": "Lunch Split",
  "amount": 300,
  "type": "expense",
  "is_increase": false,
  "emoji": "🍕",
  "split_members": [
    {"name": "Me", "amount": 100, "is_current_user": true, "is_payer": true},
    {"name": "Ali", "amount": 100, "is_current_user": false, "is_payer": false},
    {"name": "Mohamed", "amount": 100, "is_current_user": false, "is_payer": false, "note": "next door"}
  ]
}]

Input: "Ali paid 200 for dinner with me"
Output: [{
  "title": "Dinner Split",
  "amount": 200,
  "type": "expense",
  "is_increase": false,
  "emoji": "🍽️",
  "split_members": [
     {"name": "Me", "amount": 100, "is_current_user": true, "is_payer": false},
     {"name": "Ali", "amount": 100, "is_current_user": false, "is_payer": true}
  ]
}]

Text to Parse: "$text"''';
  }

  String _buildModifyPrompt(
    Transaction current,
    String instruction,
    List<String> history,
  ) {
    final historyBlock = history.isNotEmpty
        ? '\nPrevious Voice Commands:\n${history.map((h) => "- $h").join("\n")}\n'
        : '';

    return '''You are a financial assistant. Update the transaction JSON based on the user's instruction.

Current JSON:
${json.encode(current.toJson())}

$historyBlock
Instruction: "$instruction"

CRITICAL RULES:
1. Return the COMPLETE updated JSON object.
2. PRESERVE all existing fields (id, createdAt, split_members, etc.) unless explicitly asked to change them.
3. If modifying a split participant (e.g. "Make Ali pay 50"), find "Ali" in "split_members", update their amount, and RECALCULATE other shares if needed to match total.
4. DO NOT DELETE any existing split members unless asked to "remove" them.
5. PRESERVE hidden fields like "email", "phone", "note" inside split_members.

Return ONLY the updated JSON object. No markdown.''';
  }

  // --- OpenAI / Groq API Call ---

  /// Transcribe audio file using Groq Whisper
  Future<String?> transcribeAudio(String filePath) async {
    try {
      final url = Uri.parse('$endpoint/audio/transcriptions');
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..fields['model'] =
            'whisper-large-v3' // or 'distil-whisper-large-v3-en' for English only
        ..fields['language'] =
            'ar' // Hint for Arabic, optional but helpful
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        print('Groq Whisper API error: ${response.statusCode} - $responseBody');
        return null;
      }

      final data = json.decode(responseBody);
      return data['text'] as String?;
    } catch (e) {
      print('Groq Whisper exception: $e');
      return null;
    }
  }

  Future<String?> _callGroq(String prompt) async {
    try {
      final url = Uri.parse('$endpoint/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful financial AI helper that answers exclusively in JSON.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.1, // Low temp for consistent JSON
        }),
      );

      if (response.statusCode != 200) {
        print('Groq API error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final content = data['choices']?[0]?['message']?['content'] as String?;
      return content;
    } catch (e) {
      print('Groq API exception: $e');
      return null;
    }
  }

  // --- Response Parsing ---

  List<Transaction> _parseResponse(String response) {
    try {
      String cleaned = response.trim();
      // Remove markdown code blocks
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'```\w*\n?'), '');
      }
      cleaned = cleaned.trim();
      // Extract array part
      final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
      if (arrayMatch != null) cleaned = arrayMatch.group(0)!;

      // Try array parsing
      if (cleaned.startsWith('[')) {
        final List<dynamic> list = json.decode(cleaned);
        return list
            .map(
              (item) =>
                  Transaction.fromAIResponse(item as Map<String, dynamic>),
            )
            .toList();
      }
      // Try single object parsing
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
      if (cleaned.startsWith('```'))
        cleaned = cleaned.replaceAll(RegExp(r'```\w*\n?'), '');
      cleaned = cleaned.trim();

      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (objectMatch != null) cleaned = objectMatch.group(0)!;

      final Map<String, dynamic> data = json.decode(cleaned);
      return Transaction.fromAIResponse(data);
    } catch (e) {
      return null;
    }
  }

  // No mock fallback during active AI use, unless call fails
}
