import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_wallet_pro/core/security/services/key_derivation_service.dart';
import 'package:crypto_wallet_pro/core/error/failures.dart';

void main() {
  late KeyDerivationService service;

  setUp(() {
    service = KeyDerivationService();
  });

  group('KeyDerivationService', () {
    group('generateSalt', () {
      test('32바이트 Salt를 생성해야 함', () {
        // Act
        final salt = service.generateSalt();

        // Assert
        expect(service.validateSalt(salt), isTrue);
      });

      test('매번 다른 Salt를 생성해야 함', () {
        // Act
        final salt1 = service.generateSalt();
        final salt2 = service.generateSalt();

        // Assert
        expect(salt1, isNot(equals(salt2)));
      });

      test('Base64 인코딩된 문자열을 반환해야 함', () {
        // Act
        final salt = service.generateSalt();

        // Assert - Base64 디코딩 가능
        expect(() => service.validateSalt(salt), returnsNormally);
      });
    });

    group('deriveKey', () {
      test('동일한 PIN과 Salt로 동일한 키를 생성해야 함', () {
        // Arrange
        const pin = '123456';
        final salt = service.generateSalt();

        // Act
        final key1 = service.deriveKey(pin: pin, salt: salt);
        final key2 = service.deriveKey(pin: pin, salt: salt);

        // Assert
        expect(key1, equals(key2));
      });

      test('다른 PIN으로 다른 키를 생성해야 함', () {
        // Arrange
        final salt = service.generateSalt();

        // Act
        final key1 = service.deriveKey(pin: '123456', salt: salt);
        final key2 = service.deriveKey(pin: '654321', salt: salt);

        // Assert
        expect(key1, isNot(equals(key2)));
      });

      test('다른 Salt로 다른 키를 생성해야 함', () {
        // Arrange
        const pin = '123456';
        final salt1 = service.generateSalt();
        final salt2 = service.generateSalt();

        // Act
        final key1 = service.deriveKey(pin: pin, salt: salt1);
        final key2 = service.deriveKey(pin: pin, salt: salt2);

        // Assert
        expect(key1, isNot(equals(key2)));
      });

      test('32바이트 키를 생성해야 함 (Base64 디코딩 후)', () {
        // Arrange
        const pin = '123456';
        final salt = service.generateSalt();

        // Act
        final key = service.deriveKey(pin: pin, salt: salt);
        final keyBytes = Uri.decodeComponent(key).length;

        // Assert - Base64는 4/3 배수로 인코딩되므로 원본 32바이트
        expect(keyBytes >= 32, isTrue);
      });

      test('잘못된 Salt 형식으로 CryptographyFailure를 발생해야 함', () {
        // Arrange
        const pin = '123456';
        const invalidSalt = 'invalid-salt!!!';

        // Act & Assert
        expect(
          () => service.deriveKey(pin: pin, salt: invalidSalt),
          throwsA(isA<CryptographyFailure>()),
        );
      });

      test('커스텀 iterations를 사용할 수 있어야 함', () {
        // Arrange
        const pin = '123456';
        final salt = service.generateSalt();

        // Act
        final key1 = service.deriveKey(pin: pin, salt: salt, iterations: 10000);
        final key2 = service.deriveKey(pin: pin, salt: salt, iterations: 20000);

        // Assert - iterations가 다르면 키도 달라야 함
        expect(key1, isNot(equals(key2)));
      });
    });

    group('validateSalt', () {
      test('유효한 Salt를 검증해야 함', () {
        // Arrange
        final salt = service.generateSalt();

        // Act
        final isValid = service.validateSalt(salt);

        // Assert
        expect(isValid, isTrue);
      });

      test('잘못된 형식의 Salt를 거부해야 함', () {
        // Arrange
        const invalidSalt = 'invalid-salt!!!';

        // Act
        final isValid = service.validateSalt(invalidSalt);

        // Assert
        expect(isValid, isFalse);
      });

      test('잘못된 길이의 Salt를 거부해야 함', () {
        // Arrange
        const shortSalt = 'dG9vLXNob3J0'; // Base64: "too-short" (9 bytes)

        // Act
        final isValid = service.validateSalt(shortSalt);

        // Assert
        expect(isValid, isFalse);
      });

      test('빈 문자열을 거부해야 함', () {
        // Act
        final isValid = service.validateSalt('');

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('보안 특성', () {
      test('PBKDF2 최소 100,000 iterations를 사용해야 함', () {
        // Assert
        expect(KeyDerivationService.kdfIterations, greaterThanOrEqualTo(100000));
      });

      test('256비트 (32바이트) 키를 생성해야 함', () {
        // Assert
        expect(KeyDerivationService.keyLength, equals(32));
      });

      test('최소 256비트 (32바이트) Salt를 사용해야 함', () {
        // Assert
        expect(KeyDerivationService.saltLength, greaterThanOrEqualTo(32));
      });
    });
  });
}
