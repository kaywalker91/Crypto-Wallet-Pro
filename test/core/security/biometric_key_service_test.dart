import 'package:crypto_wallet_pro/core/error/failures.dart';
import 'package:crypto_wallet_pro/core/security/services/biometric_key_service.dart';
import 'package:crypto_wallet_pro/core/security/services/encryption_service.dart';
import 'package:crypto_wallet_pro/core/security/services/enhanced_biometric_service.dart';
import 'package:crypto_wallet_pro/core/security/services/key_derivation_service.dart';
import 'package:crypto_wallet_pro/shared/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'biometric_key_service_test.mocks.dart';

@GenerateMocks([
  SecureStorageService,
  EnhancedBiometricService,
  LocalAuthentication,
])
void main() {
  late BiometricKeyService service;
  late MockSecureStorageService mockSecureStorage;
  late MockEnhancedBiometricService mockBiometricService;
  late EncryptionService encryptionService;
  late KeyDerivationService keyDerivationService;

  setUp(() {
    mockSecureStorage = MockSecureStorageService();
    mockBiometricService = MockEnhancedBiometricService();
    encryptionService = EncryptionService();
    keyDerivationService = KeyDerivationService();

    service = BiometricKeyService(
      secureStorage: mockSecureStorage,
      biometricService: mockBiometricService,
      encryptionService: encryptionService,
      keyDerivationService: keyDerivationService,
    );
  });

  group('BiometricKeyService', () {
    const testPin = '123456';

    group('isBiometricKeyAvailable', () {
      test('생체인증 키가 존재하면 true 반환', () async {
        // Arrange
        when(mockSecureStorage.read('wallet_biometric_key'))
            .thenAnswer((_) async => 'mock_key');

        // Act
        final result = await service.isBiometricKeyAvailable();

        // Assert
        expect(result, true);
        verify(mockSecureStorage.read('wallet_biometric_key')).called(1);
      });

      test('생체인증 키가 없으면 false 반환', () async {
        // Arrange
        when(mockSecureStorage.read('wallet_biometric_key'))
            .thenAnswer((_) async => null);

        // Act
        final result = await service.isBiometricKeyAvailable();

        // Assert
        expect(result, false);
        verify(mockSecureStorage.read('wallet_biometric_key')).called(1);
      });
    });

    group('generateAndSaveBiometricKey', () {
      test('생체인증 키를 생성하고 저장', () async {
        // Arrange
        when(mockSecureStorage.read('wallet_biometric_key_salt'))
            .thenAnswer((_) async => null);
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          isSensitive: anyNamed('isSensitive'),
        )).thenAnswer((_) async {});

        // Act
        await service.generateAndSaveBiometricKey(pin: testPin);

        // Assert
        verify(mockSecureStorage.write(
          key: 'wallet_biometric_key_salt',
          value: anyNamed('value'),
          isSensitive: true,
        )).called(1);

        verify(mockSecureStorage.write(
          key: 'wallet_encrypted_biometric_key',
          value: anyNamed('value'),
          isSensitive: true,
        )).called(1);

        verify(mockSecureStorage.write(
          key: 'wallet_biometric_key',
          value: anyNamed('value'),
          isSensitive: true,
        )).called(1);
      });

      test('기존 Salt가 있으면 재사용', () async {
        // Arrange
        final existingSalt = keyDerivationService.generateSalt();
        when(mockSecureStorage.read('wallet_biometric_key_salt'))
            .thenAnswer((_) async => existingSalt);
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          isSensitive: anyNamed('isSensitive'),
        )).thenAnswer((_) async {});

        // Act
        await service.generateAndSaveBiometricKey(pin: testPin);

        // Assert
        // Salt가 재사용되므로 새로 저장하지 않음
        verify(mockSecureStorage.write(
          key: 'wallet_encrypted_biometric_key',
          value: anyNamed('value'),
          isSensitive: true,
        )).called(1);

        verify(mockSecureStorage.write(
          key: 'wallet_biometric_key',
          value: anyNamed('value'),
          isSensitive: true,
        )).called(1);
      });
    });

    group('getBiometricKey', () {
      test('생체인증 성공 시 키 반환', () async {
        // Arrange
        const mockKey = 'mock_biometric_key_base64';
        when(mockBiometricService.ensureAuthenticated(
          reason: anyNamed('reason'),
        )).thenAnswer((_) async => true);
        when(mockSecureStorage.read('wallet_biometric_key'))
            .thenAnswer((_) async => mockKey);

        // Act
        final result = await service.getBiometricKey();

        // Assert
        expect(result, mockKey);
        verify(mockBiometricService.ensureAuthenticated(
          reason: anyNamed('reason'),
        )).called(1);
        verify(mockSecureStorage.read('wallet_biometric_key')).called(1);
      });

      test('생체인증 실패 시 null 반환', () async {
        // Arrange
        when(mockBiometricService.ensureAuthenticated(
          reason: anyNamed('reason'),
        )).thenAnswer((_) async => false);

        // Act
        final result = await service.getBiometricKey();

        // Assert
        expect(result, null);
        verify(mockBiometricService.ensureAuthenticated(
          reason: anyNamed('reason'),
        )).called(1);
        verifyNever(mockSecureStorage.read('wallet_biometric_key'));
      });
    });

    group('getBiometricKeyWithPin', () {
      test('올바른 PIN으로 키 복호화', () async {
        // Arrange
        // 1. Salt 생성 및 저장
        final salt = keyDerivationService.generateSalt();
        when(mockSecureStorage.read('wallet_biometric_key_salt'))
            .thenAnswer((_) async => salt);

        // 2. PIN으로 키 파생
        final pinKey = keyDerivationService.deriveKey(pin: testPin, salt: salt);

        // 3. 생체인증 키 생성 (정확히 32바이트)
        const biometricKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='; // 32 bytes Base64

        // 4. 생체인증 키를 PIN 키로 암호화
        final encryptedBiometricKey = encryptionService.encrypt(
          plaintext: biometricKey,
          key: pinKey,
        );

        when(mockSecureStorage.read('wallet_encrypted_biometric_key'))
            .thenAnswer((_) async => encryptedBiometricKey);

        // Act
        final result = await service.getBiometricKeyWithPin(pin: testPin);

        // Assert
        expect(result, biometricKey);
        verify(mockSecureStorage.read('wallet_encrypted_biometric_key')).called(1);
        verify(mockSecureStorage.read('wallet_biometric_key_salt')).called(1);
      });

      test('잘못된 PIN으로 복호화 시 CryptographyFailure 발생', () async {
        // Arrange
        final salt = keyDerivationService.generateSalt();
        when(mockSecureStorage.read('wallet_biometric_key_salt'))
            .thenAnswer((_) async => salt);

        // 올바른 PIN으로 암호화
        final correctPinKey = keyDerivationService.deriveKey(pin: testPin, salt: salt);
        const biometricKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
        final encryptedBiometricKey = encryptionService.encrypt(
          plaintext: biometricKey,
          key: correctPinKey,
        );

        when(mockSecureStorage.read('wallet_encrypted_biometric_key'))
            .thenAnswer((_) async => encryptedBiometricKey);

        // Act & Assert
        // 잘못된 PIN으로 복호화 시도
        expect(
          () => service.getBiometricKeyWithPin(pin: 'wrong_pin'),
          throwsA(isA<CryptographyFailure>()),
        );
      });

      test('암호화된 키가 없으면 null 반환', () async {
        // Arrange
        when(mockSecureStorage.read('wallet_encrypted_biometric_key'))
            .thenAnswer((_) async => null);

        // Act
        final result = await service.getBiometricKeyWithPin(pin: testPin);

        // Assert
        expect(result, null);
        verify(mockSecureStorage.read('wallet_encrypted_biometric_key')).called(1);
        verifyNever(mockSecureStorage.read('wallet_biometric_key_salt'));
      });

      test('Salt가 없으면 CryptographyFailure 발생', () async {
        // Arrange
        when(mockSecureStorage.read('wallet_encrypted_biometric_key'))
            .thenAnswer((_) async => 'encrypted_data');
        when(mockSecureStorage.read('wallet_biometric_key_salt'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.getBiometricKeyWithPin(pin: testPin),
          throwsA(isA<CryptographyFailure>()),
        );
      });
    });

    group('encryptWithBiometricKey', () {
      test('생체인증으로 데이터 암호화', () async {
        // Arrange
        const plaintext = 'secret_data';
        // 정확히 32바이트 (256비트) Base64 인코딩 키
        const mockKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='; // 32 bytes

        when(mockBiometricService.ensureAuthenticated(
          reason: anyNamed('reason'),
        )).thenAnswer((_) async => true);
        when(mockSecureStorage.read('wallet_biometric_key'))
            .thenAnswer((_) async => mockKey);

        // Act
        final result = await service.encryptWithBiometricKey(
          plaintext: plaintext,
          pin: testPin,
          useBiometric: true,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result, isNot(equals(plaintext)));
        verify(mockBiometricService.ensureAuthenticated(
          reason: anyNamed('reason'),
        )).called(1);
      });

      test('PIN으로 데이터 암호화 (폴백)', () async {
        // Arrange
        const plaintext = 'secret_data';
        final salt = keyDerivationService.generateSalt();
        final pinKey = keyDerivationService.deriveKey(pin: testPin, salt: salt);
        // 정확히 32바이트 Base64 인코딩 키
        const biometricKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
        final encryptedBiometricKey = encryptionService.encrypt(
          plaintext: biometricKey,
          key: pinKey,
        );

        when(mockSecureStorage.read('wallet_encrypted_biometric_key'))
            .thenAnswer((_) async => encryptedBiometricKey);
        when(mockSecureStorage.read('wallet_biometric_key_salt'))
            .thenAnswer((_) async => salt);

        // Act
        final result = await service.encryptWithBiometricKey(
          plaintext: plaintext,
          pin: testPin,
          useBiometric: false,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result, isNot(equals(plaintext)));
        verifyNever(mockBiometricService.ensureAuthenticated(
          reason: anyNamed('reason'),
        ));
      });
    });

    group('deleteBiometricKey', () {
      test('모든 생체인증 키 데이터 삭제', () async {
        // Arrange
        when(mockSecureStorage.delete(any)).thenAnswer((_) async {});

        // Act
        await service.deleteBiometricKey();

        // Assert
        verify(mockSecureStorage.delete('wallet_biometric_key')).called(1);
        verify(mockSecureStorage.delete('wallet_encrypted_biometric_key')).called(1);
        verify(mockSecureStorage.delete('wallet_biometric_key_salt')).called(1);
      });
    });

    group('changePinForBiometricKey', () {
      test('PIN 변경 시 생체인증 키 재암호화', () async {
        // Arrange
        const oldPin = '123456';
        const newPin = '654321';

        // 기존 PIN으로 암호화된 데이터
        final oldSalt = keyDerivationService.generateSalt();
        final oldPinKey = keyDerivationService.deriveKey(pin: oldPin, salt: oldSalt);
        const biometricKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
        final encryptedBiometricKey = encryptionService.encrypt(
          plaintext: biometricKey,
          key: oldPinKey,
        );

        when(mockSecureStorage.read('wallet_encrypted_biometric_key'))
            .thenAnswer((_) async => encryptedBiometricKey);
        when(mockSecureStorage.read('wallet_biometric_key_salt'))
            .thenAnswer((_) async => oldSalt);
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          isSensitive: anyNamed('isSensitive'),
        )).thenAnswer((_) async {});

        // Act
        await service.changePinForBiometricKey(oldPin: oldPin, newPin: newPin);

        // Assert
        verify(mockSecureStorage.write(
          key: 'wallet_encrypted_biometric_key',
          value: anyNamed('value'),
          isSensitive: true,
        )).called(1);

        verify(mockSecureStorage.write(
          key: 'wallet_biometric_key_salt',
          value: anyNamed('value'),
          isSensitive: true,
        )).called(1);
      });

      test('잘못된 기존 PIN으로 PIN 변경 시 CryptographyFailure 발생', () async {
        // Arrange
        const oldPin = '123456';
        const wrongOldPin = 'wrong_pin';
        const newPin = '654321';

        final salt = keyDerivationService.generateSalt();
        final pinKey = keyDerivationService.deriveKey(pin: oldPin, salt: salt);
        const biometricKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
        final encryptedBiometricKey = encryptionService.encrypt(
          plaintext: biometricKey,
          key: pinKey,
        );

        when(mockSecureStorage.read('wallet_encrypted_biometric_key'))
            .thenAnswer((_) async => encryptedBiometricKey);
        when(mockSecureStorage.read('wallet_biometric_key_salt'))
            .thenAnswer((_) async => salt);

        // Act & Assert
        expect(
          () => service.changePinForBiometricKey(
            oldPin: wrongOldPin,
            newPin: newPin,
          ),
          throwsA(isA<CryptographyFailure>()),
        );
      });
    });
  });
}
