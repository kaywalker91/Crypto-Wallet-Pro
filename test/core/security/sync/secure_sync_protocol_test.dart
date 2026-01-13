import 'package:crypto_wallet_pro/core/security/services/encryption_service.dart';
import 'package:crypto_wallet_pro/core/security/services/key_derivation_service.dart';
import 'package:crypto_wallet_pro/core/security/sync/secure_sync_protocol.dart';
import 'package:crypto_wallet_pro/core/security/sync/sync_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SecureSyncProtocol syncProtocol;
  late EncryptionService encryptionService;
  late KeyDerivationService keyDerivationService;

  setUp(() {
    encryptionService = EncryptionService();
    keyDerivationService = KeyDerivationService();
    syncProtocol = SecureSyncProtocol(
      encryptionService: encryptionService,
      keyDerivationService: keyDerivationService,
    );
  });

  group('SecureSyncProtocol - Key Derivation', () {
    test('should derive sync key from master key', () async {
      final masterKey = keyDerivationService.generateSalt(); // Use as key
      final salt = keyDerivationService.generateSalt();

      final syncKey = await syncProtocol.deriveSyncKey(
        masterKey: masterKey,
        salt: salt,
      );

      expect(syncKey, isNotEmpty);
      expect(syncKey, isNot(masterKey));
    });

    test('should derive different keys for different contexts', () async {
      final masterKey = keyDerivationService.generateSalt();
      final salt = keyDerivationService.generateSalt();

      final syncKey1 = await syncProtocol.deriveSyncKey(
        masterKey: masterKey,
        salt: salt,
        context: 'CONTEXT_1',
      );

      final syncKey2 = await syncProtocol.deriveSyncKey(
        masterKey: masterKey,
        salt: salt,
        context: 'CONTEXT_2',
      );

      expect(syncKey1, isNot(syncKey2));
    });

    test('should derive same key for same inputs', () async {
      final masterKey = keyDerivationService.generateSalt();
      final salt = keyDerivationService.generateSalt();

      final syncKey1 = await syncProtocol.deriveSyncKey(
        masterKey: masterKey,
        salt: salt,
      );

      final syncKey2 = await syncProtocol.deriveSyncKey(
        masterKey: masterKey,
        salt: salt,
      );

      expect(syncKey1, syncKey2);
    });
  });

  group('SecureSyncProtocol - Encryption/Decryption', () {
    late String syncKey;
    const String testData = '{"test": "data", "value": 123}';
    const String deviceId = 'test-device-id';

    setUp(() async {
      final masterKey = keyDerivationService.generateSalt();
      final salt = keyDerivationService.generateSalt();
      syncKey = await syncProtocol.deriveSyncKey(
        masterKey: masterKey,
        salt: salt,
      );
    });

    test('should encrypt data into SyncPayload', () async {
      final payload = await syncProtocol.encryptPayload(
        data: testData,
        dataType: SyncDataType.auditLogs,
        syncKey: syncKey,
        deviceId: deviceId,
      );

      expect(payload.id, isNotEmpty);
      expect(payload.dataType, SyncDataType.auditLogs);
      expect(payload.encryptedData, isNotEmpty);
      expect(payload.iv, isNotEmpty);
      expect(payload.authTag, isNotEmpty);
      expect(payload.deviceId, deviceId);
      expect(payload.checksum, isNotEmpty);
      expect(payload.version, 1);
    });

    test('should decrypt SyncPayload back to original data', () async {
      final payload = await syncProtocol.encryptPayload(
        data: testData,
        dataType: SyncDataType.auditLogs,
        syncKey: syncKey,
        deviceId: deviceId,
      );

      final decrypted = await syncProtocol.decryptPayload(
        payload: payload,
        syncKey: syncKey,
      );

      expect(decrypted, testData);
    });

    test('should fail decryption with wrong key', () async {
      final payload = await syncProtocol.encryptPayload(
        data: testData,
        dataType: SyncDataType.auditLogs,
        syncKey: syncKey,
        deviceId: deviceId,
      );

      // Generate a different key
      final wrongKey = keyDerivationService.generateSalt();

      await expectLater(
        syncProtocol.decryptPayload(
          payload: payload,
          syncKey: wrongKey,
        ),
        throwsA(anything),
      );
    });

    test('should support encryption round-trip for all data types', () async {
      for (final dataType in SyncDataType.values) {
        final payload = await syncProtocol.encryptPayload(
          data: testData,
          dataType: dataType,
          syncKey: syncKey,
          deviceId: deviceId,
        );

        final decrypted = await syncProtocol.decryptPayload(
          payload: payload,
          syncKey: syncKey,
        );

        expect(decrypted, testData);
        expect(payload.dataType, dataType);
      }
    });

    test('should create unique IVs for each encryption', () async {
      final payload1 = await syncProtocol.encryptPayload(
        data: testData,
        dataType: SyncDataType.auditLogs,
        syncKey: syncKey,
        deviceId: deviceId,
      );

      final payload2 = await syncProtocol.encryptPayload(
        data: testData,
        dataType: SyncDataType.auditLogs,
        syncKey: syncKey,
        deviceId: deviceId,
      );

      expect(payload1.iv, isNot(payload2.iv));
      expect(payload1.encryptedData, isNot(payload2.encryptedData));
    });

    test('should include version in payload', () async {
      final payload = await syncProtocol.encryptPayload(
        data: testData,
        dataType: SyncDataType.auditLogs,
        syncKey: syncKey,
        deviceId: deviceId,
        version: 5,
      );

      expect(payload.version, 5);
    });
  });

  group('SecureSyncProtocol - Checksum', () {
    test('should generate checksum for data', () {
      const data = 'test data for checksum';
      final checksum = syncProtocol.generateChecksum(data);

      expect(checksum, isNotEmpty);
      expect(checksum.length, greaterThan(32)); // SHA-256 hex length
    });

    test('should generate different checksums for different data', () {
      const data1 = 'data 1';
      const data2 = 'data 2';

      final checksum1 = syncProtocol.generateChecksum(data1);
      final checksum2 = syncProtocol.generateChecksum(data2);

      expect(checksum1, isNot(checksum2));
    });

    test('should generate same checksum for same data', () {
      const data = 'consistent data';

      final checksum1 = syncProtocol.generateChecksum(data);
      final checksum2 = syncProtocol.generateChecksum(data);

      expect(checksum1, checksum2);
    });

    test('should verify valid checksum', () async {
      const testData = 'test data';
      final syncKey = keyDerivationService.generateSalt();

      final payload = await syncProtocol.encryptPayload(
        data: testData,
        dataType: SyncDataType.auditLogs,
        syncKey: syncKey,
        deviceId: 'device-1',
      );

      final isValid = syncProtocol.verifyChecksum(payload, testData);
      expect(isValid, isTrue);
    });

    test('should reject invalid checksum', () async {
      const testData = 'test data';
      const tamperedData = 'tampered data';
      final syncKey = keyDerivationService.generateSalt();

      final payload = await syncProtocol.encryptPayload(
        data: testData,
        dataType: SyncDataType.auditLogs,
        syncKey: syncKey,
        deviceId: 'device-1',
      );

      final isValid = syncProtocol.verifyChecksum(payload, tamperedData);
      expect(isValid, isFalse);
    });
  });

  group('SecureSyncProtocol - Device ID', () {
    test('should generate valid device ID', () {
      final deviceId = syncProtocol.generateDeviceId();

      expect(deviceId, isNotEmpty);
      expect(deviceId.contains('-'), isTrue); // UUID format
    });

    test('should generate unique device IDs', () {
      final deviceId1 = syncProtocol.generateDeviceId();
      final deviceId2 = syncProtocol.generateDeviceId();

      expect(deviceId1, isNot(deviceId2));
    });

    test('should generate UUID v4 format device IDs', () {
      final deviceId = syncProtocol.generateDeviceId();
      final parts = deviceId.split('-');

      expect(parts.length, 5); // UUID format: 8-4-4-4-12
    });
  });
}
