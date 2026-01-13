import 'package:crypto_wallet_pro/core/security/services/enhanced_biometric_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'enhanced_biometric_service_test.mocks.dart';

@GenerateMocks([LocalAuthentication])
void main() {
  late EnhancedBiometricService service;
  late MockLocalAuthentication mockLocalAuth;

  setUp(() {
    mockLocalAuth = MockLocalAuthentication();
    service = EnhancedBiometricService(
      mockLocalAuth,
      sessionDuration: const Duration(minutes: 3),
    );
  });

  group('EnhancedBiometricService', () {
    group('canCheck', () {
      test('디바이스가 생체인증을 지원하면 true 반환', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);

        // Act
        final result = await service.canCheck();

        // Assert
        expect(result, true);
        verify(mockLocalAuth.isDeviceSupported()).called(1);
        verify(mockLocalAuth.canCheckBiometrics).called(1);
      });

      test('디바이스가 생체인증을 지원하지 않으면 false 반환', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);

        // Act
        final result = await service.canCheck();

        // Assert
        expect(result, false);
        verify(mockLocalAuth.isDeviceSupported()).called(1);
        verify(mockLocalAuth.canCheckBiometrics).called(1);
      });

      test('생체정보가 등록되지 않으면 false 반환', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);

        // Act
        final result = await service.canCheck();

        // Assert
        expect(result, false);
        verify(mockLocalAuth.isDeviceSupported()).called(1);
        verify(mockLocalAuth.canCheckBiometrics).called(1);
      });
    });

    group('getAvailableBiometrics', () {
      test('사용 가능한 생체인증 유형 반환', () async {
        // Arrange
        const expectedTypes = [BiometricType.face, BiometricType.fingerprint];
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => expectedTypes);

        // Act
        final result = await service.getAvailableBiometrics();

        // Assert
        expect(result, expectedTypes);
        verify(mockLocalAuth.getAvailableBiometrics()).called(1);
      });

      test('생체인증 사용 불가 시 빈 리스트 반환', () async {
        // Arrange
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => []);

        // Act
        final result = await service.getAvailableBiometrics();

        // Assert
        expect(result, isEmpty);
        verify(mockLocalAuth.getAvailableBiometrics()).called(1);
      });

      test('오류 발생 시 빈 리스트 반환', () async {
        // Arrange
        when(mockLocalAuth.getAvailableBiometrics())
            .thenThrow(Exception('Biometric error'));

        // Act
        final result = await service.getAvailableBiometrics();

        // Assert
        expect(result, isEmpty);
        verify(mockLocalAuth.getAvailableBiometrics()).called(1);
      });
    });

    group('authenticate', () {
      test('생체인증 성공 시 true 반환 및 세션 시작', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await service.authenticate(reason: 'Test authentication');

        // Assert
        expect(result, true);
        expect(service.hasValidSession, true);
        verify(mockLocalAuth.authenticate(
          localizedReason: 'Test authentication',
          options: anyNamed('options'),
        )).called(1);
      });

      test('생체인증 실패 시 false 반환 및 세션 시작 안 함', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => false);

        // Act
        final result = await service.authenticate();

        // Assert
        expect(result, false);
        expect(service.hasValidSession, false);
        verify(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).called(1);
      });

      test('생체인증 사용 불가 시 false 반환', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);

        // Act
        final result = await service.authenticate();

        // Assert
        expect(result, false);
        verifyNever(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        ));
      });
    });

    group('ensureAuthenticated', () {
      test('유효한 세션이 있으면 true 반환 (재인증 안 함)', () async {
        // Arrange
        // 먼저 세션 시작
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        await service.authenticate();
        clearInteractions(mockLocalAuth);

        // Act
        final result = await service.ensureAuthenticated();

        // Assert
        expect(result, true);
        verifyNever(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        ));
      });

      test('세션이 없으면 생체인증 수행', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await service.ensureAuthenticated();

        // Assert
        expect(result, true);
        verify(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).called(1);
      });

      test('forceAuth가 true이면 세션이 있어도 재인증', () async {
        // Arrange
        // 먼저 세션 시작
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        await service.authenticate();
        clearInteractions(mockLocalAuth);

        // 재인증 설정
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await service.ensureAuthenticated(forceAuth: true);

        // Assert
        expect(result, true);
        verify(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).called(1);
      });
    });

    group('invalidateSession', () {
      test('세션 무효화', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        await service.authenticate();
        expect(service.hasValidSession, true);

        // Act
        service.invalidateSession();

        // Assert
        expect(service.hasValidSession, false);
      });
    });

    group('getPrimaryBiometricType', () {
      test('Face ID가 있으면 Face ID 반환 (최우선)', () async {
        // Arrange
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [
            BiometricType.fingerprint,
            BiometricType.face,
            BiometricType.iris,
          ],
        );

        // Act
        final result = await service.getPrimaryBiometricType();

        // Assert
        expect(result, BiometricType.face);
      });

      test('Face ID가 없고 지문이 있으면 지문 반환', () async {
        // Arrange
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [
            BiometricType.fingerprint,
            BiometricType.iris,
          ],
        );

        // Act
        final result = await service.getPrimaryBiometricType();

        // Assert
        expect(result, BiometricType.fingerprint);
      });

      test('Face ID와 지문이 없고 홍채가 있으면 홍채 반환', () async {
        // Arrange
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.iris],
        );

        // Act
        final result = await service.getPrimaryBiometricType();

        // Assert
        expect(result, BiometricType.iris);
      });

      test('생체인증 사용 불가 시 null 반환', () async {
        // Arrange
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        // Act
        final result = await service.getPrimaryBiometricType();

        // Assert
        expect(result, null);
      });
    });

    group('getBiometricTypeName', () {
      test('생체인증 유형별 한국어 이름 반환', () {
        expect(
          service.getBiometricTypeName(BiometricType.face),
          'Face ID / 얼굴 인식',
        );
        expect(
          service.getBiometricTypeName(BiometricType.fingerprint),
          'Touch ID / 지문 인식',
        );
        expect(
          service.getBiometricTypeName(BiometricType.iris),
          '홍채 인식',
        );
        expect(
          service.getBiometricTypeName(BiometricType.weak),
          '낮은 보안 생체인증',
        );
        expect(
          service.getBiometricTypeName(BiometricType.strong),
          '높은 보안 생체인증',
        );
      });
    });
  });
}
