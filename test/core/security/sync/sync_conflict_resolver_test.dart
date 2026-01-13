import 'package:crypto_wallet_pro/core/security/sync/sync_config.dart';
import 'package:crypto_wallet_pro/core/security/sync/sync_conflict_resolver.dart';
import 'package:crypto_wallet_pro/core/security/sync/sync_payload.dart';
import 'package:crypto_wallet_pro/core/security/sync/sync_result.dart';
import 'package:crypto_wallet_pro/shared/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SyncConflictResolver resolver;
  late SecureStorageService secureStorage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    secureStorage = SecureStorageService(
      const FlutterSecureStorage(),
    );
  });

  group('SyncConflictResolver - Last Write Wins', () {
    late SyncPayload localPayload;
    late SyncPayload remotePayload;

    setUp(() {
      resolver = SyncConflictResolver(
        secureStorage: secureStorage,
        defaultStrategy: ConflictStrategy.lastWriteWins,
      );

      final now = DateTime.now();
      localPayload = SyncPayload(
        id: 'payload-1',
        dataType: SyncDataType.auditLogs,
        encryptedData: 'local-data',
        iv: 'iv-local',
        authTag: 'tag-local',
        version: 1,
        timestamp: now.subtract(const Duration(minutes: 5)),
        deviceId: 'device-local',
        checksum: 'checksum-local',
      );

      remotePayload = SyncPayload(
        id: 'payload-1',
        dataType: SyncDataType.auditLogs,
        encryptedData: 'remote-data',
        iv: 'iv-remote',
        authTag: 'tag-remote',
        version: 1,
        timestamp: now,
        deviceId: 'device-remote',
        checksum: 'checksum-remote',
      );
    });

    test('should keep remote when it is newer', () async {
      final conflict = await resolver.resolveConflict(
        localPayload: localPayload,
        remotePayload: remotePayload,
      );

      expect(conflict.resolution, ConflictResolution.keepRemote);
      expect(conflict.payloadId, 'payload-1');
      expect(conflict.dataType, SyncDataType.auditLogs);
    });

    test('should keep local when it is newer', () async {
      final conflict = await resolver.resolveConflict(
        localPayload: remotePayload, // Swap to make local newer
        remotePayload: localPayload,
      );

      expect(conflict.resolution, ConflictResolution.keepLocal);
    });

    test('should keep local when timestamps are equal', () async {
      final sameTime = DateTime.now();
      final local = localPayload.copyWith(timestamp: sameTime);
      final remote = remotePayload.copyWith(timestamp: sameTime);

      final conflict = await resolver.resolveConflict(
        localPayload: local,
        remotePayload: remote,
      );

      expect(conflict.resolution, ConflictResolution.keepLocal);
    });
  });

  group('SyncConflictResolver - Local First', () {
    late SyncPayload localPayload;
    late SyncPayload remotePayload;

    setUp(() {
      resolver = SyncConflictResolver(
        secureStorage: secureStorage,
        defaultStrategy: ConflictStrategy.localFirst,
      );

      final now = DateTime.now();
      localPayload = SyncPayload(
        id: 'payload-1',
        dataType: SyncDataType.securitySettings,
        encryptedData: 'local-data',
        iv: 'iv-local',
        authTag: 'tag-local',
        version: 1,
        timestamp: now.subtract(const Duration(minutes: 5)),
        deviceId: 'device-local',
        checksum: 'checksum-local',
      );

      remotePayload = localPayload.copyWith(
        encryptedData: 'remote-data',
        timestamp: now,
      );
    });

    test('should always keep local', () async {
      final conflict = await resolver.resolveConflict(
        localPayload: localPayload,
        remotePayload: remotePayload,
      );

      expect(conflict.resolution, ConflictResolution.keepLocal);
    });

    test('should keep local even when remote is newer', () async {
      expect(remotePayload.timestamp.isAfter(localPayload.timestamp), isTrue);

      final conflict = await resolver.resolveConflict(
        localPayload: localPayload,
        remotePayload: remotePayload,
        strategy: ConflictStrategy.localFirst,
      );

      expect(conflict.resolution, ConflictResolution.keepLocal);
    });
  });

  group('SyncConflictResolver - Remote First', () {
    late SyncPayload localPayload;
    late SyncPayload remotePayload;

    setUp(() {
      resolver = SyncConflictResolver(
        secureStorage: secureStorage,
        defaultStrategy: ConflictStrategy.remoteFirst,
      );

      final now = DateTime.now();
      localPayload = SyncPayload(
        id: 'payload-1',
        dataType: SyncDataType.deviceRegistry,
        encryptedData: 'local-data',
        iv: 'iv-local',
        authTag: 'tag-local',
        version: 1,
        timestamp: now,
        deviceId: 'device-local',
        checksum: 'checksum-local',
      );

      remotePayload = localPayload.copyWith(
        encryptedData: 'remote-data',
        timestamp: now.subtract(const Duration(minutes: 5)),
      );
    });

    test('should always keep remote', () async {
      final conflict = await resolver.resolveConflict(
        localPayload: localPayload,
        remotePayload: remotePayload,
      );

      expect(conflict.resolution, ConflictResolution.keepRemote);
    });

    test('should keep remote even when local is newer', () async {
      expect(localPayload.timestamp.isAfter(remotePayload.timestamp), isTrue);

      final conflict = await resolver.resolveConflict(
        localPayload: localPayload,
        remotePayload: remotePayload,
        strategy: ConflictStrategy.remoteFirst,
      );

      expect(conflict.resolution, ConflictResolution.keepRemote);
    });
  });

  group('SyncConflictResolver - Manual Resolution', () {
    late SyncPayload localPayload;
    late SyncPayload remotePayload;

    setUp(() {
      resolver = SyncConflictResolver(
        secureStorage: secureStorage,
        defaultStrategy: ConflictStrategy.manual,
      );

      final now = DateTime.now();
      localPayload = SyncPayload(
        id: 'payload-1',
        dataType: SyncDataType.backupMetadata,
        encryptedData: 'local-data',
        iv: 'iv-local',
        authTag: 'tag-local',
        version: 1,
        timestamp: now,
        deviceId: 'device-local',
        checksum: 'checksum-local',
      );

      remotePayload = localPayload.copyWith(
        encryptedData: 'remote-data',
        timestamp: now.add(const Duration(seconds: 1)),  // Different timestamp for conflict
      );
    });

    test('should set resolution to pending for manual conflicts', () async {
      final conflict = await resolver.resolveConflict(
        localPayload: localPayload,
        remotePayload: remotePayload,
        strategy: ConflictStrategy.manual,  // Explicitly set manual strategy
      );

      expect(conflict.resolution, ConflictResolution.pending);
      expect(conflict.requiresManualResolution, isTrue);
    });

    test('should queue conflict for manual resolution', () async {
      final conflict = await resolver.resolveConflict(
        localPayload: localPayload,
        remotePayload: remotePayload,
        strategy: ConflictStrategy.manual,  // Explicitly set manual strategy
      );

      // Give time for async queueing
      await Future.delayed(const Duration(milliseconds: 100));

      final pending = await resolver.getPendingConflicts();
      expect(pending, isNotEmpty);
      expect(pending.any((c) => c.payloadId == conflict.payloadId), isTrue);
    });
  });

  group('SyncConflictResolver - Manual Conflict Queue', () {
    setUp(() {
      resolver = SyncConflictResolver(
        secureStorage: secureStorage,
        defaultStrategy: ConflictStrategy.lastWriteWins,
      );
    });

    test('should add conflict to queue', () async {
      final conflict = SyncConflict(
        payloadId: 'payload-1',
        dataType: SyncDataType.auditLogs,
        resolution: ConflictResolution.pending,
        localTimestamp: DateTime.now(),
        remoteTimestamp: DateTime.now(),
      );

      await resolver.queueForManualResolution(conflict);

      final pending = await resolver.getPendingConflicts();
      expect(pending.length, 1);
      expect(pending.first.payloadId, 'payload-1');
    });

    test('should retrieve all pending conflicts', () async {
      final conflict1 = SyncConflict(
        payloadId: 'payload-1',
        dataType: SyncDataType.auditLogs,
        resolution: ConflictResolution.pending,
        localTimestamp: DateTime.now(),
        remoteTimestamp: DateTime.now(),
      );

      final conflict2 = SyncConflict(
        payloadId: 'payload-2',
        dataType: SyncDataType.securitySettings,
        resolution: ConflictResolution.pending,
        localTimestamp: DateTime.now(),
        remoteTimestamp: DateTime.now(),
      );

      await resolver.queueForManualResolution(conflict1);
      await resolver.queueForManualResolution(conflict2);

      final pending = await resolver.getPendingConflicts();
      expect(pending.length, 2);
    });

    test('should resolve and remove conflict from queue', () async {
      final conflict = SyncConflict(
        payloadId: 'payload-1',
        dataType: SyncDataType.auditLogs,
        resolution: ConflictResolution.pending,
        localTimestamp: DateTime.now(),
        remoteTimestamp: DateTime.now(),
      );

      await resolver.queueForManualResolution(conflict);

      var pending = await resolver.getPendingConflicts();
      expect(pending.length, 1);

      await resolver.resolveManualConflict(
        payloadId: 'payload-1',
        resolution: ConflictResolution.keepLocal,
      );

      pending = await resolver.getPendingConflicts();
      expect(pending, isEmpty);
    });

    test('should clear all pending conflicts', () async {
      final conflict1 = SyncConflict(
        payloadId: 'payload-1',
        dataType: SyncDataType.auditLogs,
        resolution: ConflictResolution.pending,
        localTimestamp: DateTime.now(),
        remoteTimestamp: DateTime.now(),
      );

      final conflict2 = SyncConflict(
        payloadId: 'payload-2',
        dataType: SyncDataType.securitySettings,
        resolution: ConflictResolution.pending,
        localTimestamp: DateTime.now(),
        remoteTimestamp: DateTime.now(),
      );

      await resolver.queueForManualResolution(conflict1);
      await resolver.queueForManualResolution(conflict2);

      await resolver.clearPendingConflicts();

      final pending = await resolver.getPendingConflicts();
      expect(pending, isEmpty);
    });
  });

  group('SyncConflictResolver - Auto Merge', () {
    late SyncPayload localPayload;
    late SyncPayload remotePayload;

    setUp(() {
      resolver = SyncConflictResolver(
        secureStorage: secureStorage,
        defaultStrategy: ConflictStrategy.lastWriteWins,
      );

      final now = DateTime.now();
      localPayload = SyncPayload(
        id: 'payload-1',
        dataType: SyncDataType.auditLogs,
        encryptedData: 'local-data',
        iv: 'iv-local',
        authTag: 'tag-local',
        version: 1,
        timestamp: now,
        deviceId: 'device-local',
        checksum: 'checksum-local',
      );

      remotePayload = localPayload.copyWith(encryptedData: 'remote-data');
    });

    test('should return null for incompatible data types', () async {
      final incompatibleRemote = remotePayload.copyWith(
        dataType: SyncDataType.securitySettings,
      );

      final merged = await resolver.attemptAutoMerge(
        localPayload: localPayload,
        remotePayload: incompatibleRemote,
      );

      expect(merged, isNull);
    });

    test('should return null when auto merge is not implemented', () async {
      // Currently auto-merge is not implemented
      final merged = await resolver.attemptAutoMerge(
        localPayload: localPayload,
        remotePayload: remotePayload,
      );

      expect(merged, isNull);
    });
  });
}
