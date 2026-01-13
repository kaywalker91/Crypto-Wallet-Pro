# Security Module

This module provides security features for protecting sensitive user data in the crypto wallet app.

## Features

### Screenshot Protection

Prevents screenshots and screen recording on sensitive screens (mnemonic display, private key display).

#### Platform Implementation

**Android**
- Uses `FLAG_SECURE` on the window
- Prevents screenshots, screen recording, and content visibility in Recent Apps
- No known bypasses on non-rooted devices
- Works from Android 5.0+

**iOS**
- Applies blur overlay when app enters background state
- Hides content in App Switcher snapshot
- **Limitation**: Cannot prevent screenshots while app is in foreground (iOS platform limitation)
- Alternative: Implement screenshot detection for user warnings

#### Usage

##### Option 1: Widget Wrapper (Recommended)

```dart
import 'package:crypto_wallet_pro/core/security/widgets/secure_content_wrapper.dart';

class MnemonicDisplayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SecureContentWrapper(
      child: Scaffold(
        body: MnemonicGrid(words: mnemonicWords),
      ),
    );
  }
}
```

##### Option 2: Manual Service Control

```dart
import 'package:crypto_wallet_pro/core/security/services/screenshot_protection_service.dart';

class _MyPageState extends State<MyPage> {
  final _protectionService = ScreenshotProtectionService();

  @override
  void initState() {
    super.initState();
    _protectionService.enable();
  }

  @override
  void dispose() {
    _protectionService.disable();
    super.dispose();
  }
}
```

##### Option 3: With Loading Indicator

```dart
SecureContentWrapperWithIndicator(
  loadingIndicator: CircularProgressIndicator(),
  child: MnemonicDisplay(words: mnemonicWords),
)
```

#### Security Best Practices

1. **Scope**: Apply protection only to screens displaying sensitive data
   - Mnemonic phrase display/confirmation
   - Private key export
   - Seed phrase backup

2. **Lifecycle**: Use `SecureContentWrapper` for automatic management
   - Enables protection on mount
   - Disables protection on dispose
   - Handles edge cases (app backgrounding, crashes)

3. **User Experience**: Don't apply globally
   - Users expect to screenshot non-sensitive content
   - May reduce app store ratings if overused

4. **Defense in Depth**: Combine with other security measures
   - Biometric authentication before displaying sensitive data
   - Encrypted storage (Keychain/Keystore)
   - Secure memory handling (clear sensitive data after use)

#### Testing

**Android**
```bash
# Enable protection, then attempt screenshot
adb shell screencap /sdcard/test.png
# Expected: Black screen or error
```

**iOS**
```bash
# Enable protection, background app, check app switcher
# Expected: Blurred overlay on app preview
```

#### Known Limitations

| Platform | Limitation | Workaround |
|----------|-----------|------------|
| Android (Rooted) | FLAG_SECURE can be bypassed | Detect root, warn user |
| iOS | Cannot prevent foreground screenshots | Detect screenshot event, show warning |
| Android < 5.0 | FLAG_SECURE not fully supported | Show warning on old devices |
| Screen Recording | iOS doesn't block foreground recording | Implement recording detection |

#### iOS Screenshot Detection (Optional Enhancement)

```dart
// Add to ScreenshotProtectionService
void addScreenshotListener(VoidCallback onScreenshot) {
  // iOS: Listen to UIApplicationUserDidTakeScreenshotNotification
  // Android: Monitor media store changes
}

// Usage
_protectionService.addScreenshotListener(() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Security Warning'),
      content: Text('Screenshots of sensitive data are not recommended'),
    ),
  );
});
```

## Future Enhancements

- [ ] Root/Jailbreak detection
- [ ] Screenshot detection with user warnings
- [ ] Screen recording detection
- [ ] Overlay attack prevention (Android)
- [ ] Tamper detection (code signing verification)
- [ ] Secure enclave integration (iOS)
- [ ] Hardware-backed keystore (Android StrongBox)

## References

- [Android FLAG_SECURE](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#FLAG_SECURE)
- [iOS Screenshot Protection Techniques](https://developer.apple.com/documentation/uikit/app_and_environment/protecting_the_user_s_privacy)
- [OWASP Mobile Security Testing Guide](https://github.com/OWASP/owasp-mstg)
