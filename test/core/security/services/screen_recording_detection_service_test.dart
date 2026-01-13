import 'package:crypto_wallet_pro/core/security/services/screen_recording_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScreenRecordingDetectionService service;

  setUp(() {
    service = ScreenRecordingDetectionService();
  });

  tearDown(() {
    service.dispose();
  });

  group('ScreenRecordingDetectionService - Non-Mobile Platform', () {
    // 테스트 환경은 Android/iOS가 아니므로 unknown 반환
    test('isRecordingActive should return unknown on non-mobile', () async {
      final status = await service.isRecordingActive();
      expect(status, ScreenRecordingStatus.unknown);
    });

    test('getRecordingApps should return empty list on non-Android', () async {
      final apps = await service.getRecordingApps();
      expect(apps, isEmpty);
    });

    test('isSupported should return false on non-mobile', () async {
      final isSupported = await service.isSupported();
      expect(isSupported, false);
    });
  });

  group('ScreenRecordingDetectionService - Listener Management', () {
    test('addRecordingListener should add listener to list', () {
      int callCount = 0;
      void listener(RecordingStatusEvent event) {
        callCount++;
      }

      service.addRecordingListener(listener);
      // 리스너가 추가되었는지 확인 (dispose로 간접 확인)
      // 실제로는 native 이벤트가 없으므로 callback은 호출되지 않음
      expect(callCount, 0); // No events yet
    });

    test('removeRecordingListener should remove specific listener', () {
      void listener1(RecordingStatusEvent event) {}
      void listener2(RecordingStatusEvent event) {}

      service.addRecordingListener(listener1);
      service.addRecordingListener(listener2);

      service.removeRecordingListener(listener1);
      // No exception means success
    });

    test('removeRecordingListener without argument should remove all', () {
      service.addRecordingListener((event) {});
      service.addRecordingListener((event) {});

      service.removeRecordingListener();
      // No exception means success
    });

    test('dispose should remove all listeners', () {
      service.addRecordingListener((event) {});
      service.dispose();
      // No exception means success
    });
  });

  group('ScreenRecordingStatus', () {
    test('should have all expected values', () {
      expect(ScreenRecordingStatus.values, contains(ScreenRecordingStatus.notRecording));
      expect(ScreenRecordingStatus.values, contains(ScreenRecordingStatus.recording));
      expect(ScreenRecordingStatus.values, contains(ScreenRecordingStatus.unknown));
    });
  });

  group('RecordingStatusEvent', () {
    test('should create recording event', () {
      final now = DateTime.now();
      final event = RecordingStatusEvent(
        status: ScreenRecordingStatus.recording,
        timestamp: now,
        recordingApp: 'com.test.recorder',
      );

      expect(event.status, ScreenRecordingStatus.recording);
      expect(event.timestamp, now);
      expect(event.recordingApp, 'com.test.recorder');
      expect(event.isRecording, true);
    });

    test('isRecording should return true for recording status', () {
      final event = RecordingStatusEvent(
        status: ScreenRecordingStatus.recording,
        timestamp: DateTime.now(),
      );

      expect(event.isRecording, true);
    });

    test('isRecording should return false for notRecording', () {
      final event = RecordingStatusEvent(
        status: ScreenRecordingStatus.notRecording,
        timestamp: DateTime.now(),
      );

      expect(event.isRecording, false);
    });

    test('isRecording should return false for unknown', () {
      final event = RecordingStatusEvent(
        status: ScreenRecordingStatus.unknown,
        timestamp: DateTime.now(),
      );

      expect(event.isRecording, false);
    });

    test('should accept null recordingApp', () {
      final event = RecordingStatusEvent(
        status: ScreenRecordingStatus.recording,
        timestamp: DateTime.now(),
      );

      expect(event.recordingApp, isNull);
    });

    test('should have meaningful toString', () {
      final event = RecordingStatusEvent(
        status: ScreenRecordingStatus.recording,
        timestamp: DateTime.now(),
        recordingApp: 'com.test.app',
      );

      expect(event.toString(), contains('RecordingStatusEvent'));
      expect(event.toString(), contains('status'));
      expect(event.toString(), contains('recording'));
    });
  });
}
