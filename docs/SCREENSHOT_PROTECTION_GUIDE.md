# Screenshot Protection Implementation Guide

## Overview

This guide explains how screenshot protection has been implemented in the crypto wallet app and how to use it for new sensitive screens.

## Architecture

```
┌─────────────────────────────────────────────────┐
│           SecureContentWrapper                  │
│           (Widget Layer)                        │
│  - Auto lifecycle management                    │
│  - Declarative API                              │
└──────────────────┬──────────────────────────────┘
                   │ Uses
┌──────────────────▼──────────────────────────────┐
│      ScreenshotProtectionService                │
│      (Service Layer)                            │
│  - MethodChannel abstraction                    │
│  - Platform detection                           │
└──────────────────┬──────────────────────────────┘
                   │ Invokes
        ┌──────────┴──────────┐
        ▼                     ▼
┌──────────────┐    ┌──────────────────┐
│   Android    │    │      iOS         │
│ FLAG_SECURE  │    │  Blur Overlay    │
└──────────────┘    └──────────────────┘
```

## Current Implementation

### Protected Screens

1. **Mnemonic Display** (`_ShowMnemonicStep`)
   - 12-word recovery phrase display
   - Protection enabled for entire step

2. **Mnemonic Confirmation** (`_ConfirmMnemonicStep`)
   - Word verification interface
   - Protection enabled for entire step

### Code Example

```dart
// Before
class _ShowMnemonicStep extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: MnemonicGrid(words: mnemonicWords),
    );
  }
}

// After
class _ShowMnemonicStep extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return SecureContentWrapper(  // Added wrapper
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: MnemonicGrid(words: mnemonicWords),
      ),
    );
  }
}
```

## Platform-Specific Behavior

### Android

**Mechanism**: `FLAG_SECURE` on window

**Protection**:
- Prevents screenshots (Power + Volume Down)
- Prevents third-party screenshot apps
- Hides content in Recent Apps (App Switcher)
- Blocks screen recording

**Code**: `MainActivity.kt`
```kotlin
private fun enableScreenshotProtection() {
    window.setFlags(
        WindowManager.LayoutParams.FLAG_SECURE,
        WindowManager.LayoutParams.FLAG_SECURE
    )
}
```

**Testing**:
```bash
# Navigate to mnemonic screen, then attempt screenshot
adb shell screencap /sdcard/screenshot.png
# Expected: Black screen or permission error

# Check Recent Apps
# Expected: Blank/black preview
```

### iOS

**Mechanism**: Blur overlay on background state

**Protection**:
- Applies blur when app enters background
- Hides content in App Switcher snapshot
- Removes blur when app returns to foreground

**Code**: `AppDelegate.swift`
```swift
@objc private func applicationDidEnterBackground() {
    guard isProtectionEnabled else { return }

    let blurEffect = UIBlurEffect(style: .systemMaterial)
    let blurView = UIVisualEffectView(effect: blurEffect)
    window.addSubview(blurView)
}
```

**Testing**:
1. Navigate to mnemonic screen
2. Swipe up to show App Switcher
3. Expected: Blurred overlay on app preview

**Limitation**: Cannot prevent foreground screenshots (iOS API limitation)

## Adding Protection to New Screens

### Step 1: Identify Sensitive Content

Screens that should be protected:
- Mnemonic phrase display
- Private key export
- Seed phrase backup
- Recovery phrase import
- Transaction signing (optional)

Screens that should NOT be protected:
- Dashboard
- Settings
- Transaction history
- NFT gallery

### Step 2: Wrap with SecureContentWrapper

```dart
import 'package:crypto_wallet_pro/core/security/widgets/secure_content_wrapper.dart';

class PrivateKeyExportPage extends StatelessWidget {
  final String privateKey;

  @override
  Widget build(BuildContext context) {
    return SecureContentWrapper(
      onProtectionEnabled: (success) {
        if (!success) {
          // Optional: Show warning to user
          print('Warning: Screenshot protection failed');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Private Key')),
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Text('Your Private Key'),
              SelectableText(
                privateKey,
                style: TextStyle(fontFamily: 'monospace'),
              ),
              SizedBox(height: 16),
              Text(
                'Never share your private key',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Step 3: Test on Both Platforms

**Android Testing Checklist**:
- [ ] Screenshots blocked
- [ ] Screen recording blocked
- [ ] Recent Apps shows blank screen
- [ ] Protection disables when leaving screen

**iOS Testing Checklist**:
- [ ] App Switcher shows blur overlay
- [ ] Blur appears immediately on background
- [ ] Blur removes on foreground
- [ ] No memory leaks from blur view

## Advanced Usage

### With Loading Indicator

Use when you want to ensure protection is active before showing content:

```dart
SecureContentWrapperWithIndicator(
  loadingIndicator: CircularProgressIndicator(),
  child: SensitiveContent(),
)
```

### Manual Service Control

For fine-grained control or non-widget contexts:

```dart
class _MyPageState extends State<MyPage> {
  final _protectionService = ScreenshotProtectionService();

