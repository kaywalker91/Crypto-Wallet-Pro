import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:crypto_wallet_pro/core/security/services/secure_enclave_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/secure_enclave');

  late SecureEnclaveService service;

  setUp(() {
    service = SecureEnclaveService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SecureEnclaveService - isAvailable', () {
    test('should return true when Secure Enclave is available on iOS', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSecureEnclaveAvailable') {
          return true;
        }
        return null;
      });

      final isAvailable = await service.isAvailable();

      expect(isAvailable, true);
    });

    test('should return false when hardware not available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSecureEnclaveAvailable') {
          return false;
        }
        return null;
      });

      final isAvailable = await service.isAvailable();

      expect(isAvailable, false);
    });

    test('should cache availability result', () async {
      int callCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSecureEnclaveAvailable') {
          callCount++;
          return true;
        }
        return null;
      });

      await service.isAvailable();
      await service.isAvailable();

      expect(callCount, 1); // Should only call platform once
    });
  });

  group('SecureEnclaveService - generateKey', () {
    test('should generate key successfully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSecureEnclaveAvailable') {
          return true;
        }
        if (methodCall.method == 'generateKey') {
          return {
            'keyId': 'test_key_123',
            'publicKey': 'BASE64_PUBLIC_KEY',
            'isHardwareBacked': true,
          };
        }
        return null;
      });

      final key = await service.generateKey();

      expect(key.keyId, 'test_key_123');
      expect(key.publicKey, 'BASE64_PUBLIC_KEY');
      expect(key.isHardwareBacked, true);
    });

    test('should throw exception when hardware not available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSecureEnclaveAvailable') {
          return false;
        }
        return null;
      });

      expect(
        () => service.generateKey(),
        throwsA(isA<Exception>()),
      );
    });

    test('should pass requiresBiometric parameter', () async {
      bool? receivedBiometricFlag;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSecureEnclaveAvailable') {
          return true;
        }
        if (methodCall.method == 'generateKey') {
          receivedBiometricFlag =
              methodCall.arguments['requiresBiometric'] as bool?;
          return {
            'keyId': 'test_key',
            'publicKey': 'PUBLIC_KEY',
            'isHardwareBacked': true,
          };
        }
        return null;
      });

      await service.generateKey(requiresBiometric: false);

      expect(receivedBiometricFlag, false);
    });
  });

  group('SecureEnclaveService - getKey', () {
    test('should retrieve existing key', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getKey') {
          return {
            'keyId': 'existing_key',
            'publicKey': 'PUBLIC_KEY',
            'isHardwareBacked': true,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          };
        }
        return null;
      });

      final key = await service.getKey();

      expect(key, isNotNull);
      expect(key!.keyId, 'existing_key');
    });

    test('should return null when key does not exist', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getKey') {
          return null;
        }
        return null;
      });

      final key = await service.getKey();

      expect(key, isNull);
    });
  });

  group('SecureEnclaveService - sign', () {
    test('should sign data successfully', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final mockSignature = Uint8List.fromList(List.filled(64, 0));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'sign') {
          expect(methodCall.arguments['keyId'], 'test_key');
          expect(methodCall.arguments['data'], testData);
          return mockSignature;
        }
        return null;
      });

      final signature = await service.sign(
        keyId: 'test_key',
        data: testData,
      );

      expect(signature.signature, mockSignature);
      expect(signature.keyId, 'test_key');
    });

    test('should throw exception on user cancellation', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'sign') {
          throw PlatformException(
            code: 'USER_CANCELED',
            message: 'User canceled biometric authentication',
          );
        }
        return null;
      });

      expect(
        () => service.sign(
          keyId: 'test_key',
          data: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when key not found', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'sign') {
          throw PlatformException(
            code: 'KEY_NOT_FOUND',
            message: 'Signing key not found',
          );
        }
        return null;
      });

      expect(
        () => service.sign(
          keyId: 'nonexistent_key',
          data: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SecureEnclaveService - verify', () {
    test('should verify signature successfully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'verify') {
          return true;
        }
        return null;
      });

      final isValid = await service.verify(
        publicKey: 'PUBLIC_KEY',
        data: Uint8List.fromList([1, 2, 3]),
        signature: Uint8List.fromList(List.filled(64, 0)),
      );

      expect(isValid, true);
    });

    test('should return false for invalid signature', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'verify') {
          return false;
        }
        return null;
      });

      final isValid = await service.verify(
        publicKey: 'PUBLIC_KEY',
        data: Uint8List.fromList([1, 2, 3]),
        signature: Uint8List.fromList([9, 9, 9]),
      );

      expect(isValid, false);
    });
  });

  group('SecureEnclaveService - deleteKey', () {
    test('should delete key successfully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'deleteKey') {
          return true;
        }
        return null;
      });

      final result = await service.deleteKey('test_key');

      expect(result, true);
    });

    test('should return false on deletion failure', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'deleteKey') {
          return false;
        }
        return null;
      });

      final result = await service.deleteKey('test_key');

      expect(result, false);
    });
  });

  group('SecureEnclaveService - keyExists', () {
    test('should return true when key exists', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'keyExists') {
          return true;
        }
        return null;
      });

      final exists = await service.keyExists('test_key');

      expect(exists, true);
    });

    test('should return false when key does not exist', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'keyExists') {
          return false;
        }
        return null;
      });

      final exists = await service.keyExists('nonexistent_key');

      expect(exists, false);
    });
  });

  group('SecureEnclaveService - backupKeyMetadata', () {
    test('should backup key metadata successfully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'backupKeyMetadata') {
          return {
            'keyId': 'test_key',
            'publicKey': 'PUBLIC_KEY',
            'isHardwareBacked': true,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          };
        }
        return null;
      });

      final metadata = await service.backupKeyMetadata('test_key');

      expect(metadata, isNotEmpty);
      expect(metadata['keyId'], 'test_key');
      expect(metadata['publicKey'], 'PUBLIC_KEY');
    });
  });
}
