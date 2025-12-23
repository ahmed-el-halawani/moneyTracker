import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Category model for transactions
class Category {
  final String id;
  final String name;
  final String icon;
  final Color color;
  
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
    };
  }
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: Color(json['color'] as int),
    );
  }
}

/// Predefined categories
class Categories {
  static const List<Category> all = [
    Category(
      id: 'food',
      name: 'Food',
      icon: 'utensils',
      color: Color(0xFFF97316),
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: 'car',
      color: Color(0xFF3B82F6),
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: 'shopping-bag',
      color: Color(0xFFEC4899),
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: 'gamepad-2',
      color: Color(0xFF8B5CF6),
    ),
    Category(
      id: 'bills',
      name: 'Bills',
      icon: 'receipt',
      color: Color(0xFFEF4444),
    ),
    Category(
      id: 'salary',
      name: 'Salary',
      icon: 'wallet',
      color: Color(0xFF10B981),
    ),
    Category(
      id: 'healthcare',
      name: 'Healthcare',
      icon: 'heart-pulse',
      color: Color(0xFF06B6D4),
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: 'graduation-cap',
      color: Color(0xFF6366F1),
    ),
    Category(
      id: 'investment',
      name: 'Investment',
      icon: 'trending-up',
      color: Color(0xFF22C55E),
    ),
    Category(
      id: 'gifts',
      name: 'Gifts',
      icon: 'gift',
      color: Color(0xFFF472B6),
    ),
    Category(
      id: 'other',
      name: 'Other',
      icon: 'more-horizontal',
      color: Color(0xFF6B7280),
    ),
  ];
  
  static Category getByName(String name) {
    return all.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => all.last, // Return 'Other' as default
    );
  }
  
  static Category getById(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => all.last,
    );
  }
  
  static Color getColor(String categoryName) {
    return getByName(categoryName).color;
  }
  
  static List<Category> get expenseCategories {
    return all.where((c) => c.id != 'salary' && c.id != 'investment').toList();
  }
  
  static List<Category> get incomeCategories {
    return [
      all.firstWhere((c) => c.id == 'salary'),
      all.firstWhere((c) => c.id == 'investment'),
      all.firstWhere((c) => c.id == 'gifts'),
      all.firstWhere((c) => c.id == 'other'),
    ];
  }
}
