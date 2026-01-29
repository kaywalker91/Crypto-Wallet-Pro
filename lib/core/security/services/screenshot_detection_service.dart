import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 스크린샷 감지 결과
class ScreenshotEvent {
  /// 스크린샷 파일 경로 (가능한 경우)
  final String? filePath;

  /// 감지 시간
  final DateTime timestamp;

  /// 플랫폼별 메타데이터
  final Map<String, dynamic> metadata;

  const ScreenshotEvent({
    this.filePath,
    required this.timestamp,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'ScreenshotEvent(timestamp: $timestamp, filePath: $filePath)';
  }
}

/// 스크린샷 감지 서비스
///
/// 사용자가 앱 화면을 스크린샷으로 캡처하는 것을 실시간으로 감지합니다.
/// 민감한 정보(프라이빗 키, 시드 구문)가 노출된 상태에서
/// 스크린샷이 촬영되면 보안 로그를 남기고 사용자에게 경고합니다.
///
/// **플랫폼별 구현**
/// - **iOS:**
///   - `UIApplicationUserDidTakeScreenshotNotification` 리슨
///   - 실시간 이벤트 전달 (Photos 접근 권한 불필요)
///
/// - **Android:**
///   - MediaStore 변경 모니터링
///   - `FileObserver` 사용
///   - READ_EXTERNAL_STORAGE 권한 필요
///
/// **보안 원칙**
/// - 스크린샷을 방지하지 않음 (사용자 불편)
/// - 감지 후 보안 로그 기록 및 경고
/// - 민감한 화면에서만 리스너 활성화
///
/// **사용 예시**
/// ```dart
/// final service = ScreenshotDetectionService();
///
/// // 민감한 화면 진입 시
/// service.addScreenshotListener((event) {
///   logSecurityEvent('Screenshot taken: ${event.timestamp}');
///   showWarning('Please delete the screenshot for security');
/// });
///
/// // 화면 이탈 시
/// service.removeScreenshotListener();
/// ```
class ScreenshotDetectionService {
  static const MethodChannel _channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/security');

  static const EventChannel _eventChannel =
      EventChannel('com.etherflow.crypto_wallet_pro/security/screenshot');

  StreamSubscription<dynamic>? _subscription;
  final List<void Function(ScreenshotEvent)> _listeners = [];

  /// 스크린샷 감지 리스너 추가
  ///
  /// [callback]은 스크린샷이 감지될 때마다 호출됩니다.
  ///
  /// **주의:**
  /// - 민감한 화면에서만 활성화하세요 (배터리/성능 고려)
  /// - 화면 이탈 시 반드시 [removeScreenshotListener] 호출
  void addScreenshotListener(void Function(ScreenshotEvent) callback) {
    _listeners.add(callback);

    // 첫 리스너 추가 시 Native 리스너 활성화
    if (_listeners.length == 1) {
      _startListening();
    }
  }

  /// 스크린샷 감지 리스너 제거
  ///
  /// 특정 콜백을 제거하거나, 콜백을 지정하지 않으면 모든 리스너를 제거합니다.
  void removeScreenshotListener([void Function(ScreenshotEvent)? callback]) {
    if (callback != null) {
      _listeners.remove(callback);
    } else {
      _listeners.clear();
    }

    // 모든 리스너 제거 시 Native 리스너 비활성화
    if (_listeners.isEmpty) {
      _stopListening();
    }
  }

  /// 최근 스크린샷 목록 조회
  ///
  /// [duration] 기간 내에 촬영된 스크린샷 목록을 반환합니다.
  ///
  /// **Android:**
  /// - MediaStore 쿼리
  /// - READ_EXTERNAL_STORAGE 권한 필요
  ///
  /// **iOS:**
  /// - Photos Framework 사용
  /// - Photos 접근 권한 필요
  ///
  /// Returns: 스크린샷 이벤트 목록
  Future<List<ScreenshotEvent>> getRecentScreenshots({
    Duration duration = const Duration(minutes: 5),
  }) async {
    try {
      final List<dynamic>? result =
          await _channel.invokeMethod('getRecentScreenshots', {
        'durationMillis': duration.inMilliseconds,
      });

      if (result == null) {
        return [];
      }

      return result.map((item) {
        final map = item as Map<dynamic, dynamic>;
        return ScreenshotEvent(
          filePath: map['filePath'] as String?,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            map['timestamp'] as int,
          ),
          metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        );
      }).toList();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to get recent screenshots: ${e.message}');
      }
      return [];
    }
  }

  /// 스크린샷 감지 지원 여부 확인
  ///
  /// Returns: true if screenshot detection is supported on this platform
  Future<bool> isSupported() async {
    try {
      final bool? result =
          await _channel.invokeMethod('isScreenshotDetectionSupported');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Native 리스너 시작
  void _startListening() {
    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          _handleScreenshotEvent(event);
        },
        onError: (dynamic error) {
          if (kDebugMode) {
            print('Screenshot detection error: $error');
          }
        },
      );

      // Native 측에 감지 시작 요청
      _channel.invokeMethod('startScreenshotDetection');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start screenshot listening: $e');
      }
    }
  }

  /// Native 리스너 중지
  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;

    try {
      _channel.invokeMethod('stopScreenshotDetection');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to stop screenshot listening: $e');
      }
    }
  }

  /// 스크린샷 이벤트 처리
  void _handleScreenshotEvent(dynamic event) {
    try {
      final map = event as Map<dynamic, dynamic>;
      final screenshotEvent = ScreenshotEvent(
        filePath: map['filePath'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );

      // 모든 리스너에게 이벤트 전달
      for (final listener in _listeners) {
        listener(screenshotEvent);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to handle screenshot event: $e');
      }
    }
  }

  /// 리소스 정리
  void dispose() {
    removeScreenshotListener();
  }
}
