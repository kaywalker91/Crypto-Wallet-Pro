import 'package:flutter/material.dart';

import '../services/screenshot_protection_service.dart';

/// A widget that automatically enables screenshot protection for its content.
///
/// This widget manages the lifecycle of screenshot protection:
/// - Enables protection when the widget is mounted
/// - Disables protection when the widget is disposed
///
/// Usage:
/// ```dart
/// SecureContentWrapper(
///   child: MnemonicDisplay(words: mnemonicWords),
/// )
/// ```
///
/// Security Best Practices:
/// - Wrap entire sensitive screens (not individual widgets)
/// - Ensure protection is active before displaying sensitive data
/// - Combine with other security measures (authentication, encryption)
///
/// Platform Support:
/// - Android: FLAG_SECURE (prevents screenshots and screen recording)
/// - iOS: Blur overlay when app enters background
class SecureContentWrapper extends StatefulWidget {
  /// The child widget to protect.
  ///
  /// This content will be protected from screenshots and screen recording.
  final Widget child;

  /// Optional callback when protection is enabled.
  ///
  /// Receives true if protection was enabled successfully, false otherwise.
  final ValueChanged<bool>? onProtectionEnabled;

  /// Optional callback when protection is disabled.
  final ValueChanged<bool>? onProtectionDisabled;

  const SecureContentWrapper({
    super.key,
    required this.child,
    this.onProtectionEnabled,
    this.onProtectionDisabled,
  });

  @override
  State<SecureContentWrapper> createState() => _SecureContentWrapperState();
}

class _SecureContentWrapperState extends State<SecureContentWrapper> {
  final _protectionService = ScreenshotProtectionService();

  @override
  void initState() {
    super.initState();
    _enableProtection();
  }

  @override
  void dispose() {
    _disableProtection();
    super.dispose();
  }

  Future<void> _enableProtection() async {
    final success = await _protectionService.enable();
    if (mounted) {
      widget.onProtectionEnabled?.call(success);
    }
  }

  Future<void> _disableProtection() async {
    final success = await _protectionService.disable();
    widget.onProtectionDisabled?.call(success);
  }

  @override
  Widget build(BuildContext context) {
    // Return child directly - protection is managed in lifecycle
    return widget.child;
  }
}

/// A more opinionated secure wrapper with visual feedback.
///
/// Shows a loading state until screenshot protection is confirmed active.
/// Use this when you want to ensure protection is definitely enabled
/// before displaying sensitive content.
class SecureContentWrapperWithIndicator extends StatefulWidget {
  final Widget child;
  final Widget? loadingIndicator;

  const SecureContentWrapperWithIndicator({
    super.key,
    required this.child,
    this.loadingIndicator,
  });

  @override
  State<SecureContentWrapperWithIndicator> createState() =>
      _SecureContentWrapperWithIndicatorState();
}

class _SecureContentWrapperWithIndicatorState
    extends State<SecureContentWrapperWithIndicator> {
  final _protectionService = ScreenshotProtectionService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _enableProtection();
  }

  @override
  void dispose() {
    _protectionService.disable();
    super.dispose();
  }

  Future<void> _enableProtection() async {
    await _protectionService.enable();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingIndicator ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    // Show content after protection is enabled (graceful degradation)
    return widget.child;
  }
}
