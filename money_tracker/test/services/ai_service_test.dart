import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/services/ai_service.dart';
import 'package:money_tracker/models/transaction.dart';

void main() {
  group('AIService', () {
    late AIService aiService;
    
    setUp(() {
      aiService = AIService();
    });
    
    test('should return failure for empty text', () async {
      final result = await aiService.parseTransaction('');
      
      expect(result.success, false);
      expect(result.error, 'Input text is empty');
      expect(result.transactions, isEmpty);
    });
    
    test('should return failure for whitespace-only text', () async {
      final result = await aiService.parseTransaction('   ');
      
      expect(result.success, false);
      expect(result.error, 'Input text is empty');
    });
    
    test('should parse grocery-related text using mock', () async {
      // The AI service falls back to mock responses when no AI is available
      final result = await aiService.parseTransaction('Spent 50 on groceries');
      
      expect(result.success, true);
      expect(result.transactions, isNotEmpty);
      
      final transaction = result.transactions.first;
      expect(transaction.category, 'Food');
      expect(transaction.type, TransactionType.expense);
      expect(transaction.isPending, true);
    });
    
    test('should parse salary-related text using mock', () async {
      // Use prompt that matches the mock keywords: 'salary' or 'راتب'
      final result = await aiService.parseTransaction('salary received 5000');
      
      expect(result.success, true);
      expect(result.transactions, isNotEmpty);
      
      final transaction = result.transactions.first;
      expect(transaction.category, 'Salary');
      expect(transaction.type, TransactionType.income);
    });
    
    test('should parse transport-related text using mock', () async {
      // Use prompt that matches the mock keywords: 'transport', 'uber', or 'taxi'
      final result = await aiService.parseTransaction('uber ride cost 25');
      
      expect(result.success, true);
      expect(result.transactions, isNotEmpty);
      
      final transaction = result.transactions.first;
      expect(transaction.category, 'Transport');
      expect(transaction.type, TransactionType.expense);
    });
    
    test('should handle unrecognized text gracefully', () async {
      final result = await aiService.parseTransaction('random text here');
      
      // Either successfully parses (with real AI or mock) or gracefully fails
      // Real AI may categorize ambiguous text differently than mock
      if (result.success) {
        expect(result.transactions, isNotEmpty);
        // AI might assign any category to ambiguous text
        expect(result.transactions.first.category, isNotNull);
      } else {
        // Also acceptable - AI couldn't parse ambiguous text
        expect(result.error, isNotNull);
      }
    });
  });
  
  group('AIParseResult', () {
    test('should create success result', () {
      final transactions = [
        Transaction(
          title: 'Test',
          description: '',
          amount: 100,
          type: TransactionType.expense,
          category: 'Other',
        ),
      ];
      
      final result = AIParseResult.success(transactions);
      
      expect(result.success, true);
      expect(result.error, isNull);
      expect(result.transactions, transactions);
    });
    
    test('should create failure result', () {
      final result = AIParseResult.failure('Test error');
      
      expect(result.success, false);
      expect(result.error, 'Test error');
      expect(result.transactions, isEmpty);
    });
  });
  
  group('Transaction Modification', () {
    late AIService aiService;
    
    setUp(() {
      aiService = AIService();
    });
    
    test('should return original transaction for empty instruction', () async {
      final original = Transaction(
        title: 'Original',
        description: 'Test',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      final result = await aiService.modifyTransaction(original, '');
      
      expect(result, original);
    });
    
    test('should return original transaction for whitespace instruction', () async {
      final original = Transaction(
        title: 'Original',
        description: 'Test',
        amount: 100,
        type: TransactionType.expense,
        category: 'Food',
      );
      
      final result = await aiService.modifyTransaction(original, '   ');
      
      expect(result, original);
    });
  });
}
