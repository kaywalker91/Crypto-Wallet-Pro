import 'package:flutter/material.dart';

/// Dark mode color palette for Crypto Wallet Pro
/// Design: Glassmorphism + deep navy accents
class AppColors {
  AppColors._();

  // Background colors
  static const Color background = Color(0xFF0B1220);
  static const Color backgroundSecondary = Color(0xFF0E172A);
  static const Color surface = Color(0xFF101B2D);
  static const Color surfaceLight = Color(0xFF18243A);

  // Card & Glass surfaces
  static const Color cardBackground = Color(0xFF111E33);
  static const Color cardBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassSurface = Color(0x1AFFFFFF); // 10% white

  // Primary accent - Blue/Cyan
  static const Color primary = Color(0xFF2BB0FF);
  static const Color primaryLight = Color(0xFF7CD9FF);
  static const Color primaryDark = Color(0xFF0A7AC2);

  // Secondary accent - Indigo Blue
  static const Color secondary = Color(0xFF5B7CFF);
  static const Color secondaryLight = Color(0xFF8FA6FF);
  static const Color secondaryDark = Color(0xFF3F5ED6);

  // Gradient colors
  static const Color gradientStart = Color(0xFF2BB0FF);
  static const Color gradientEnd = Color(0xFF5B7CFF);

  // Status colors
  static const Color success = Color(0xFF16C784);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF38BDF8);

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);

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
      Color(0x1FFFFFFF),
      Color(0x0DFFFFFF),
    ],
  );

  // Neon glow colors for shadows
  static const Color neonCyanGlow = Color(0x662BB0FF);
  static const Color neonPurpleGlow = Color(0x665B7CFF);
}
