import 'package:crypto_wallet_pro/core/security/sync/sync_payload.dart';
import 'package:crypto_wallet_pro/core/security/sync/sync_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncResult', () {
    test('should create success result', () {
      final now = DateTime.now();
      final result = SyncResult.success(
        uploadedCount: 5,
        downloadedCount: 3,
        lastSyncTime: now,
      );

      expect(result.status, SyncStatus.success);
      expect(result.uploadedCount, 5);
      expect(result.downloadedCount, 3);
      expect(result.conflictCount, 0);
      expect(result.conflicts, isEmpty);
      expect(result.lastSyncTime, now);
      expect(result.errorMessage, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.requiresConflictResolution, isFalse);
    });

    test('should create failure result', () {
      final result = SyncResult.failure(errorMessage: 'Network error');

      expect(result.status, SyncStatus.failed);
      expect(result.uploadedCount, 0);
      expect(result.downloadedCount, 0);
      expect(result.conflictCount, 0);
      expect(result.conflicts, isEmpty);
      expect(result.errorMessage, 'Network error');
      expect(result.isSuccess, isFalse);
    });

    test('should create partial success result with conflicts', () {
      final now = DateTime.now();
      final conflicts = [
        SyncConflict(
          payloadId: 'payload-1',
          dataType: SyncDataType.auditLogs,
          resolution: ConflictResolution.keepLocal,
          localTimestamp: now.subtract(const Duration(minutes: 1)),
          remoteTimestamp: now,
        ),
      ];

      final result = SyncResult.partialSuccess(
        uploadedCount: 2,
        downloadedCount: 1,
        conflicts: conflicts,
        lastSyncTime: now,
      );

      expect(result.status, SyncStatus.partialSuccess);
      expect(result.uploadedCount, 2);
      expect(result.downloadedCount, 1);
      expect(result.conflictCount, 1);
      expect(result.conflicts, conflicts);
      expect(result.lastSyncTime, now);
      expect(result.requiresConflictResolution, isTrue);
    });

    test('should create no changes result', () {
      final result = SyncResult.noChanges();

      expect(result.status, SyncStatus.noChanges);
      expect(result.uploadedCount, 0);
      expect(result.downloadedCount, 0);
      expect(result.conflictCount, 0);
      expect(result.isSuccess, isTrue);
    });

    test('should create conflict result', () {
      final conflict = SyncConflict(
        payloadId: 'payload-1',
        dataType: SyncDataType.securitySettings,
        resolution: ConflictResolution.pending,
        localTimestamp: DateTime.now(),
        remoteTimestamp: DateTime.now(),
      );

      final result = SyncResult.conflict(conflicts: [conflict]);

      expect(result.status, SyncStatus.conflict);
      expect(result.conflictCount, 1);
      expect(result.requiresConflictResolution, isTrue);
    });
  });

  group('SyncConflict', () {
    late DateTime localTime;
    late DateTime remoteTime;
    late SyncConflict testConflict;

    setUp(() {
      localTime = DateTime.utc(2024, 1, 15, 10, 0, 0);
      remoteTime = DateTime.utc(2024, 1, 15, 10, 5, 0);

      testConflict = SyncConflict(
        payloadId: 'test-payload',
        dataType: SyncDataType.auditLogs,
        resolution: ConflictResolution.keepLocal,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );
    });

    test('should create conflict with all required fields', () {
      expect(testConflict.payloadId, 'test-payload');
      expect(testConflict.dataType, SyncDataType.auditLogs);
      expect(testConflict.resolution, ConflictResolution.keepLocal);
      expect(testConflict.localTimestamp, localTime);
      expect(testConflict.remoteTimestamp, remoteTime);
    });

    test('should determine which version is newer', () {
      expect(testConflict.isLocalNewer, isFalse);
      expect(testConflict.isRemoteNewer, isTrue);

      final reverseConflict = SyncConflict(
        payloadId: 'test',
        dataType: SyncDataType.auditLogs,
        resolution: ConflictResolution.keepRemote,
        localTimestamp: remoteTime,
        remoteTimestamp: localTime,
      );

      expect(reverseConflict.isLocalNewer, isTrue);
      expect(reverseConflict.isRemoteNewer, isFalse);
    });

    test('should identify manual resolution requirement', () {
      final manualConflict = testConflict.copyWith(
        resolution: ConflictResolution.pending,
      );

      expect(testConflict.requiresManualResolution, isFalse);
      expect(manualConflict.requiresManualResolution, isTrue);
    });

    test('should support equality comparison', () {
      final conflict1 = SyncConflict(
        payloadId: 'id-1',
        dataType: SyncDataType.auditLogs,
        resolution: ConflictResolution.keepLocal,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      final conflict2 = SyncConflict(
        payloadId: 'id-1',
        dataType: SyncDataType.auditLogs,
        resolution: ConflictResolution.keepLocal,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(conflict1, conflict2);
    });
  });

  group('SyncStatus Extension', () {
    test('should return correct display names', () {
      expect(SyncStatus.success.displayName, 'Success');
      expect(SyncStatus.failed.displayName, 'Failed');
      expect(SyncStatus.partialSuccess.displayName, 'Partial Success');
      expect(SyncStatus.noChanges.displayName, 'No Changes');
      expect(SyncStatus.conflict.displayName, 'Conflict');
    });

    test('should identify successful statuses', () {
      expect(SyncStatus.success.isSuccessful, isTrue);
      expect(SyncStatus.noChanges.isSuccessful, isTrue);
      expect(SyncStatus.failed.isSuccessful, isFalse);
      expect(SyncStatus.partialSuccess.isSuccessful, isFalse);
      expect(SyncStatus.conflict.isSuccessful, isFalse);
    });
  });

  group('ConflictResolution Extension', () {
    test('should return correct display names', () {
      expect(ConflictResolution.keepLocal.displayName, 'Keep Local');
      expect(ConflictResolution.keepRemote.displayName, 'Keep Remote');
      expect(ConflictResolution.merge.displayName, 'Merge');
      expect(ConflictResolution.pending.displayName, 'Pending');
    });
  });
}

// Helper extension for testing
extension SyncConflictCopyWith on SyncConflict {
  SyncConflict copyWith({
    String? payloadId,
    SyncDataType? dataType,
    ConflictResolution? resolution,
    DateTime? localTimestamp,
    DateTime? remoteTimestamp,
  }) {
    return SyncConflict(
      payloadId: payloadId ?? this.payloadId,
      dataType: dataType ?? this.dataType,
      resolution: resolution ?? this.resolution,
      localTimestamp: localTimestamp ?? this.localTimestamp,
      remoteTimestamp: remoteTimestamp ?? this.remoteTimestamp,
      localPayload: localPayload,
      remotePayload: remotePayload,
    );
  }
}
