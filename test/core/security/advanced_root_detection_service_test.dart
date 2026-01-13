import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:crypto_wallet_pro/core/security/services/advanced_root_detection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/advanced_security');

  late AdvancedRootDetectionService service;

  setUp(() {
    service = AdvancedRootDetectionService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AdvancedRootDetectionService - performDeepScan', () {
    test('should return secure result when no threats detected', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performAndroidDeepScan') {
          return {
            'threats': <String>[],
            'confidence': 0.0,
            'details': {},
          };
        }
        return null;
      });

      final result = await service.performDeepScan();

      expect(result.isCompromised, false);
      expect(result.confidenceScore, 0.0);
      expect(result.detectedThreats, isEmpty);
    });

    test('should detect su_binary threat on Android', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performAndroidDeepScan') {
          return {
            'threats': ['su_binary'],
            'confidence': 0.9,
            'details': {'suPath': '/system/xbin/su'},
          };
        }
        return null;
      });

      final result = await service.performDeepScan();

      expect(result.isCompromised, true);
      expect(result.confidenceScore, 0.9);
      expect(result.detectedThreats, contains(ThreatIndicator.suBinary));
    });

    test('should detect multiple threats with high confidence', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performAndroidDeepScan') {
          return {
            'threats': ['su_binary', 'magisk_app', 'test_keys'],
            'confidence': 0.95,
            'details': {
              'suPath': '/system/xbin/su',
              'magiskVersion': '25.2',
              'buildTags': 'test-keys',
            },
          };
        }
        return null;
      });

      final result = await service.performDeepScan();

      expect(result.isCompromised, true);
      expect(result.confidenceScore, 0.95);
      expect(result.detectedThreats, hasLength(3));
      expect(result.detectedThreats, contains(ThreatIndicator.suBinary));
      expect(result.detectedThreats, contains(ThreatIndicator.magiskApp));
      expect(result.detectedThreats, contains(ThreatIndicator.testKeys));
    });

    test('should detect iOS jailbreak threats', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        // 테스트 환경에서는 먼저 Android 메서드가 호출됨
        if (methodCall.method == 'performAndroidDeepScan' ||
            methodCall.method == 'performIOSDeepScan') {
          return {
            'threats': ['cydia_app', 'jailbreak_files', 'sandbox_breach'],
            'confidence': 0.88,
            'details': {
              'cydiaPath': '/Applications/Cydia.app',
              'jailbreakFiles': ['/private/var/lib/apt', '/Library/MobileSubstrate'],
            },
          };
        }
        return null;
      });

      final result = await service.performDeepScan();

      expect(result.isCompromised, true);
      expect(result.confidenceScore, 0.88);
      expect(result.detectedThreats, contains(ThreatIndicator.cydiaApp));
      expect(result.detectedThreats, contains(ThreatIndicator.jailbreakFiles));
      expect(result.detectedThreats, contains(ThreatIndicator.sandboxBreach));
    });

    test('should handle platform exception gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERROR', message: 'Scan failed');
      });

      final result = await service.performDeepScan();

      expect(result.isCompromised, false);
      expect(result.confidenceScore, 0.5);
      expect(result.details, containsPair('error', 'Scan failed'));
    });
  });

  group('AdvancedRootDetectionService - performQuickScan', () {
    test('should perform quick scan successfully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performAndroidQuickScan') {
          return {
            'threats': ['su_binary'],
            'confidence': 0.8,
          };
        }
        return null;
      });

      final result = await service.performQuickScan();

      expect(result.isCompromised, true);
      expect(result.confidenceScore, 0.8);
      expect(result.detectedThreats, contains(ThreatIndicator.suBinary));
    });

    test('should return secure result when no threats in quick scan', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performAndroidQuickScan') {
          return {
            'threats': <String>[],
            'confidence': 0.0,
          };
        }
        return null;
      });

      final result = await service.performQuickScan();

      expect(result.isCompromised, false);
      expect(result.confidenceScore, 0.0);
      expect(result.detectedThreats, isEmpty);
    });

    test('should handle exception in quick scan', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERROR');
      });

      final result = await service.performQuickScan();

      expect(result.isCompromised, false);
      expect(result.confidenceScore, 0.0);
    });
  });

  group('AdvancedRootDetectionService - getRiskLevel', () {
    test('should return "low" for score < 0.3', () {
      expect(service.getRiskLevel(0.0), 'low');
      expect(service.getRiskLevel(0.2), 'low');
    });

    test('should return "medium" for score 0.3-0.7', () {
      expect(service.getRiskLevel(0.3), 'medium');
      expect(service.getRiskLevel(0.5), 'medium');
      expect(service.getRiskLevel(0.69), 'medium');
    });

    test('should return "high" for score >= 0.7', () {
      expect(service.getRiskLevel(0.7), 'high');
      expect(service.getRiskLevel(0.9), 'high');
      expect(service.getRiskLevel(1.0), 'high');
    });
  });

  group('AdvancedRootDetectionService - getThreatDescription', () {
    test('should return correct description for each threat', () {
      expect(
        service.getThreatDescription(ThreatIndicator.suBinary),
        'Superuser binary detected',
      );
      expect(
        service.getThreatDescription(ThreatIndicator.magiskApp),
        'Magisk app detected',
      );
      expect(
        service.getThreatDescription(ThreatIndicator.cydiaApp),
        'Cydia app detected',
      );
      expect(
        service.getThreatDescription(ThreatIndicator.sandboxBreach),
        'Sandbox integrity compromised',
      );
      expect(
        service.getThreatDescription(ThreatIndicator.emulator),
        'Running on emulator/simulator',
      );
    });
  });

  group('RootDetectionResult', () {
    test('should create secure result', () {
      final result = RootDetectionResult.secure();

      expect(result.isCompromised, false);
      expect(result.confidenceScore, 0.0);
      expect(result.detectedThreats, isEmpty);
    });

    test('should create compromised result', () {
      final result = RootDetectionResult.compromised(
        confidenceScore: 0.9,
        threats: [ThreatIndicator.suBinary, ThreatIndicator.magiskApp],
        details: {'reason': 'Root access detected'},
      );

      expect(result.isCompromised, true);
      expect(result.confidenceScore, 0.9);
      expect(result.detectedThreats, hasLength(2));
      expect(result.details, containsPair('reason', 'Root access detected'));
    });

    test('should implement equality correctly', () {
      final now = DateTime.now();
      final result1 = RootDetectionResult(
        isCompromised: true,
        confidenceScore: 0.8,
        detectedThreats: [ThreatIndicator.suBinary],
        details: const {},
        timestamp: now,
      );

      final result2 = RootDetectionResult(
        isCompromised: true,
        confidenceScore: 0.8,
        detectedThreats: [ThreatIndicator.suBinary],
        details: const {},
        timestamp: now,
      );

      expect(result1, equals(result2));
    });
  });
}
