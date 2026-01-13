import 'package:crypto_wallet_pro/core/security/services/tamper_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TamperDetectionService service;

  setUp(() {
    service = TamperDetectionService();
  });

  group('TamperDetectionService - Debug Mode', () {
    // 디버그 모드에서는 대부분의 검사가 통과됨
    test('verifyAppIntegrity should pass in debug mode', () async {
      final result = await service.verifyAppIntegrity();

      // 디버그 모드에서는 서명, 코드, 디버거, 후킹 검사가 통과됨
      expect(result.isIntact, true);
      expect(result.violations, isEmpty);
      expect(result.riskLevel, 0.0);
    });

    test('verifyAppSignature should return true in debug mode', () async {
      final result = await service.verifyAppSignature();
      expect(result, true);
    });

    test('verifyCodeIntegrity should return true in debug mode', () async {
      final result = await service.verifyCodeIntegrity();
      expect(result, true);
    });

    test('getAppSignature should return platform-specific value', () async {
      final signature = await service.getAppSignature();
      // Non-mobile 플랫폼에서는 'UNSUPPORTED_PLATFORM' 반환
      expect(signature, isNotEmpty);
    });
  });

  group('TamperDetectionResult', () {
    test('should report no critical violations when intact', () {
      final result = TamperDetectionResult(
        isIntact: true,
        violations: [],
        riskLevel: 0.0,
        timestamp: DateTime.now(),
      );

      expect(result.hasCriticalViolations, false);
      expect(result.isSafeForSigning, true);
    });

    test('should report critical violations for invalid signature', () {
      final result = TamperDetectionResult(
        isIntact: false,
        violations: [
          const TamperViolation(
            type: TamperViolationType.invalidSignature,
            description: 'Invalid signature',
            severity: 1.0,
          ),
        ],
        riskLevel: 1.0,
        timestamp: DateTime.now(),
      );

      expect(result.hasCriticalViolations, true);
      expect(result.isSafeForSigning, false);
    });

    test('should report critical violations for code modification', () {
      final result = TamperDetectionResult(
        isIntact: false,
        violations: [
          const TamperViolation(
            type: TamperViolationType.codeModified,
            description: 'Code modified',
            severity: 0.9,
          ),
        ],
        riskLevel: 0.9,
        timestamp: DateTime.now(),
      );

      expect(result.hasCriticalViolations, true);
      expect(result.isSafeForSigning, false);
    });

    test('should not report critical violations for debugger', () {
      final result = TamperDetectionResult(
        isIntact: false,
        violations: [
          const TamperViolation(
            type: TamperViolationType.debuggerAttached,
            description: 'Debugger attached',
            severity: 0.8,
          ),
        ],
        riskLevel: 0.8,
        timestamp: DateTime.now(),
      );

      expect(result.hasCriticalViolations, false);
      expect(result.isSafeForSigning, false); // still not intact
    });

    test('should have correct toString', () {
      final result = TamperDetectionResult(
        isIntact: true,
        violations: [],
        riskLevel: 0.0,
        timestamp: DateTime.now(),
      );

      expect(result.toString(),
          'TamperDetectionResult(isIntact: true, riskLevel: 0.0, violations: 0)');
    });
  });

  group('TamperViolationType', () {
    test('should have all expected values', () {
      expect(TamperViolationType.values, contains(TamperViolationType.invalidSignature));
      expect(TamperViolationType.values, contains(TamperViolationType.codeModified));
      expect(TamperViolationType.values, contains(TamperViolationType.debuggerAttached));
      expect(TamperViolationType.values, contains(TamperViolationType.runningOnEmulator));
      expect(TamperViolationType.values, contains(TamperViolationType.hookingFrameworkDetected));
      expect(TamperViolationType.values, contains(TamperViolationType.unknown));
    });
  });

  group('TamperViolation', () {
    test('should create violation with correct values', () {
      const violation = TamperViolation(
        type: TamperViolationType.invalidSignature,
        description: 'Test description',
        severity: 0.9,
      );

      expect(violation.type, TamperViolationType.invalidSignature);
      expect(violation.description, 'Test description');
      expect(violation.severity, 0.9);
    });

    test('should have correct toString', () {
      const violation = TamperViolation(
        type: TamperViolationType.codeModified,
        description: 'Test',
        severity: 0.8,
      );

      expect(violation.toString(),
          'TamperViolation(type: TamperViolationType.codeModified, severity: 0.8)');
    });
  });
}
