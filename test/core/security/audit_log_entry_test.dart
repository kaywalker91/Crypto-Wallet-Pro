import 'package:crypto_wallet_pro/core/security/audit/audit_event_type.dart';
import 'package:crypto_wallet_pro/core/security/audit/audit_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuditLogEntry', () {
    final timestamp = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('should create entry with required fields', () {
        final entry = AuditLogEntry(
          id: 'test-id',
          timestamp: timestamp,
          eventType: AuditEventType.authBiometricSuccess,
        );

        expect(entry.id, 'test-id');
        expect(entry.timestamp, timestamp);
        expect(entry.eventType, AuditEventType.authBiometricSuccess);
        expect(entry.metadata, isEmpty);
        expect(entry.errorMessage, isNull);
        expect(entry.stackTrace, isNull);
        expect(entry.isEncrypted, false);
      });

      test('should create entry with all fields', () {
        final entry = AuditLogEntry(
          id: 'test-id',
          timestamp: timestamp,
          eventType: AuditEventType.decryptionFailed,
          metadata: {'key': 'value'},
          errorMessage: 'Test error',
          stackTrace: 'Test stack trace',
          isEncrypted: true,
        );

        expect(entry.id, 'test-id');
        expect(entry.timestamp, timestamp);
        expect(entry.eventType, AuditEventType.decryptionFailed);
        expect(entry.metadata, {'key': 'value'});
        expect(entry.errorMessage, 'Test error');
        expect(entry.stackTrace, 'Test stack trace');
        expect(entry.isEncrypted, true);
      });
    });

    group('computed properties', () {
      test('should get severity from eventType', () {
        final successEntry = AuditLogEntry(
          id: 'id1',
          timestamp: timestamp,
          eventType: AuditEventType.authBiometricSuccess,
        );
        expect(successEntry.severity, AuditSeverity.info);

        final failedEntry = AuditLogEntry(
          id: 'id2',
          timestamp: timestamp,
          eventType: AuditEventType.authPinFailed,
        );
        expect(failedEntry.severity, AuditSeverity.critical);
      });

      test('should get category from eventType', () {
        final authEntry = AuditLogEntry(
          id: 'id1',
          timestamp: timestamp,
          eventType: AuditEventType.authBiometricSuccess,
        );
        expect(authEntry.category, 'authentication');

        final walletEntry = AuditLogEntry(
          id: 'id2',
          timestamp: timestamp,
          eventType: AuditEventType.walletCreated,
        );
        expect(walletEntry.category, 'wallet');
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final entry = AuditLogEntry(
          id: 'test-id',
          timestamp: timestamp,
          eventType: AuditEventType.authBiometricSuccess,
          metadata: {'deviceId': '123'},
        );

        final json = entry.toJson();

        expect(json['id'], 'test-id');
        expect(json['timestamp'], timestamp.toIso8601String());
        expect(json['eventType'], 'authBiometricSuccess');
        expect(json['severity'], 'info');
        expect(json['category'], 'authentication');
        expect(json['metadata'], {'deviceId': '123'});
        expect(json['errorMessage'], isNull);
        expect(json['stackTrace'], isNull);
        expect(json['isEncrypted'], false);
      });

      test('should serialize error fields', () {
        final entry = AuditLogEntry(
          id: 'test-id',
          timestamp: timestamp,
          eventType: AuditEventType.decryptionFailed,
          errorMessage: 'Decryption failed',
          stackTrace: 'Stack trace here',
        );

        final json = entry.toJson();

        expect(json['errorMessage'], 'Decryption failed');
        expect(json['stackTrace'], 'Stack trace here');
      });
    });

    group('fromJson', () {
      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-id',
          'timestamp': timestamp.toIso8601String(),
          'eventType': 'authBiometricSuccess',
          'severity': 'info',
          'category': 'authentication',
          'metadata': {'deviceId': '123'},
          'errorMessage': null,
          'stackTrace': null,
          'isEncrypted': false,
        };

        final entry = AuditLogEntry.fromJson(json);

        expect(entry.id, 'test-id');
        expect(entry.timestamp, timestamp);
        expect(entry.eventType, AuditEventType.authBiometricSuccess);
        expect(entry.metadata, {'deviceId': '123'});
        expect(entry.errorMessage, isNull);
        expect(entry.isEncrypted, false);
      });

      test('should deserialize with error fields', () {
        final json = {
          'id': 'test-id',
          'timestamp': timestamp.toIso8601String(),
          'eventType': 'decryptionFailed',
          'severity': 'critical',
          'category': 'encryption',
          'metadata': {},
          'errorMessage': 'Test error',
          'stackTrace': 'Test stack',
          'isEncrypted': true,
        };

        final entry = AuditLogEntry.fromJson(json);

        expect(entry.errorMessage, 'Test error');
        expect(entry.stackTrace, 'Test stack');
        expect(entry.isEncrypted, true);
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'test-id',
          'timestamp': timestamp.toIso8601String(),
          'eventType': 'walletCreated',
        };

        final entry = AuditLogEntry.fromJson(json);

        expect(entry.metadata, isEmpty);
        expect(entry.errorMessage, isNull);
        expect(entry.stackTrace, isNull);
        expect(entry.isEncrypted, false);
      });

      test('should throw on unknown event type', () {
        final json = {
          'id': 'test-id',
          'timestamp': timestamp.toIso8601String(),
          'eventType': 'unknownEventType',
        };

        expect(
          () => AuditLogEntry.fromJson(json),
          throwsArgumentError,
        );
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = AuditLogEntry(
          id: 'id1',
          timestamp: timestamp,
          eventType: AuditEventType.walletCreated,
          metadata: {'key': 'value'},
        );

        final copied = original.copyWith(
          id: 'id2',
          errorMessage: 'New error',
        );

        expect(copied.id, 'id2');
        expect(copied.timestamp, timestamp);
        expect(copied.eventType, AuditEventType.walletCreated);
        expect(copied.metadata, {'key': 'value'});
        expect(copied.errorMessage, 'New error');
      });

      test('should keep original values when not specified', () {
        final original = AuditLogEntry(
          id: 'id1',
          timestamp: timestamp,
          eventType: AuditEventType.walletCreated,
          isEncrypted: true,
        );

        final copied = original.copyWith();

        expect(copied.id, 'id1');
        expect(copied.isEncrypted, true);
      });
    });

    group('equality', () {
      test('should be equal with same values', () {
        final entry1 = AuditLogEntry(
          id: 'id1',
          timestamp: timestamp,
          eventType: AuditEventType.walletCreated,
          metadata: {'key': 'value'},
        );

        final entry2 = AuditLogEntry(
          id: 'id1',
          timestamp: timestamp,
          eventType: AuditEventType.walletCreated,
          metadata: {'key': 'value'},
        );

        expect(entry1, equals(entry2));
      });

      test('should not be equal with different values', () {
        final entry1 = AuditLogEntry(
          id: 'id1',
          timestamp: timestamp,
          eventType: AuditEventType.walletCreated,
        );

        final entry2 = AuditLogEntry(
          id: 'id2',
          timestamp: timestamp,
          eventType: AuditEventType.walletCreated,
        );

        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final entry = AuditLogEntry(
          id: 'test-id',
          timestamp: timestamp,
          eventType: AuditEventType.authBiometricSuccess,
        );

        final string = entry.toString();

        expect(string, contains('test-id'));
        expect(string, contains('authBiometricSuccess'));
        expect(string, contains('info'));
        expect(string, contains('authentication'));
      });
    });

    group('JSON round-trip', () {
      test('should maintain data integrity after round-trip', () {
        final original = AuditLogEntry(
          id: 'test-id',
          timestamp: timestamp,
          eventType: AuditEventType.transactionSigned,
          metadata: {'txHash': '0x123', 'amount': '1.5'},
          isEncrypted: true,
        );

        final json = original.toJson();
        final restored = AuditLogEntry.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}
