import 'package:flutter/material.dart';

/// Dark mode color palette for Crypto Wallet Pro
/// Design: Glassmorphism + Neon gradients
class AppColors {
  AppColors._();

  // Background colors
  static const Color background = Color(0xFF0D0D0D);
  static const Color backgroundSecondary = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);
  static const Color surfaceLight = Color(0xFF1F2937);

  // Card & Glass surfaces
  static const Color cardBackground = Color(0x0DFFFFFF); // 5% white
  static const Color cardBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassSurface = Color(0x1AFFFFFF); // 10% white

  // Primary accent - Neon Cyan
  static const Color primary = Color(0xFF00D9FF);
  static const Color primaryLight = Color(0xFF5CE1E6);
  static const Color primaryDark = Color(0xFF00A8CC);

  // Secondary accent - Neon Purple
  static const Color secondary = Color(0xFFBD00FF);
  static const Color secondaryLight = Color(0xFFE040FB);
  static const Color secondaryDark = Color(0xFF9C27B0);

  // Gradient colors
  static const Color gradientStart = Color(0xFF00D9FF);
  static const Color gradientEnd = Color(0xFFBD00FF);

  // Status colors
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF448AFF);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color textTertiary = Color(0x80FFFFFF); // 50% white
  static const Color textDisabled = Color(0x4DFFFFFF); // 30% white

  // Token icon colors
  static const Color ethColor = Color(0xFF627EEA);
  static const Color usdtColor = Color(0xFF26A17B);
  static const Color uniColor = Color(0xFFFF007A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundSecondary],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
  );

  // Neon glow colors for shadows
  static const Color neonCyanGlow = Color(0x6600D9FF);
  static const Color neonPurpleGlow = Color(0x66BD00FF);
}
