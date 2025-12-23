import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/glassmorphism.dart';

/// A glassmorphic card widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? borderColor;
  
  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.7,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget card = Container(
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
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    
    return card;
  }
}
