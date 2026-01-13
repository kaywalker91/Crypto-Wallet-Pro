import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:crypto_wallet_pro/core/security/hsm/hsm_manager.dart';
import 'package:crypto_wallet_pro/core/security/hsm/hsm_capability.dart';
import 'package:crypto_wallet_pro/core/security/hsm/hsm_key.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/hsm');

  late HsmManager manager;

  setUp(() {
    manager = HsmManager();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('HsmManager - initialize', () {
    test('should initialize with StrongBox on Android', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {
            'hasStrongBox': true,
            'version': '2.0',
          };
        }
        return null;
      });

      await manager.initialize();
      final info = await manager.getHsmInfo();

      expect(info.isStrongBox, true);
      expect(info.isHardwareBacked, true);
    });

    test('should fallback to software when hardware not available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {
            'hasStrongBox': false,
            'version': '1.0',
          };
        }
        return null;
      });

      await manager.initialize();
      final info = await manager.getHsmInfo();

      expect(info.isHardwareBacked, false);
      expect(info.name, 'Software KeyStore');
    });
  });

  group('HsmManager - generateKey', () {
    test('should generate ECC P-256 key', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'generateKey') {
          expect(methodCall.arguments['alias'], 'test_key');
          expect(methodCall.arguments['keyType'], 'EC_P256');
          return {
            'keyId': 'key_123',
            'alias': 'test_key',
            'keyType': 'EC_P256',
            'purposes': ['SIGN', 'VERIFY'],
            'isHardwareBacked': true,
            'requiresBiometric': false,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'isExportable': false,
          };
        }
        return null;
      });

      await manager.initialize();
      final key = await manager.generateKey(
        alias: 'test_key',
        keyType: HsmKeyType.eccP256,
        purposes: [HsmKeyPurpose.sign, HsmKeyPurpose.verify],
      );

      expect(key.keyId, 'key_123');
      expect(key.alias, 'test_key');
      expect(key.keyType, HsmKeyType.eccP256);
      expect(key.isHardwareBacked, true);
    });

    test('should generate key with biometric requirement', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'generateKey') {
          expect(methodCall.arguments['requiresBiometric'], true);
          return {
            'keyId': 'biometric_key',
            'alias': 'biometric_test',
            'keyType': 'EC_P256',
            'purposes': ['SIGN'],
            'isHardwareBacked': true,
            'requiresBiometric': true,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'isExportable': false,
          };
        }
        return null;
      });

      await manager.initialize();
      final key = await manager.generateKey(
        alias: 'biometric_test',
        keyType: HsmKeyType.eccP256,
        purposes: [HsmKeyPurpose.sign],
        requiresBiometric: true,
      );

      expect(key.requiresBiometric, true);
    });
  });

  group('HsmManager - getKey', () {
    test('should retrieve existing key', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'getKey') {
          return {
            'keyId': 'existing_key',
            'alias': 'test_key',
            'keyType': 'EC_P256',
            'purposes': ['SIGN_VERIFY'],
            'isHardwareBacked': true,
            'requiresBiometric': false,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'isExportable': false,
          };
        }
        return null;
      });

      await manager.initialize();
      final key = await manager.getKey('existing_key');

      expect(key, isNotNull);
      expect(key!.keyId, 'existing_key');
    });

    test('should return null for non-existent key', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'getKey') {
          return null;
        }
        return null;
      });

      await manager.initialize();
      final key = await manager.getKey('nonexistent');

      expect(key, isNull);
    });
  });

  group('HsmManager - listKeys', () {
    test('should list all keys', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'listKeys') {
          return [
            {
              'keyId': 'key1',
              'alias': 'first',
              'keyType': 'EC_P256',
              'purposes': ['SIGN'],
              'isHardwareBacked': true,
              'requiresBiometric': false,
              'createdAt': DateTime.now().millisecondsSinceEpoch,
              'isExportable': false,
            },
            {
              'keyId': 'key2',
              'alias': 'second',
              'keyType': 'RSA_2048',
              'purposes': ['ENCRYPT', 'DECRYPT'],
              'isHardwareBacked': true,
              'requiresBiometric': false,
              'createdAt': DateTime.now().millisecondsSinceEpoch,
              'isExportable': false,
            },
          ];
        }
        return null;
      });

      await manager.initialize();
      final keys = await manager.listKeys();

      expect(keys, hasLength(2));
      expect(keys[0].keyId, 'key1');
      expect(keys[1].keyId, 'key2');
    });
  });

  group('HsmManager - deleteKey', () {
    test('should delete key successfully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'deleteKey') {
          return true;
        }
        return null;
      });

      await manager.initialize();
      final result = await manager.deleteKey('test_key');

      expect(result, true);
    });
  });

  group('HsmManager - sign and verify', () {
    test('should sign data successfully', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final mockSignature = Uint8List.fromList(List.filled(64, 0));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'sign') {
          expect(methodCall.arguments['keyId'], 'signing_key');
          expect(methodCall.arguments['data'], testData);
          return mockSignature;
        }
        return null;
      });

      await manager.initialize();
      final signature = await manager.sign(
        keyId: 'signing_key',
        data: testData,
      );

      expect(signature, mockSignature);
    });

    test('should verify signature successfully', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = Uint8List.fromList(List.filled(64, 0));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'verify') {
          return true;
        }
        return null;
      });

      await manager.initialize();
      final isValid = await manager.verify(
        keyId: 'verify_key',
        data: testData,
        signature: signature,
      );

      expect(isValid, true);
    });
  });

  group('HsmManager - encrypt and decrypt', () {
    test('should encrypt data successfully', () async {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
      final ciphertext = Uint8List.fromList([9, 8, 7, 6, 5]);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'encrypt') {
          return ciphertext;
        }
        return null;
      });

      await manager.initialize();
      final result = await manager.encrypt(
        keyId: 'encryption_key',
        plaintext: plaintext,
      );

      expect(result, ciphertext);
    });

    test('should decrypt data successfully', () async {
      final ciphertext = Uint8List.fromList([9, 8, 7, 6, 5]);
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        if (methodCall.method == 'decrypt') {
          return plaintext;
        }
        return null;
      });

      await manager.initialize();
      final result = await manager.decrypt(
        keyId: 'decryption_key',
        ciphertext: ciphertext,
      );

      expect(result, plaintext);
    });
  });

  group('HsmManager - capability checks', () {
    test('should check if HSM is available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        return null;
      });

      await manager.initialize();
      final isAvailable = await manager.isAvailable();

      expect(isAvailable, true);
    });

    test('should check capability support', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initializeAndroid') {
          return {'hasStrongBox': true, 'version': '2.0'};
        }
        return null;
      });

      await manager.initialize();
      final supportsSign =
          await manager.supportsCapability(HsmCapability.signing);

      expect(supportsSign, true);
    });
  });
}
