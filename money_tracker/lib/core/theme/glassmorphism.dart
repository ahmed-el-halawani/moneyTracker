import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Glassmorphism decoration utilities
class Glassmorphism {
  /// Creates a glassmorphism container decoration
  static BoxDecoration decoration({
    double blur = 15.0,
    double opacity = 0.7,
    double borderRadius = 16.0,
    Color? borderColor,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: isDark 
          ? AppColors.glassDark 
          : Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorder,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
  
  /// Creates a gradient glass decoration
  static BoxDecoration gradientDecoration({
    double borderRadius = 16.0,
    List<Color>? gradientColors,
    bool isDark = false,
  }) {
    final colors = gradientColors ?? 
        (isDark ? AppColors.meshGradientDark : AppColors.meshGradientLight);
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.map((c) => c.withOpacity(0.8)).toList(),
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.glassBorder,
        width: 1.5,
      ),
    );
  }
  
  /// Mesh gradient background decoration
  static BoxDecoration meshBackground({bool isDark = false}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark 
            ? AppColors.meshGradientDark 
            : AppColors.meshGradientLight,
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }
}

/// A widget that applies glassmorphism effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final Color? borderColor;
  
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.7,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: Glassmorphism.decoration(
              blur: blur,
              opacity: opacity,
              borderRadius: borderRadius,
              borderColor: borderColor,
              isDark: isDark,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
