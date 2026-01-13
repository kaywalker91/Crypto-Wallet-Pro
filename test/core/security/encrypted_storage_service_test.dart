import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_wallet_pro/core/security/services/encrypted_storage_service.dart';
import 'package:crypto_wallet_pro/core/security/services/encryption_service.dart';
import 'package:crypto_wallet_pro/core/security/services/key_derivation_service.dart';
import 'package:crypto_wallet_pro/shared/services/secure_storage_service.dart';
import 'package:crypto_wallet_pro/core/constants/storage_keys.dart';
import 'package:crypto_wallet_pro/core/error/failures.dart';

/// Mock SecureStorageService for testing.
class MockSecureStorageService implements SecureStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String value,
    bool isSensitive = true,
  }) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  void clear() {
    _storage.clear();
  }
}

void main() {
  late EncryptedStorageService service;
  late MockSecureStorageService mockStorage;
  late EncryptionService encryptionService;
  late KeyDerivationService keyDerivationService;

  setUp(() {
    mockStorage = MockSecureStorageService();
    encryptionService = EncryptionService();
    keyDerivationService = KeyDerivationService();
    service = EncryptedStorageService(
      secureStorage: mockStorage,
      encryptionService: encryptionService,
      keyDerivationService: keyDerivationService,
    );
  });

  tearDown(() {
    mockStorage.clear();
  });

  group('EncryptedStorageService', () {
    group('saveMnemonic & getMnemonic', () {
      test('니모닉을 암호화하여 저장하고 복호화하여 조회할 수 있어야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3 word4 word5 word6 word7 word8 '
            'word9 word10 word11 word12';
        const pin = '123456';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);
        final retrieved = await service.getMnemonic(pin: pin);

        // Assert
        expect(retrieved, equals(mnemonic));
      });

      test('한글 니모닉을 암호화하여 저장하고 복호화할 수 있어야 함', () async {
        // Arrange
        const mnemonic = '단어1 단어2 단어3 단어4 단어5 단어6';
        const pin = '123456';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);
        final retrieved = await service.getMnemonic(pin: pin);

        // Assert
        expect(retrieved, equals(mnemonic));
      });

      test('다른 PIN으로 조회 시 CryptographyFailure를 발생해야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3';
        const pin1 = '123456';
        const pin2 = '654321';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin1);

        // Assert
        expect(
          () => service.getMnemonic(pin: pin2),
          throwsA(isA<CryptographyFailure>()),
        );
      });

      test('저장된 니모닉이 없으면 null을 반환해야 함', () async {
        // Act
        final retrieved = await service.getMnemonic(pin: '123456');

        // Assert
        expect(retrieved, isNull);
      });

      test('Salt가 없으면 CryptographyFailure를 발생해야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3';
        const pin = '123456';
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);

        // Delete salt
        await mockStorage.delete(StorageKeys.pinSalt);

        // Act & Assert
        expect(
          () => service.getMnemonic(pin: pin),
          throwsA(isA<CryptographyFailure>()),
        );
      });

      test('동일한 PIN으로 여러 번 저장해도 동일한 Salt를 재사용해야 함', () async {
        // Arrange
        const mnemonic1 = 'word1 word2 word3';
        const mnemonic2 = 'word4 word5 word6';
        const pin = '123456';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic1, pin: pin);
        final salt1 = await mockStorage.read(StorageKeys.pinSalt);

        await service.saveMnemonic(mnemonic: mnemonic2, pin: pin);
        final salt2 = await mockStorage.read(StorageKeys.pinSalt);

        // Assert
        expect(salt1, equals(salt2));

        // Verify latest mnemonic is retrievable
        final retrieved = await service.getMnemonic(pin: pin);
        expect(retrieved, equals(mnemonic2));
      });
    });

    group('isPlaintextMnemonic', () {
      test('평문 니모닉이 저장되어 있으면 true를 반환해야 함', () async {
        // Arrange
        await mockStorage.write(
          key: StorageKeys.mnemonic,
          value: 'word1 word2 word3',
          isSensitive: true,
        );
        // No salt = plaintext

        // Act
        final isPlaintext = await service.isPlaintextMnemonic();

        // Assert
        expect(isPlaintext, isTrue);
      });

      test('암호화된 니모닉이 저장되어 있으면 false를 반환해야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3';
        const pin = '123456';
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);

        // Act
        final isPlaintext = await service.isPlaintextMnemonic();

        // Assert
        expect(isPlaintext, isFalse);
      });

      test('니모닉이 없으면 false를 반환해야 함', () async {
        // Act
        final isPlaintext = await service.isPlaintextMnemonic();

        // Assert
        expect(isPlaintext, isFalse);
      });

      test('Salt가 있지만 니모닉이 평문이면 true를 반환해야 함', () async {
        // Arrange
        await mockStorage.write(
          key: StorageKeys.mnemonic,
          value: 'word1 word2 word3', // plaintext
          isSensitive: true,
        );
        await mockStorage.write(
          key: StorageKeys.pinSalt,
          value: keyDerivationService.generateSalt(),
          isSensitive: true,
        );

        // Act
        final isPlaintext = await service.isPlaintextMnemonic();

        // Assert
        expect(isPlaintext, isTrue);
      });
    });

    group('migratePlaintextMnemonic', () {
      test('평문 니모닉을 암호문으로 마이그레이션해야 함', () async {
        // Arrange
        const plaintextMnemonic = 'word1 word2 word3';
        const pin = '123456';
        await mockStorage.write(
          key: StorageKeys.mnemonic,
          value: plaintextMnemonic,
          isSensitive: true,
        );

        // Act
        await service.migratePlaintextMnemonic(pin: pin);

        // Assert
        final isPlaintext = await service.isPlaintextMnemonic();
        expect(isPlaintext, isFalse);

        final retrieved = await service.getMnemonic(pin: pin);
        expect(retrieved, equals(plaintextMnemonic));
      });

      test('이미 암호화된 니모닉은 마이그레이션하지 않아야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3';
        const pin = '123456';
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);

        // Act
        await service.migratePlaintextMnemonic(pin: pin);

        // Assert - 마이그레이션 후에도 복호화 가능해야 함
        final isPlaintext = await service.isPlaintextMnemonic();
        expect(isPlaintext, isFalse);

        final retrieved = await service.getMnemonic(pin: pin);
        expect(retrieved, equals(mnemonic));
      });

      test('니모닉이 없으면 아무 작업도 하지 않아야 함', () async {
        // Act
        await service.migratePlaintextMnemonic(pin: '123456');

        // Assert
        final mnemonic = await mockStorage.read(StorageKeys.mnemonic);
        expect(mnemonic, isNull);
      });
    });

    group('deleteMnemonic', () {
      test('니모닉과 Salt를 모두 삭제해야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3';
        const pin = '123456';
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);

        // Act
        await service.deleteMnemonic();

        // Assert
        final storedMnemonic = await mockStorage.read(StorageKeys.mnemonic);
        final storedSalt = await mockStorage.read(StorageKeys.pinSalt);
        expect(storedMnemonic, isNull);
        expect(storedSalt, isNull);
      });

      test('니모닉이 없어도 오류 없이 실행되어야 함', () async {
        // Act & Assert
        expect(() => service.deleteMnemonic(), returnsNormally);
      });
    });

    group('Defense-in-Depth 검증', () {
      test('저장된 데이터는 평문이 아니어야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3';
        const pin = '123456';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);

        // Assert
        final stored = await mockStorage.read(StorageKeys.mnemonic);
        expect(stored, isNot(equals(mnemonic)));
      });

      test('Salt는 별도로 저장되어야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3';
        const pin = '123456';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);

        // Assert
        final salt = await mockStorage.read(StorageKeys.pinSalt);
        expect(salt, isNotNull);
        expect(keyDerivationService.validateSalt(salt!), isTrue);
      });

      test('동일한 니모닉도 매번 다른 암호문으로 저장되어야 함 (랜덤 IV)', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3';
        const pin = '123456';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);
        final encrypted1 = await mockStorage.read(StorageKeys.mnemonic);

        await service.deleteMnemonic();

        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);
        final encrypted2 = await mockStorage.read(StorageKeys.mnemonic);

        // Assert
        expect(encrypted1, isNot(equals(encrypted2)));
      });
    });

    group('에지 케이스', () {
      test('빈 문자열 니모닉을 처리할 수 있어야 함', () async {
        // Arrange
        const mnemonic = '';
        const pin = '123456';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);
        final retrieved = await service.getMnemonic(pin: pin);

        // Assert
        expect(retrieved, equals(mnemonic));
      });

      test('매우 긴 니모닉을 처리할 수 있어야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3 word4 word5 word6 word7 word8 '
            'word9 word10 word11 word12 word13 word14 word15 word16 '
            'word17 word18 word19 word20 word21 word22 word23 word24';
        const pin = '123456';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);
        final retrieved = await service.getMnemonic(pin: pin);

        // Assert
        expect(retrieved, equals(mnemonic));
      });

      test('특수문자를 포함한 PIN을 처리할 수 있어야 함', () async {
        // Arrange
        const mnemonic = 'word1 word2 word3';
        const pin = '!@#\$%^&*()';

        // Act
        await service.saveMnemonic(mnemonic: mnemonic, pin: pin);
        final retrieved = await service.getMnemonic(pin: pin);

        // Assert
        expect(retrieved, equals(mnemonic));
      });
    });
  });
}
