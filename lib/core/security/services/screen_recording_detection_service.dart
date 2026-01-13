import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 화면 녹화 상태
enum ScreenRecordingStatus {
  /// 녹화 중이 아님
  notRecording,

  /// 녹화 중
  recording,

  /// 상태 확인 불가
  unknown,
}

/// 화면 녹화 감지 결과
class RecordingStatusEvent {
  /// 녹화 상태
  final ScreenRecordingStatus status;

  /// 상태 변경 시간
  final DateTime timestamp;

  /// 녹화 앱 정보 (감지된 경우)
  final String? recordingApp;

  const RecordingStatusEvent({
    required this.status,
    required this.timestamp,
    this.recordingApp,
  });

  bool get isRecording => status == ScreenRecordingStatus.recording;

  @override
  String toString() {
    return 'RecordingStatusEvent(status: $status, timestamp: $timestamp, '
        'app: $recordingApp)';
  }
}

/// 화면 녹화 감지 서비스
///
/// 사용자가 앱 화면을 녹화하는 것을 실시간으로 감지합니다.
/// 민감한 작업(트랜잭션 서명) 중 화면 녹화를 차단합니다.
///
/// **플랫폼별 구현**
/// - **iOS 11+:**
///   - `UIScreen.isCaptured` 프로퍼티 사용
///   - `UIScreenCapturedDidChangeNotification` 리슨
///   - 실시간 감지 (100% 정확도)
///
/// - **Android:**
///   - `MediaProjection` API 모니터링 (API 21+)
///   - 화면 녹화 앱 프로세스 감지
///   - 정확도: ~80% (우회 가능)
///
/// **보안 전략**
/// - 녹화 감지 시 민감한 화면 즉시 블러 처리
/// - 트랜잭션 서명 차단
/// - 보안 로그 기록
///
/// **사용 예시**
/// ```dart
/// final service = ScreenRecordingDetectionService();
///
/// // 트랜잭션 화면 진입 시
/// final status = await service.isRecordingActive();
/// if (status == ScreenRecordingStatus.recording) {
///   showError('Please stop screen recording');
///   return;
/// }
///
/// service.addRecordingListener((event) {
///   if (event.isRecording) {
///     blurSensitiveContent();
///   }
/// });
/// ```
class ScreenRecordingDetectionService {
  static const MethodChannel _channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/security');

  static const EventChannel _eventChannel = EventChannel(
      'com.etherflow.crypto_wallet_pro/security/screen_recording');

  StreamSubscription<dynamic>? _subscription;
  final List<void Function(RecordingStatusEvent)> _listeners = [];

  /// 현재 화면 녹화 상태 확인
  ///
  /// 현재 시점에 화면이 녹화 중인지 확인합니다.
  ///
  /// Returns [ScreenRecordingStatus]
  Future<ScreenRecordingStatus> isRecordingActive() async {
    try {
      if (Platform.isIOS) {
        final bool? isRecording =
            await _channel.invokeMethod('isScreenRecording');
        if (isRecording == null) {
          return ScreenRecordingStatus.unknown;
        }
        return isRecording
            ? ScreenRecordingStatus.recording
            : ScreenRecordingStatus.notRecording;
      } else if (Platform.isAndroid) {
        final bool? isRecording =
            await _channel.invokeMethod('isScreenRecording');
        if (isRecording == null) {
          return ScreenRecordingStatus.unknown;
        }
        return isRecording
            ? ScreenRecordingStatus.recording
            : ScreenRecordingStatus.notRecording;
      } else {
        return ScreenRecordingStatus.unknown;
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to check recording status: ${e.message}');
      }
      return ScreenRecordingStatus.unknown;
    }
  }

  /// 화면 녹화 상태 변경 리스너 추가
  ///
  /// 녹화 시작/종료 시 [callback]이 호출됩니다.
  ///
  /// **iOS:**
  /// - `UIScreenCapturedDidChangeNotification` 기반
  /// - 즉시 감지 (지연 없음)
  ///
  /// **Android:**
  /// - Polling 기반 (1초 간격)
  /// - 배터리 소모 고려 필요
  void addRecordingListener(void Function(RecordingStatusEvent) callback) {
    _listeners.add(callback);

    // 첫 리스너 추가 시 Native 리스너 활성화
    if (_listeners.length == 1) {
      _startListening();
    }
  }

  /// 화면 녹화 상태 변경 리스너 제거
  ///
  /// 특정 콜백을 제거하거나, 콜백을 지정하지 않으면 모든 리스너를 제거합니다.
  void removeRecordingListener([void Function(RecordingStatusEvent)? callback]) {
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

  /// 화면 녹화 앱 목록 조회 (Android)
  ///
  /// 현재 설치된 화면 녹화 앱 목록을 반환합니다.
  ///
  /// Returns: 패키지 이름 목록
  Future<List<String>> getRecordingApps() async {
    try {
      if (!Platform.isAndroid) {
        return [];
      }

      final List<dynamic>? result =
          await _channel.invokeMethod('getRecordingApps');
      return result?.map((e) => e.toString()).toList() ?? [];
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to get recording apps: ${e.message}');
      }
      return [];
    }
  }

  /// 화면 녹화 감지 지원 여부 확인
  ///
  /// Returns: true if screen recording detection is supported
  Future<bool> isSupported() async {
    try {
      final bool? result =
          await _channel.invokeMethod('isRecordingDetectionSupported');
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
          _handleRecordingEvent(event);
        },
        onError: (dynamic error) {
          if (kDebugMode) {
            print('Recording detection error: $error');
          }
        },
      );

      // Native 측에 감지 시작 요청
      _channel.invokeMethod('startRecordingDetection');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start recording listening: $e');
      }
    }
  }

  /// Native 리스너 중지
  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;

    try {
      _channel.invokeMethod('stopRecordingDetection');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to stop recording listening: $e');
      }
    }
  }

  /// 녹화 상태 변경 이벤트 처리
  void _handleRecordingEvent(dynamic event) {
    try {
      final map = event as Map<dynamic, dynamic>;
      final isRecording = map['isRecording'] as bool? ?? false;
      final recordingApp = map['recordingApp'] as String?;

      final statusEvent = RecordingStatusEvent(
        status: isRecording
            ? ScreenRecordingStatus.recording
            : ScreenRecordingStatus.notRecording,
        timestamp: DateTime.now(),
        recordingApp: recordingApp,
      );

      // 모든 리스너에게 이벤트 전달
      for (final listener in _listeners) {
        listener(statusEvent);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to handle recording event: $e');
      }
    }
  }

  /// 리소스 정리
  void dispose() {
    removeRecordingListener();
  }
}
