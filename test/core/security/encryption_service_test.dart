import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_wallet_pro/core/security/services/encryption_service.dart';
import 'package:crypto_wallet_pro/core/security/services/key_derivation_service.dart';
import 'package:crypto_wallet_pro/core/error/failures.dart';

void main() {
  late EncryptionService encryptionService;
  late KeyDerivationService keyDerivationService;

  setUp(() {
    encryptionService = EncryptionService();
    keyDerivationService = KeyDerivationService();
  });

  group('EncryptionService', () {
    group('encrypt & decrypt', () {
      test('평문을 암호화하고 복호화할 수 있어야 함', () {
        // Arrange
        const plaintext = 'test mnemonic phrase';
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);

        // Act
        final encrypted = encryptionService.encrypt(plaintext: plaintext, key: key);
        final decrypted = encryptionService.decrypt(ciphertext: encrypted, key: key);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('한글 텍스트를 암호화하고 복호화할 수 있어야 함', () {
        // Arrange
        const plaintext = '안녕하세요 암호화 테스트입니다';
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);

        // Act
        final encrypted = encryptionService.encrypt(plaintext: plaintext, key: key);
        final decrypted = encryptionService.decrypt(ciphertext: encrypted, key: key);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('긴 텍스트를 암호화하고 복호화할 수 있어야 함', () {
        // Arrange
        const plaintext = 'word1 word2 word3 word4 word5 word6 word7 word8 '
            'word9 word10 word11 word12 word13 word14 word15';
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);

        // Act
        final encrypted = encryptionService.encrypt(plaintext: plaintext, key: key);
        final decrypted = encryptionService.decrypt(ciphertext: encrypted, key: key);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('특수문자를 포함한 텍스트를 암호화하고 복호화할 수 있어야 함', () {
        // Arrange
        const plaintext = '!@#\$%^&*()_+-=[]{}|;:",.<>?/~`';
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);

        // Act
        final encrypted = encryptionService.encrypt(plaintext: plaintext, key: key);
        final decrypted = encryptionService.decrypt(ciphertext: encrypted, key: key);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('매번 다른 암호문을 생성해야 함 (랜덤 IV)', () {
        // Arrange
        const plaintext = 'test mnemonic phrase';
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);

        // Act
        final encrypted1 = encryptionService.encrypt(plaintext: plaintext, key: key);
        final encrypted2 = encryptionService.encrypt(plaintext: plaintext, key: key);

        // Assert
        expect(encrypted1, isNot(equals(encrypted2)));

        // But both should decrypt to same plaintext
        final decrypted1 = encryptionService.decrypt(ciphertext: encrypted1, key: key);
        final decrypted2 = encryptionService.decrypt(ciphertext: encrypted2, key: key);
        expect(decrypted1, equals(plaintext));
        expect(decrypted2, equals(plaintext));
      });

      test('잘못된 키로 복호화 시 CryptographyFailure를 발생해야 함', () {
        // Arrange
        const plaintext = 'test mnemonic phrase';
        final salt = keyDerivationService.generateSalt();
        final key1 = keyDerivationService.deriveKey(pin: '123456', salt: salt);
        final key2 = keyDerivationService.deriveKey(pin: '654321', salt: salt);
        final encrypted = encryptionService.encrypt(plaintext: plaintext, key: key1);

        // Act & Assert
        expect(
          () => encryptionService.decrypt(ciphertext: encrypted, key: key2),
          throwsA(isA<CryptographyFailure>()),
        );
      });

      test('변조된 암호문 복호화 시 CryptographyFailure를 발생해야 함', () {
        // Arrange
        const plaintext = 'test mnemonic phrase';
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);
        final encrypted = encryptionService.encrypt(plaintext: plaintext, key: key);

        // Tamper with ciphertext
        final tamperedBytes = base64.decode(encrypted);
        tamperedBytes[tamperedBytes.length - 1] ^= 0xFF; // Flip last byte
        final tampered = base64.encode(tamperedBytes);

        // Act & Assert
        expect(
          () => encryptionService.decrypt(ciphertext: tampered, key: key),
          throwsA(isA<CryptographyFailure>()),
        );
      });

      test('잘못된 Base64 형식으로 CryptographyFailure를 발생해야 함', () {
        // Arrange
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);
        const invalidCiphertext = 'not-valid-base64!!!';

        // Act & Assert
        expect(
          () => encryptionService.decrypt(ciphertext: invalidCiphertext, key: key),
          throwsA(isA<CryptographyFailure>()),
        );
      });

      test('너무 짧은 암호문으로 CryptographyFailure를 발생해야 함', () {
        // Arrange
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);
        const shortCiphertext = 'dGVzdA=='; // Base64: "test" (4 bytes)

        // Act & Assert
        expect(
          () => encryptionService.decrypt(ciphertext: shortCiphertext, key: key),
          throwsA(isA<CryptographyFailure>()),
        );
      });

      test('빈 문자열을 암호화하고 복호화할 수 있어야 함', () {
        // Arrange
        const plaintext = '';
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);

        // Act
        final encrypted = encryptionService.encrypt(plaintext: plaintext, key: key);
        final decrypted = encryptionService.decrypt(ciphertext: encrypted, key: key);

        // Assert
        expect(decrypted, equals(plaintext));
      });
    });

    group('키 검증', () {
      test('잘못된 키 길이로 CryptographyFailure를 발생해야 함', () {
        // Arrange
        const plaintext = 'test';
        const shortKey = 'dG9vLXNob3J0'; // Base64: "too-short" (9 bytes)

        // Act & Assert
        expect(
          () => encryptionService.encrypt(plaintext: plaintext, key: shortKey),
          throwsA(isA<CryptographyFailure>()),
        );
      });

      test('잘못된 Base64 키 형식으로 CryptographyFailure를 발생해야 함', () {
        // Arrange
        const plaintext = 'test';
        const invalidKey = 'invalid-key!!!';

        // Act & Assert
        expect(
          () => encryptionService.encrypt(plaintext: plaintext, key: invalidKey),
          throwsA(isA<CryptographyFailure>()),
        );
      });
    });

    group('암호화 데이터 포맷', () {
      test('암호문은 Base64 인코딩되어야 함', () {
        // Arrange
        const plaintext = 'test mnemonic phrase';
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);

        // Act
        final encrypted = encryptionService.encrypt(plaintext: plaintext, key: key);

        // Assert - Base64 디코딩 가능
        expect(() => base64.decode(encrypted), returnsNormally);
      });

      test('암호문은 IV + Ciphertext + Tag를 포함해야 함', () {
        // Arrange
        const plaintext = 'test';
        final salt = keyDerivationService.generateSalt();
        final key = keyDerivationService.deriveKey(pin: '123456', salt: salt);

        // Act
        final encrypted = encryptionService.encrypt(plaintext: plaintext, key: key);
        final encryptedBytes = base64.decode(encrypted);

        // Assert
        // IV (12) + Plaintext (4) + Tag (16) = 32 bytes minimum
        expect(encryptedBytes.length, greaterThanOrEqualTo(32));
      });
    });

    group('보안 특성', () {
      test('AES-256 (32바이트 키)를 사용해야 함', () {
        // Assert
        expect(EncryptionService.keyLength, equals(32));
      });

      test('GCM 표준 IV 길이 (12바이트)를 사용해야 함', () {
        // Assert
        expect(EncryptionService.ivLength, equals(12));
      });

      test('GCM 표준 Auth Tag 길이 (128비트)를 사용해야 함', () {
        // Assert
        expect(EncryptionService.macLength, equals(128));
      });
    });
  });
}
