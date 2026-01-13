import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_wallet_pro/core/security/services/screenshot_protection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScreenshotProtectionService service;
  late List<MethodCall> methodCalls;

  setUp(() {
    service = ScreenshotProtectionService();
    methodCalls = [];

    // Mock MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.etherflow.crypto_wallet_pro/security'),
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);

        switch (methodCall.method) {
          case 'enableProtection':
            return true;
          case 'disableProtection':
            return true;
          case 'isProtectionEnabled':
            return methodCalls
                .where((call) => call.method == 'enableProtection')
                .length >
                methodCalls
                    .where((call) => call.method == 'disableProtection')
                    .length;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.etherflow.crypto_wallet_pro/security'),
      null,
    );
    methodCalls.clear();
  });

  group('ScreenshotProtectionService', () {
    test('enable() should call native enableProtection method', () async {
      final result = await service.enable();

      expect(result, isTrue);
      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'enableProtection');
    });

    test('disable() should call native disableProtection method', () async {
      final result = await service.disable();

      expect(result, isTrue);
      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'disableProtection');
    });

    test('isEnabled() should return correct state', () async {
      // Initially disabled
      var isEnabled = await service.isEnabled();
      expect(isEnabled, isFalse);

      // Enable
      await service.enable();
      isEnabled = await service.isEnabled();
      expect(isEnabled, isTrue);

      // Disable
      await service.disable();
      isEnabled = await service.isEnabled();
      expect(isEnabled, isFalse);
    });

    test('should handle platform exceptions gracefully', () async {
      // Mock exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.etherflow.crypto_wallet_pro/security'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'ERROR',
            message: 'Test error',
          );
        },
      );

      final result = await service.enable();
      expect(result, isFalse);
    });

    test('enable and disable should be idempotent', () async {
      // Multiple enables
      await service.enable();
      await service.enable();
      await service.enable();

      var enableCount = methodCalls
          .where((call) => call.method == 'enableProtection')
          .length;
      expect(enableCount, 3);

      // Multiple disables
      await service.disable();
      await service.disable();

      var disableCount = methodCalls
          .where((call) => call.method == 'disableProtection')
          .length;
      expect(disableCount, 2);
    });

    test('should maintain state across multiple calls', () async {
      // Enable -> Disable -> Enable cycle
      await service.enable();
      await service.disable();
      await service.enable();

      var isEnabled = await service.isEnabled();
      expect(isEnabled, isTrue);
    });
  });
}
