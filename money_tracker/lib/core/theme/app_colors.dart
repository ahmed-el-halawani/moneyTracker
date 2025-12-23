import 'package:flutter/material.dart';

/// App color palette for Glassmorphism theme
class AppColors {
  // Primary colors
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF818CF8);
  
  // Secondary colors
  static const Color secondaryLight = Color(0xFFEC4899);
  static const Color secondaryDark = Color(0xFFF472B6);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  
  // Income/Expense colors
  static const Color incomeColor = Color(0xFF10B981);
  static const Color expenseColor = Color(0xFFEF4444);
  
  // Light theme surfaces
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF1F5F9);
  
  // Dark theme surfaces
  static const Color surfaceDark = Color(0xFF1E1E2D);
  static const Color cardDark = Color(0xFF2D2D3F);
  static const Color backgroundDark = Color(0xFF13131A);
  
  // Glass colors
  static Color glassLight = Colors.white.withOpacity(0.7);
  static Color glassDark = const Color(0xFF1E1E2D).withOpacity(0.8);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  
  // Gradient colors for mesh background
  static const List<Color> meshGradientLight = [
    Color(0xFFFDF2F8), // Pink tint
    Color(0xFFEDE9FE), // Purple tint
    Color(0xFFDBEAFE), // Blue tint
  ];
  
  static const List<Color> meshGradientDark = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F0F23),
  ];
  
  // Category colors
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFF97316),
    'Transport': Color(0xFF3B82F6),
    'Shopping': Color(0xFFEC4899),
    'Entertainment': Color(0xFF8B5CF6),
    'Bills': Color(0xFFEF4444),
    'Salary': Color(0xFF10B981),
    'Healthcare': Color(0xFF06B6D4),
    'Education': Color(0xFF6366F1),
    'Other': Color(0xFF6B7280),
  };
  
  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? categoryColors['Other']!;
  }
}