  @override
  void initState() {
    super.initState();
    _enableProtectionSafely();
  }

  Future<void> _enableProtectionSafely() async {
    final success = await _protectionService.enable();
    if (!success) {
      // Handle failure (optional warning)
    }
  }

  @override
  void dispose() {
    _protectionService.disable();
    super.dispose();
  }

  // Rest of widget...
}
```

### Check Protection Status

```dart
final isProtected = await _protectionService.isEnabled();
if (isProtected) {
  // Safe to display sensitive data
} else {
  // Show warning or retry
}
```

## Security Considerations

### Defense in Depth

Screenshot protection is ONE layer of security. Always combine with:

1. **Encryption at Rest**
   - Use `SecureStorageService` for sensitive data
   - Never store plaintext mnemonics

2. **Authentication**
   - Require biometrics/PIN before displaying sensitive data
   - Re-authenticate for critical operations

3. **Secure Memory**
   - Clear sensitive data after use
   - Use `Uint8List` for keys, zero out after use

4. **User Education**
   - Show warnings about screenshot risks
   - Educate users about phishing

### Threat Model

| Threat | Android Protection | iOS Protection | Additional Mitigation |
|--------|-------------------|----------------|------------------------|
| Screenshot by user | FLAG_SECURE | None (foreground) | User education |
| Screen recording | FLAG_SECURE | None (foreground) | Detect recording |
| App Switcher leak | FLAG_SECURE | Blur overlay | Both covered |
| Screenshot apps | FLAG_SECURE | N/A | Root detection |
| Rooted device bypass | Partial | N/A | Root detection + warning |

### Known Bypasses

1. **Android Rooted Devices**
   - FLAG_SECURE can be bypassed with Xposed modules
   - Mitigation: Detect root, show warning, disable sensitive features

2. **iOS Foreground Screenshots**
   - iOS doesn't provide APIs to prevent foreground screenshots
   - Mitigation: Detect screenshot event, show warning dialog

3. **External Camera**
   - User can photograph screen with another device
   - Mitigation: User education, time-limited display

4. **Screen Sharing**
   - User can share screen via video call
   - Mitigation: Detect screen recording (future enhancement)

## Future Enhancements

### iOS Screenshot Detection

```dart
// Add to ScreenshotProtectionService
Stream<void> get onScreenshotTaken {
  return _screenshotEventChannel.receiveBroadcastStream();
}

// iOS native (AppDelegate.swift)
NotificationCenter.default.addObserver(
  forName: UIApplication.userDidTakeScreenshotNotification,
  object: nil,
  queue: .main
) { _ in
  channel.invokeMethod("onScreenshot", arguments: nil)
}

// Usage
service.onScreenshotTaken.listen((_) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Security Warning'),
      content: Text('Screenshots of recovery phrases can be stolen by malware'),
    ),
  );
});
```

### Root/Jailbreak Detection

```dart
// Check if device is compromised
final isCompromised = await SecurityService.isDeviceCompromised();
if (isCompromised) {
  showWarningDialog('Your device appears to be rooted/jailbroken');
}
```

### Screen Recording Detection

```dart
// Android: Check for MediaRecorder
// iOS: Monitor UIScreen.isCaptured (iOS 11+)
final isRecording = await SecurityService.isScreenBeingRecorded();
if (isRecording) {
  showWarningDialog('Screen recording detected');
}
```

## Troubleshooting

### Android: Screenshots still work

**Cause**: Protection not enabled or device rooted

**Solution**:
1. Check logs: `await service.isEnabled()`
2. Test on non-rooted device
3. Verify `configureFlutterEngine` is called in MainActivity

### iOS: No blur in App Switcher

**Cause**: Observer not registered or timing issue

**Solution**:
1. Check `isProtectionEnabled` flag in AppDelegate
2. Verify observers are added before backgrounding
3. Test on real device (simulator may behave differently)

### Protection disables unexpectedly

**Cause**: Widget disposal or service state issue

**Solution**:
1. Use `SecureContentWrapper` for automatic management
2. Don't call `disable()` manually when using wrapper
3. Check for multiple `dispose()` calls

## Testing Checklist

### Unit Tests

- [x] `enable()` calls native method
- [x] `disable()` calls native method
- [x] `isEnabled()` returns correct state
- [x] Platform exceptions handled gracefully

### Integration Tests

- [ ] Protection persists across navigation
- [ ] Multiple protected screens work independently
- [ ] No memory leaks from wrappers

### Manual Tests

- [ ] Android: Screenshot blocked
- [ ] Android: Screen recording blocked
- [ ] Android: Recent Apps blank
- [ ] iOS: App Switcher shows blur
- [ ] iOS: Blur timing correct
- [ ] Both: Protection disables on screen exit

## References

- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)
- [iOS Data Security](https://developer.apple.com/documentation/security)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
