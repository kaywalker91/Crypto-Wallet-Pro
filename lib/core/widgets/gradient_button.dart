import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Gradient button with neon glow effect
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final double borderRadius;
  final bool showGlow;
  final bool isLoading;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
    this.showGlow = true,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final gradient = isEnabled
        ? AppColors.primaryGradient
        : LinearGradient(
            colors: [
              AppColors.surfaceLight,
              AppColors.surface,
            ],
          );
    final foreground = isEnabled ? AppColors.background : AppColors.textDisabled;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        border: isEnabled ? null : Border.all(color: AppColors.cardBorder),
        boxShadow: showGlow && isEnabled
            ? [
                BoxShadow(
                  color: AppColors.neonCyanGlow,
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.neonPurpleGlow,
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: foreground.withValues(alpha: 0.16),
          highlightColor: foreground.withValues(alpha: 0.08),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.background,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: foreground,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: AppTypography.buttonText.copyWith(
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Outlined button with gradient border
class GradientOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final double borderRadius;
  final IconData? icon;

  const GradientOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final borderGradient = isEnabled
        ? AppColors.primaryGradient
        : LinearGradient(
            colors: [
              AppColors.cardBorder,
              AppColors.cardBorder,
            ],
          );
    final foreground = isEnabled ? Colors.white : AppColors.textDisabled;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: borderGradient,
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - 2),
          color: AppColors.background,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius - 2),
            splashColor: AppColors.primary.withValues(alpha: 0.16),
            highlightColor: AppColors.primary.withValues(alpha: 0.08),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          borderGradient.createShader(bounds),
                      child: Icon(
                        icon,
                        color: foreground,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        borderGradient.createShader(bounds),
                    child: Text(
                      text,
                      style: AppTypography.buttonText.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
