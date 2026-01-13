import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 기기 무결성 상태를 나타내는 Enum
///
/// - secure: 정상적인 기기 (루팅/탈옥 미감지)
/// - rooted: Android 루팅 감지
/// - jailbroken: iOS 탈옥 감지
/// - unknown: 감지 실패 또는 지원하지 않는 플랫폼
enum DeviceIntegrityStatus {
  secure,
  rooted,
  jailbroken,
  unknown,
}

/// 기기 무결성 검사 결과
///
/// [status]: 검사 결과 상태
/// [details]: 감지된 위험 요소들의 상세 목록
/// [riskLevel]: 위험도 (0.0 = 안전, 1.0 = 매우 위험)
class DeviceIntegrityResult {
  final DeviceIntegrityStatus status;
  final List<String> details;
  final double riskLevel;

  const DeviceIntegrityResult({
    required this.status,
    required this.details,
    required this.riskLevel,
  });

  bool get isSecure => status == DeviceIntegrityStatus.secure;
  bool get isCompromised =>
      status == DeviceIntegrityStatus.rooted ||
      status == DeviceIntegrityStatus.jailbroken;

  @override
  String toString() {
    return 'DeviceIntegrityResult(status: $status, riskLevel: $riskLevel, details: $details)';
  }
}

/// 기기 무결성 검사 서비스
///
/// Defense-in-Depth 전략을 적용한 다층 루팅/탈옥 감지:
///
/// **Android 루팅 감지 (Multi-layer)**
/// - Layer 1: su 바이너리 존재 여부 검사
/// - Layer 2: Superuser/Magisk 앱 패키지 감지
/// - Layer 3: 빌드 태그 검사 (test-keys)
/// - Layer 4: 위험 경로 접근 가능 여부
/// - Layer 5: SELinux 상태 검사
///
/// **iOS 탈옥 감지 (Multi-layer)**
/// - Layer 1: 탈옥 앱 존재 여부 (Cydia, Sileo, Zebra)
/// - Layer 2: 탈옥 파일 경로 접근 가능 여부
/// - Layer 3: 샌드박스 무결성 검사 (fork 가능 여부)
/// - Layer 4: 심볼릭 링크 검사
/// - Layer 5: 동적 라이브러리 검사
///
/// **보안 원칙**
/// - Graceful Degradation: 감지 실패 시에도 앱 크래시 없이 처리
/// - 사용자 선택 존중: 루팅 기기에서도 경고 후 사용 가능
/// - 투명성: 감지된 위험 요소를 사용자에게 명확히 표시
///
/// **사용 예시**
/// ```dart
/// final service = DeviceIntegrityService();
/// final result = await service.checkDeviceIntegrity();
///
/// if (result.isCompromised) {
///   showWarningDialog(result);
/// }
/// ```
class DeviceIntegrityService {
  static const MethodChannel _channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/security');

  /// 기기 무결성 종합 검사 수행
  ///
  /// 플랫폼에 따라 적절한 검사를 실행하고 결과를 반환합니다.
  ///
  /// Returns:
  /// - Android: 루팅 감지 결과
  /// - iOS: 탈옥 감지 결과
  /// - 기타 플랫폼: DeviceIntegrityStatus.unknown
  ///
  /// 에러 발생 시 Graceful하게 unknown 상태로 반환하여
  /// 앱 크래시를 방지합니다.
  Future<DeviceIntegrityResult> checkDeviceIntegrity() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidRootStatus();
      } else if (Platform.isIOS) {
        return await _checkIOSJailbreakStatus();
      } else {
        // Web, Desktop 플랫폼은 무결성 검사 미지원
        return const DeviceIntegrityResult(
          status: DeviceIntegrityStatus.unknown,
          details: ['Platform not supported for integrity check'],
          riskLevel: 0.0,
        );
      }
    } on PlatformException catch (e) {
      // 플랫폼 에러 발생 시 로그만 남기고 unknown 반환
      if (kDebugMode) {
        print('Platform error during integrity check: ${e.message}');
      }
      return DeviceIntegrityResult(
        status: DeviceIntegrityStatus.unknown,
        details: ['Integrity check failed: ${e.message}'],
        riskLevel: 0.5, // 검사 실패 자체도 위험 신호일 수 있음
      );
    } catch (e) {
      // 예상치 못한 에러
      if (kDebugMode) {
        print('Unexpected error during integrity check: $e');
      }
      return DeviceIntegrityResult(
        status: DeviceIntegrityStatus.unknown,
        details: ['Unexpected error: $e'],
        riskLevel: 0.5,
      );
    }
  }

  /// Android 루팅 상태 검사
  ///
  /// Native 코드를 통해 다층 검사 수행:
  /// 1. su 바이너리 검사 (RootBeer 스타일)
  /// 2. Superuser 앱 패키지 검사
  /// 3. 빌드 태그 검사
  /// 4. 위험 경로 접근 가능 여부
  /// 5. SELinux 상태
  ///
  /// Returns: 검사 결과와 감지된 위험 요소 목록
  Future<DeviceIntegrityResult> _checkAndroidRootStatus() async {
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('checkRootStatus');

      final bool isRooted = result['isRooted'] as bool? ?? false;
      final List<String> detectedThreats =
          (result['threats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              [];
      final double riskLevel = result['riskLevel'] as double? ?? 0.0;

      return DeviceIntegrityResult(
        status:
            isRooted ? DeviceIntegrityStatus.rooted : DeviceIntegrityStatus.secure,
        details: detectedThreats,
        riskLevel: riskLevel,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Android root check failed: ${e.message}');
      }
      return DeviceIntegrityResult(
        status: DeviceIntegrityStatus.unknown,
        details: ['Root check failed: ${e.message}'],
        riskLevel: 0.5,
      );
    }
  }

  /// iOS 탈옥 상태 검사
  ///
  /// Native 코드를 통해 다층 검사 수행:
  /// 1. 탈옥 앱 존재 여부 (Cydia, Sileo, Zebra)
  /// 2. 탈옥 파일 경로 접근 가능 여부
  /// 3. 샌드박스 무결성 검사 (fork 호출)
  /// 4. 심볼릭 링크 검사
  /// 5. 동적 라이브러리 검사
  ///
  /// Returns: 검사 결과와 감지된 위험 요소 목록
  Future<DeviceIntegrityResult> _checkIOSJailbreakStatus() async {
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('checkJailbreakStatus');

      final bool isJailbroken = result['isJailbroken'] as bool? ?? false;
      final List<String> detectedThreats =
          (result['threats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              [];
      final double riskLevel = result['riskLevel'] as double? ?? 0.0;

      return DeviceIntegrityResult(
        status: isJailbroken
            ? DeviceIntegrityStatus.jailbroken
            : DeviceIntegrityStatus.secure,
        details: detectedThreats,
        riskLevel: riskLevel,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('iOS jailbreak check failed: ${e.message}');
      }
      return DeviceIntegrityResult(
        status: DeviceIntegrityStatus.unknown,
        details: ['Jailbreak check failed: ${e.message}'],
        riskLevel: 0.5,
      );
    }
  }

  /// 빠른 검사 수행 (경량 버전)
  ///
  /// 앱 시작 시 성능 영향을 최소화하기 위한 경량 검사.
  /// 가장 명확한 루팅/탈옥 신호만 체크합니다.
  ///
  /// Use case: 앱 시작 시 백그라운드 검사
  Future<bool> quickCheck() async {
    final result = await checkDeviceIntegrity();
    return result.isCompromised;
  }
}
