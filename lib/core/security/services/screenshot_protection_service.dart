import 'package:flutter/services.dart';

/// Service for managing screenshot and screen recording protection.
///
/// Platform-specific implementations:
/// - Android: Uses FLAG_SECURE to prevent screenshots and screen recording
/// - iOS: Applies blur overlay when app enters background (snapshot protection)
///
/// Security Notes:
/// - Call [enable] when displaying sensitive content (mnemonic, private keys)
/// - Call [disable] when leaving sensitive screens
/// - Use [SecureContentWrapper] widget for automatic lifecycle management
class ScreenshotProtectionService {
  static const MethodChannel _channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/security');

  /// Enable screenshot protection.
  ///
  /// This should be called when entering screens that display sensitive data:
  /// - Mnemonic phrase display/confirmation
  /// - Private key display
  /// - Seed phrase backup
  ///
  /// Platform behavior:
  /// - Android: Sets FLAG_SECURE on the window
  /// - iOS: Registers observer for background state changes
  ///
  /// Returns true if protection was enabled successfully.
  Future<bool> enable() async {
    try {
      final result = await _channel.invokeMethod<bool>('enableProtection');
      return result ?? false;
    } on PlatformException catch (e) {
      // Platform not supported or error occurred
      // In production, use proper logging (e.g., Firebase Crashlytics)
      // Gracefully degrade - don't crash the app
      // ignore: avoid_print
      print('Failed to enable screenshot protection: ${e.message}');
      return false;
    }
  }

  /// Disable screenshot protection.
  ///
  /// This should be called when leaving sensitive screens.
  ///
  /// Platform behavior:
  /// - Android: Clears FLAG_SECURE from the window
  /// - iOS: Removes background state observer
  ///
  /// Returns true if protection was disabled successfully.
  Future<bool> disable() async {
    try {
      final result = await _channel.invokeMethod<bool>('disableProtection');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to disable screenshot protection: ${e.message}');
      return false;
    }
  }

  /// Check if screenshot protection is currently active.
  ///
  /// Useful for debugging or UI state management.
  Future<bool> isEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isProtectionEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to check protection status: ${e.message}');
      return false;
    }
  }
}
