import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A reusable glassmorphism style card widget
/// Features: translucent background, blur effect, gradient border
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;
  final Color? backgroundColor;
  final bool showBorder;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blurAmount = 10,
    this.backgroundColor,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              splashColor: AppColors.primary.withValues(alpha: 0.1),
              highlightColor: AppColors.primary.withValues(alpha: 0.05),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: showBorder
                      ? Border.all(color: AppColors.cardBorder, width: 1)
                      : null,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A variant of GlassmorphicCard with a colored accent glow
class GlassmorphicAccentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color accentColor;

  const GlassmorphicAccentCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GlassmorphicCard(
        padding: padding,
        borderRadius: borderRadius,
        backgroundColor: AppColors.cardBackground,
        child: child,
      ),
    );
  }
}
