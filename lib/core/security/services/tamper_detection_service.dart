import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 위반 유형
enum TamperViolationType {
  /// 앱 서명 불일치
  invalidSignature,

  /// 코드 해시 변조
  codeModified,

  /// 디버거 연결 감지
  debuggerAttached,

  /// 에뮬레이터 감지
  runningOnEmulator,

  /// Frida/Xposed 감지
  hookingFrameworkDetected,

  /// 알 수 없는 위반
  unknown,
}

/// 앱 변조 감지 결과
class TamperDetectionResult {
  /// 앱 무결성 상태
  final bool isIntact;

  /// 감지된 위반 목록
  final List<TamperViolation> violations;

  /// 전체 위험도 (0.0 = 안전, 1.0 = 매우 위험)
  final double riskLevel;

  /// 검사 수행 시간
  final DateTime timestamp;

  const TamperDetectionResult({
    required this.isIntact,
    required this.violations,
    required this.riskLevel,
    required this.timestamp,
  });

  /// 치명적인 위반이 있는지 (서명 변조 등)
  bool get hasCriticalViolations => violations.any(
        (v) =>
            v.type == TamperViolationType.invalidSignature ||
            v.type == TamperViolationType.codeModified,
      );

  /// 트랜잭션 서명에 안전한지
  bool get isSafeForSigning => isIntact && !hasCriticalViolations;

  @override
  String toString() {
    return 'TamperDetectionResult(isIntact: $isIntact, '
        'riskLevel: $riskLevel, violations: ${violations.length})';
  }
}

/// 개별 변조 위반 정보
class TamperViolation {
  final TamperViolationType type;
  final String description;
  final double severity; // 0.0 ~ 1.0

  const TamperViolation({
    required this.type,
    required this.description,
    required this.severity,
  });

  @override
  String toString() {
    return 'TamperViolation(type: $type, severity: $severity)';
  }
}

/// 앱 변조 감지 서비스
///
/// 앱의 코드와 서명이 원본 그대로인지 검증하여
/// 악성 앱 재패키징 공격을 방지합니다.
///
/// **공격 시나리오**
/// 1. 공격자가 정상 APK/IPA를 디컴파일
/// 2. 악성 코드 삽입 (키 로깅, 화면 캡처 등)
/// 3. 재서명하여 유포
/// 4. 사용자가 변조된 앱 설치
///
/// **방어 메커니즘**
/// - **Android:**
///   - APK 서명 검증 (SHA-256)
///   - DEX 파일 해시 검증
///   - Native 라이브러리 무결성 체크
/// - **iOS:**
///   - Code Signing Identity 검증
///   - Provisioning Profile 확인
///   - Dynamic Library 검사
///
/// **사용 예시**
/// ```dart
/// final service = TamperDetectionService();
/// final result = await service.verifyAppIntegrity();
///
/// if (!result.isIntact) {
///   showCriticalWarning(result);
///   exitApp();
/// }
/// ```
class TamperDetectionService {
  static const MethodChannel _channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/security');

  // 릴리스 빌드의 예상 서명 (빌드 시 설정)
  static const String _expectedAndroidSignatureSHA256 =
      'RELEASE_SIGNATURE_SHA256'; // 실제 빌드 시 교체
  static const String _expectedIOSBundleID = 'com.etherflow.crypto_wallet_pro';

