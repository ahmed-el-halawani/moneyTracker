import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/category.dart';

void main() {
  group('Category Model', () {
    test('should have all predefined categories', () {
      expect(Categories.all.length, 11);
      
      final categoryNames = Categories.all.map((c) => c.name).toList();
      expect(categoryNames, contains('Food'));
      expect(categoryNames, contains('Transport'));
      expect(categoryNames, contains('Shopping'));
      expect(categoryNames, contains('Entertainment'));
      expect(categoryNames, contains('Bills'));
      expect(categoryNames, contains('Salary'));
      expect(categoryNames, contains('Healthcare'));
      expect(categoryNames, contains('Education'));
      expect(categoryNames, contains('Investment'));
      expect(categoryNames, contains('Gifts'));
      expect(categoryNames, contains('Other'));
    });
    
    test('should get category by name (case insensitive)', () {
      final food = Categories.getByName('Food');
      expect(food.name, 'Food');
      expect(food.id, 'food');
      
      final foodLower = Categories.getByName('food');
      expect(foodLower.name, 'Food');
      
      final foodUpper = Categories.getByName('FOOD');
      expect(foodUpper.name, 'Food');
    });
    
    test('should return Other for unknown category name', () {
      final unknown = Categories.getByName('Unknown Category');
      expect(unknown.name, 'Other');
      expect(unknown.id, 'other');
    });
    
    test('should get category by ID', () {
      final food = Categories.getById('food');
      expect(food.name, 'Food');
      
      final salary = Categories.getById('salary');
      expect(salary.name, 'Salary');
    });
    
    test('should return Other for unknown category ID', () {
      final unknown = Categories.getById('unknown-id');
      expect(unknown.name, 'Other');
    });
    
    test('should get color for category', () {
      final foodColor = Categories.getColor('Food');
      expect(foodColor, const Color(0xFFF97316));
      
      final salaryColor = Categories.getColor('Salary');
      expect(salaryColor, const Color(0xFF10B981));
    });
    
    test('should return expense categories without income categories', () {
      final expenseCategories = Categories.expenseCategories;
      
      expect(expenseCategories.any((c) => c.id == 'salary'), false);
      expect(expenseCategories.any((c) => c.id == 'investment'), false);
      expect(expenseCategories.any((c) => c.id == 'food'), true);
      expect(expenseCategories.any((c) => c.id == 'bills'), true);
    });
    
    test('should return income categories', () {
      final incomeCategories = Categories.incomeCategories;
      
      expect(incomeCategories.any((c) => c.id == 'salary'), true);
      expect(incomeCategories.any((c) => c.id == 'investment'), true);
      expect(incomeCategories.any((c) => c.id == 'gifts'), true);
      expect(incomeCategories.any((c) => c.id == 'other'), true);
    });
    
    test('should convert to JSON and back', () {
      final original = Category(
        id: 'test',
        name: 'Test Category',
        icon: 'test-icon',
        color: const Color(0xFF123456),
      );
      
      final json = original.toJson();
      final restored = Category.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.icon, original.icon);
      expect(restored.color.value, original.color.value);
    });
  });
}
