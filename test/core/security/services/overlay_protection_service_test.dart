import 'package:crypto_wallet_pro/core/security/services/overlay_protection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OverlayProtectionService service;

  setUp(() {
    service = OverlayProtectionService();
  });

  group('OverlayProtectionService - Non-Android Platform', () {
    // 테스트 환경은 Android가 아니므로 non-Android 경로 테스트
    test('checkOverlayStatus should return safe status on non-Android', () async {
      final status = await service.checkOverlayStatus();

      expect(status.hasOverlay, false);
      expect(status.suspiciousApps, isEmpty);
      expect(status.threatLevel, 0.0);
      expect(status.isSafe, true);
      expect(status.requiresWarning, false);
    });

    test('enableStrictMode should return true on non-Android', () async {
      final result = await service.enableStrictMode();
      expect(result, true);
    });

    test('disableStrictMode should return true on non-Android', () async {
      final result = await service.disableStrictMode();
      expect(result, true);
    });

    test('getAppsWithOverlayPermission should return empty on non-Android', () async {
      final apps = await service.getAppsWithOverlayPermission();
      expect(apps, isEmpty);
    });
  });

  group('OverlayStatus', () {
    test('should correctly determine safety with no overlay', () {
      const safe = OverlayStatus(
        hasOverlay: false,
        suspiciousApps: [],
        threatLevel: 0.2,
      );

      expect(safe.isSafe, true);
      expect(safe.requiresWarning, false);
    });

    test('should correctly determine danger with overlay', () {
      const unsafe = OverlayStatus(
        hasOverlay: true,
        suspiciousApps: ['malware.app'],
        threatLevel: 0.8,
      );

      expect(unsafe.isSafe, false);
      expect(unsafe.requiresWarning, true);
    });

    test('should require warning with high threat level even without overlay', () {
      const status = OverlayStatus(
        hasOverlay: false,
        suspiciousApps: [],
        threatLevel: 0.6,
      );

      expect(status.requiresWarning, true);
    });

    test('should be safe with low threat level', () {
      const status = OverlayStatus(
        hasOverlay: false,
        suspiciousApps: [],
        threatLevel: 0.1,
      );

      expect(status.isSafe, true);
      expect(status.requiresWarning, false);
    });

    test('should not be safe with moderate threat level', () {
      const status = OverlayStatus(
        hasOverlay: false,
        suspiciousApps: [],
        threatLevel: 0.4,
      );

      expect(status.isSafe, false);
      expect(status.requiresWarning, false);
    });

    test('should capture error message', () {
      const status = OverlayStatus(
        hasOverlay: false,
        suspiciousApps: [],
        threatLevel: 0.5,
        errorMessage: 'Test error',
      );

      expect(status.errorMessage, 'Test error');
    });

    test('should have correct toString', () {
      const status = OverlayStatus(
        hasOverlay: true,
        suspiciousApps: ['app1', 'app2'],
        threatLevel: 0.7,
      );

      expect(
        status.toString(),
        'OverlayStatus(hasOverlay: true, threatLevel: 0.7, suspiciousApps: [app1, app2])',
      );
    });

    test('should handle unsupported platform', () {
      const status = OverlayStatus(
        hasOverlay: false,
        suspiciousApps: [],
        threatLevel: 0.0,
        isSupported: false,
      );

      expect(status.isSupported, false);
      expect(status.isSafe, true);
    });
  });
}