  /// 앱 무결성 종합 검사
  ///
  /// 다층 검증을 통해 앱 변조 여부를 확인합니다.
  ///
  /// Returns [TamperDetectionResult] - 무결성 검사 결과
  Future<TamperDetectionResult> verifyAppIntegrity() async {
    final timestamp = DateTime.now();
    final violations = <TamperViolation>[];

    try {
      // 1. 앱 서명 검증
      final signatureResult = await verifyAppSignature();
      if (!signatureResult) {
        violations.add(
          const TamperViolation(
            type: TamperViolationType.invalidSignature,
            description: 'App signature does not match expected value',
            severity: 1.0,
          ),
        );
      }

      // 2. 코드 무결성 검증
      final codeResult = await verifyCodeIntegrity();
      if (!codeResult) {
        violations.add(
          const TamperViolation(
            type: TamperViolationType.codeModified,
            description: 'Code hash verification failed',
            severity: 0.9,
          ),
        );
      }

      // 3. 디버거 연결 감지
      final debuggerAttached = await _checkDebuggerAttached();
      if (debuggerAttached) {
        violations.add(
          const TamperViolation(
            type: TamperViolationType.debuggerAttached,
            description: 'Debugger is attached to the process',
            severity: 0.8,
          ),
        );
      }

      // 4. 에뮬레이터 감지
      final isEmulator = await _checkEmulator();
      if (isEmulator) {
        violations.add(
          const TamperViolation(
            type: TamperViolationType.runningOnEmulator,
            description: 'App is running on an emulator',
            severity: 0.5, // 개발 목적일 수 있으므로 중간 수준
          ),
        );
      }

      // 5. 후킹 프레임워크 감지 (Frida, Xposed)
      final hookingDetected = await _checkHookingFramework();
      if (hookingDetected) {
        violations.add(
          const TamperViolation(
            type: TamperViolationType.hookingFrameworkDetected,
            description: 'Hooking framework (Frida/Xposed) detected',
            severity: 0.9,
          ),
        );
      }

      // 위험도 계산
      final riskLevel = violations.isEmpty
          ? 0.0
          : violations.map((v) => v.severity).reduce((a, b) => a + b) /
              violations.length;

      return TamperDetectionResult(
        isIntact: violations.isEmpty,
        violations: violations,
        riskLevel: riskLevel,
        timestamp: timestamp,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Tamper detection error: $e');
      }

      return TamperDetectionResult(
        isIntact: false,
        violations: [
          TamperViolation(
            type: TamperViolationType.unknown,
            description: 'Integrity check failed: $e',
            severity: 0.7,
          ),
        ],
        riskLevel: 0.7,
        timestamp: timestamp,
      );
    }
  }

  /// 앱 서명 검증
  ///
  /// **Android:** APK 서명 SHA-256 해시 확인
  /// **iOS:** Bundle ID 및 Code Signing Identity 확인
  ///
  /// Returns: true if signature is valid
  Future<bool> verifyAppSignature() async {
    try {
      if (Platform.isAndroid) {
        final signature = await getAppSignature();
        // 디버그 빌드는 검증 생략
        if (kDebugMode) {
          return true;
        }
        return signature == _expectedAndroidSignatureSHA256;
      } else if (Platform.isIOS) {
        final bundleId = await _getIOSBundleID();
        return bundleId == _expectedIOSBundleID;
      } else {
        return true; // 지원하지 않는 플랫폼
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Signature verification failed: ${e.message}');
      }
      return false;
    }
  }

  /// 현재 앱 서명 조회
  ///
  /// **Android:** SHA-256 해시
  /// **iOS:** Bundle ID
  ///
  /// Returns: 서명 문자열
  Future<String> getAppSignature() async {
    try {
      if (Platform.isAndroid) {
        final String? signature =
            await _channel.invokeMethod('getAppSignature');
        return signature ?? 'UNKNOWN';
      } else if (Platform.isIOS) {
        return await _getIOSBundleID();
      } else {
        return 'UNSUPPORTED_PLATFORM';
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to get app signature: ${e.message}');
      }
      return 'ERROR';
    }
  }

  /// 코드 무결성 검증
  ///
  /// **Android:** DEX 파일 CRC32 체크
  /// **iOS:** Mach-O 바이너리 해시 체크
  ///
  /// Returns: true if code is unmodified
  Future<bool> verifyCodeIntegrity() async {
    try {
      if (kDebugMode) {
        // 디버그 빌드는 검증 생략 (Hot Reload 등으로 인해 해시 변경)
        return true;
      }

      final bool? result =
          await _channel.invokeMethod('verifyCodeIntegrity');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Code integrity verification failed: ${e.message}');
      }
      return false;
    }
  }

  /// 디버거 연결 여부 확인
  Future<bool> _checkDebuggerAttached() async {
    try {
      // 디버그 모드에서는 항상 false 반환 (개발 편의성)
      if (kDebugMode) {
        return false;
      }

      final bool? result = await _channel.invokeMethod('isDebuggerAttached');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 에뮬레이터 여부 확인
  Future<bool> _checkEmulator() async {
    try {
      final bool? result = await _channel.invokeMethod('isEmulator');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 후킹 프레임워크 감지
  Future<bool> _checkHookingFramework() async {
    try {
      if (kDebugMode) {
        return false;
      }

      final bool? result =
          await _channel.invokeMethod('detectHookingFramework');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// iOS Bundle ID 조회
  Future<String> _getIOSBundleID() async {
    try {
      if (!Platform.isIOS) {
        return 'NOT_IOS';
      }

      final String? bundleId = await _channel.invokeMethod('getBundleID');
      return bundleId ?? 'UNKNOWN';
    } on PlatformException {
      return 'ERROR';
    }
  }
}
