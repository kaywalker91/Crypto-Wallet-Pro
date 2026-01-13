import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 오버레이 공격 방지 서비스 (Android)
///
/// Android의 SYSTEM_ALERT_WINDOW 권한을 가진 악성 앱이
/// 지갑 앱 위에 페이크 UI를 오버레이하여 프라이빗 키나
/// 트랜잭션 정보를 탈취하는 공격을 방지합니다.
///
/// **공격 시나리오**
/// 1. 악성 앱이 SYSTEM_ALERT_WINDOW 권한을 획득
/// 2. 지갑 앱의 송금 화면 위에 가짜 수신자 주소를 오버레이
/// 3. 사용자는 정상 화면으로 착각하고 트랜잭션 서명
/// 4. 실제로는 공격자의 주소로 자산 전송됨
///
/// **방어 메커니즘**
/// - Android API 23+: `getSystemService(OVERLAY_SERVICE)` 체크
/// - 민감한 작업 시 Strict Mode 활성화
/// - 오버레이 감지 시 트랜잭션 차단
///
/// **사용 예시**
/// ```dart
/// final service = OverlayProtectionService();
///
/// // 트랜잭션 서명 전
/// final status = await service.checkOverlayStatus();
/// if (!status.isSafe) {
///   showWarning('Overlay detected!');
///   return;
/// }
///
/// await service.enableStrictMode();
/// await signTransaction();
/// await service.disableStrictMode();
/// ```
class OverlayProtectionService {
  static const MethodChannel _channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/security');

  /// 현재 오버레이 상태 확인
  ///
  /// Returns [OverlayStatus] - 오버레이 감지 여부와 상세 정보
  ///
  /// **Android:**
  /// - 다른 앱의 오버레이 윈도우 감지
  /// - SYSTEM_ALERT_WINDOW 권한을 가진 앱 목록
  ///
  /// **iOS:**
  /// - 항상 안전 (샌드박스로 인해 오버레이 불가)
  ///
  /// **기타 플랫폼:**
  /// - OverlayStatus.unknown 반환
  Future<OverlayStatus> checkOverlayStatus() async {
    try {
      if (Platform.isAndroid) {
        final Map<dynamic, dynamic> result =
            await _channel.invokeMethod('checkOverlayStatus');

        final bool hasOverlay = result['hasOverlay'] as bool? ?? false;
        final List<String> suspiciousApps =
            (result['suspiciousApps'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
        final double threatLevel = result['threatLevel'] as double? ?? 0.0;

        return OverlayStatus(
          hasOverlay: hasOverlay,
          suspiciousApps: suspiciousApps,
          threatLevel: threatLevel,
        );
      } else if (Platform.isIOS) {
        // iOS는 샌드박스로 인해 오버레이 공격 불가
        return const OverlayStatus(
          hasOverlay: false,
          suspiciousApps: [],
          threatLevel: 0.0,
        );
      } else {
        // Web, Desktop 등
        return const OverlayStatus(
          hasOverlay: false,
          suspiciousApps: [],
          threatLevel: 0.0,
          isSupported: false,
        );
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Overlay status check failed: ${e.message}');
      }
      return OverlayStatus(
        hasOverlay: false,
        suspiciousApps: [],
        threatLevel: 0.5,
        errorMessage: e.message,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in overlay check: $e');
      }
      return OverlayStatus(
        hasOverlay: false,
        suspiciousApps: [],
        threatLevel: 0.5,
        errorMessage: e.toString(),
      );
    }
  }

  /// Strict Mode 활성화
  ///
  /// 민감한 작업(트랜잭션 서명, 프라이빗 키 표시) 시
  /// 오버레이를 엄격하게 차단합니다.
  ///
  /// **Android 동작:**
  /// - `setFilterTouchesWhenObscured(true)` 설정
  /// - 오버레이 감지 시 터치 이벤트 차단
  /// - 사용자에게 경고 표시
  ///
  /// Returns: true if strict mode was enabled successfully
  Future<bool> enableStrictMode() async {
    try {
      if (!Platform.isAndroid) {
        // Android 외 플랫폼은 no-op
        return true;
      }

      final result =
          await _channel.invokeMethod<bool>('enableOverlayStrictMode');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to enable overlay strict mode: ${e.message}');
      }
      return false;
    }
  }

  /// Strict Mode 비활성화
  ///
  /// 민감한 작업 완료 후 일반 모드로 복귀합니다.
  ///
  /// Returns: true if strict mode was disabled successfully
  Future<bool> disableStrictMode() async {
    try {
      if (!Platform.isAndroid) {
        return true;
      }

      final result =
          await _channel.invokeMethod<bool>('disableOverlayStrictMode');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to disable overlay strict mode: ${e.message}');
      }
      return false;
    }
  }

  /// 오버레이 권한을 가진 앱 목록 조회 (Android)
  ///
  /// SYSTEM_ALERT_WINDOW 권한을 가진 모든 앱을 나열합니다.
  /// 사용자가 의심스러운 앱을 식별하는 데 도움을 줍니다.
  ///
  /// Returns: 패키지 이름 목록
  Future<List<String>> getAppsWithOverlayPermission() async {
    try {
      if (!Platform.isAndroid) {
        return [];
      }

      final List<dynamic>? result =
          await _channel.invokeMethod('getAppsWithOverlayPermission');

      return result?.map((e) => e.toString()).toList() ?? [];
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to get apps with overlay permission: ${e.message}');
      }
      return [];
    }
  }
}

/// 오버레이 상태 정보
class OverlayStatus {
  /// 오버레이가 감지되었는지
  final bool hasOverlay;

  /// 의심스러운 앱 목록 (패키지 이름)
  final List<String> suspiciousApps;

  /// 위협 수준 (0.0 = 안전, 1.0 = 매우 위험)
  final double threatLevel;

  /// 플랫폼이 오버레이 감지를 지원하는지
  final bool isSupported;

  /// 에러 메시지 (검사 실패 시)
  final String? errorMessage;

  const OverlayStatus({
    required this.hasOverlay,
    required this.suspiciousApps,
    required this.threatLevel,
    this.isSupported = true,
    this.errorMessage,
  });

  /// 트랜잭션 서명에 안전한지
  bool get isSafe => !hasOverlay && threatLevel < 0.3;

  /// 경고가 필요한지
  bool get requiresWarning => hasOverlay || threatLevel >= 0.5;

  @override
  String toString() {
    return 'OverlayStatus(hasOverlay: $hasOverlay, '
        'threatLevel: $threatLevel, suspiciousApps: $suspiciousApps)';
  }
}
