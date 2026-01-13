import 'package:crypto_wallet_pro/core/security/services/screenshot_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScreenshotDetectionService service;

  setUp(() {
    service = ScreenshotDetectionService();
  });

  tearDown(() {
    service.dispose();
  });

  group('ScreenshotDetectionService - Non-Mobile Platform', () {
    // 테스트 환경은 Android/iOS가 아니므로 빈 결과/false 반환
    test('getRecentScreenshots should return empty list on non-mobile', () async {
      final screenshots = await service.getRecentScreenshots();
      expect(screenshots, isEmpty);
    });

    test('isSupported should return false on non-mobile', () async {
      final isSupported = await service.isSupported();
      expect(isSupported, false);
    });
  });

  group('ScreenshotDetectionService - Listener Management', () {
    test('addScreenshotListener should add listener', () {
      int callCount = 0;
      void listener(ScreenshotEvent event) {
        callCount++;
      }

      service.addScreenshotListener(listener);
      expect(callCount, 0); // No events yet
    });

    test('removeScreenshotListener should remove specific listener', () {
      void listener1(ScreenshotEvent event) {}
      void listener2(ScreenshotEvent event) {}

      service.addScreenshotListener(listener1);
      service.addScreenshotListener(listener2);

      service.removeScreenshotListener(listener1);
      // No exception means success
    });

    test('removeScreenshotListener without argument should remove all', () {
      service.addScreenshotListener((event) {});
      service.addScreenshotListener((event) {});

      service.removeScreenshotListener();
      // No exception means success
    });

    test('dispose should remove all listeners', () {
      service.addScreenshotListener((event) {});
      service.dispose();
      // No exception means success
    });
  });

  group('ScreenshotEvent', () {
    test('should create screenshot event with all properties', () {
      final now = DateTime.now();
      final event = ScreenshotEvent(
        filePath: '/test/path.png',
        timestamp: now,
        metadata: {'width': 1080, 'height': 1920},
      );

      expect(event.filePath, '/test/path.png');
      expect(event.timestamp, now);
      expect(event.metadata['width'], 1080);
      expect(event.metadata['height'], 1920);
    });

    test('should create screenshot event with null filePath', () {
      final now = DateTime.now();
      final event = ScreenshotEvent(
        timestamp: now,
      );

      expect(event.filePath, isNull);
      expect(event.timestamp, now);
    });

    test('should create screenshot event with empty metadata', () {
      final event = ScreenshotEvent(
        filePath: '/test/path.png',
        timestamp: DateTime.now(),
        metadata: {},
      );

      expect(event.metadata, isEmpty);
    });

    test('should have meaningful toString', () {
      final event = ScreenshotEvent(
        filePath: '/test/path.png',
        timestamp: DateTime.now(),
      );

      expect(event.toString(), contains('ScreenshotEvent'));
      expect(event.toString(), contains('timestamp'));
    });
  });
}
