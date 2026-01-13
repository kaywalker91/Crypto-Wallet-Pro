import 'package:crypto_wallet_pro/core/security/sync/sync_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncPayload', () {
    late SyncPayload testPayload;

    setUp(() {
      testPayload = SyncPayload(
        id: 'test-id-123',
        dataType: SyncDataType.auditLogs,
        encryptedData: 'encrypted-data-base64',
        iv: 'iv-base64',
        authTag: 'tag-base64',
        version: 1,
        timestamp: DateTime.utc(2024, 1, 15, 10, 30, 0),
        deviceId: 'device-abc-123',
        checksum: 'checksum-sha256',
      );
    });

    test('should create SyncPayload with all required fields', () {
      expect(testPayload.id, 'test-id-123');
      expect(testPayload.dataType, SyncDataType.auditLogs);
      expect(testPayload.encryptedData, 'encrypted-data-base64');
      expect(testPayload.iv, 'iv-base64');
      expect(testPayload.authTag, 'tag-base64');
      expect(testPayload.version, 1);
      expect(testPayload.timestamp, DateTime.utc(2024, 1, 15, 10, 30, 0));
      expect(testPayload.deviceId, 'device-abc-123');
      expect(testPayload.checksum, 'checksum-sha256');
    });

    test('should serialize to JSON correctly', () {
      final json = testPayload.toJson();

      expect(json['id'], 'test-id-123');
      expect(json['dataType'], 'auditLogs');
      expect(json['encryptedData'], 'encrypted-data-base64');
      expect(json['iv'], 'iv-base64');
      expect(json['authTag'], 'tag-base64');
      expect(json['version'], 1);
      expect(json['timestamp'], '2024-01-15T10:30:00.000Z');
      expect(json['deviceId'], 'device-abc-123');
      expect(json['checksum'], 'checksum-sha256');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id-456',
        'dataType': 'securitySettings',
        'encryptedData': 'encrypted-settings',
        'iv': 'iv-456',
        'authTag': 'tag-456',
        'version': 2,
        'timestamp': '2024-01-15T12:00:00.000Z',
        'deviceId': 'device-xyz-789',
        'checksum': 'checksum-456',
      };

      final payload = SyncPayload.fromJson(json);

      expect(payload.id, 'test-id-456');
      expect(payload.dataType, SyncDataType.securitySettings);
      expect(payload.encryptedData, 'encrypted-settings');
      expect(payload.iv, 'iv-456');
      expect(payload.authTag, 'tag-456');
      expect(payload.version, 2);
      expect(payload.timestamp, DateTime.utc(2024, 1, 15, 12, 0, 0));
      expect(payload.deviceId, 'device-xyz-789');
      expect(payload.checksum, 'checksum-456');
    });

    test('should support round-trip JSON serialization', () {
      final json = testPayload.toJson();
      final deserialized = SyncPayload.fromJson(json);

      expect(deserialized, testPayload);
    });

    test('should create copy with modified fields', () {
      final copy = testPayload.copyWith(
        version: 2,
        checksum: 'new-checksum',
      );

      expect(copy.id, testPayload.id);
      expect(copy.version, 2);
      expect(copy.checksum, 'new-checksum');
      expect(copy.encryptedData, testPayload.encryptedData);
    });

    test('should support equality comparison', () {
      final payload1 = SyncPayload(
        id: 'id-1',
        dataType: SyncDataType.auditLogs,
        encryptedData: 'data-1',
        iv: 'iv-1',
        authTag: 'tag-1',
        version: 1,
        timestamp: DateTime.utc(2024, 1, 15, 10, 0, 0),
        deviceId: 'device-1',
        checksum: 'checksum-1',
      );

      final payload2 = SyncPayload(
        id: 'id-1',
        dataType: SyncDataType.auditLogs,
        encryptedData: 'data-1',
        iv: 'iv-1',
        authTag: 'tag-1',
        version: 1,
        timestamp: DateTime.utc(2024, 1, 15, 10, 0, 0),
        deviceId: 'device-1',
        checksum: 'checksum-1',
      );

      final payload3 = payload1.copyWith(version: 2);

      expect(payload1, payload2);
      expect(payload1, isNot(payload3));
    });

    test('should mask sensitive data in toString', () {
      final str = testPayload.toString();

      expect(str, contains('SyncPayload'));
      expect(str, contains('id: test-id-123'));
      expect(str, contains('dataType: auditLogs'));
      expect(str, contains('version: 1'));
      expect(str, contains('deviceId: device-a')); // Truncated
      expect(str, contains('[REDACTED]')); // Encrypted data masked
      expect(str, contains('checksum:')); // Checksum truncated
    });

    test('should validate all SyncDataType values', () {
      for (final dataType in SyncDataType.values) {
        final payload = testPayload.copyWith(dataType: dataType);
        final json = payload.toJson();
        final deserialized = SyncPayload.fromJson(json);

        expect(deserialized.dataType, dataType);
      }
    });
  });

  group('SyncDataType Extension', () {
    test('should return correct display names', () {
      expect(SyncDataType.auditLogs.displayName, 'Audit Logs');
      expect(SyncDataType.securitySettings.displayName, 'Security Settings');
      expect(SyncDataType.deviceRegistry.displayName, 'Device Registry');
      expect(SyncDataType.backupMetadata.displayName, 'Backup Metadata');
    });

    test('should identify sensitive data types', () {
      expect(SyncDataType.auditLogs.isSensitive, isTrue);
      expect(SyncDataType.securitySettings.isSensitive, isTrue);
      expect(SyncDataType.deviceRegistry.isSensitive, isFalse);
      expect(SyncDataType.backupMetadata.isSensitive, isFalse);
    });
  });
}
