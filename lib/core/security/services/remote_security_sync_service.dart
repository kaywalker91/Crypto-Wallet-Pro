import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../../../shared/services/secure_storage_service.dart';
import '../../constants/storage_keys.dart';
import '../../error/failures.dart';
import '../audit/audit_event_type.dart';
import '../sync/secure_sync_protocol.dart';
import '../sync/sync_config.dart';
import '../sync/sync_conflict_resolver.dart';
import '../sync/sync_payload.dart';
import '../sync/sync_result.dart';
import 'security_audit_logger.dart';

/// 원격 보안 동기화 서비스.
///
/// **주요 기능:**
/// - E2E 암호화된 감사 로그 동기화
/// - 보안 설정 백업/복원
/// - 멀티 디바이스 지원
/// - 오프라인 큐잉
///
/// **동기화 흐름:**
/// ```
/// 1. prepareSyncData() → 로컬 변경사항 수집
/// 2. encryptAndSign()  → E2E 암호화 + 서명
/// 3. uploadToServer()  → HTTPS 업로드
/// 4. downloadChanges() → 원격 변경사항 다운로드
/// 5. resolveConflicts()→ 충돌 해결
/// 6. applyChanges()    → 로컬 적용
/// ```
///
/// **API 엔드포인트:**
/// - `POST /sync/upload`: 페이로드 업로드
/// - `GET /sync/download`: 페이로드 다운로드
/// - `POST /sync/devices`: 디바이스 등록
/// - `GET /sync/devices`: 디바이스 목록
/// - `DELETE /sync/devices/:id`: 디바이스 삭제
class RemoteSecuritySyncService {
  RemoteSecuritySyncService({
    required Dio dio,
    required SecureSyncProtocol syncProtocol,
    required SyncConflictResolver conflictResolver,
    required SecurityAuditLogger auditLogger,
    required SecureStorageService secureStorage,
    required SyncConfig config,
  })  : _dio = dio,
        _syncProtocol = syncProtocol,
        _conflictResolver = conflictResolver,
        _auditLogger = auditLogger,
        _secureStorage = secureStorage,
        _config = config;

  final Dio _dio;
  final SecureSyncProtocol _syncProtocol;
  final SyncConflictResolver _conflictResolver;
  final SecurityAuditLogger _auditLogger;
  final SecureStorageService _secureStorage;
  final SyncConfig _config;

  /// 전체 동기화를 수행합니다.
  ///
  /// **매개변수:**
  /// - [syncKey]: 동기화 키 (Base64)
  /// - [dataTypes]: 동기화할 데이터 유형 (null이면 활성화된 모든 유형)
  ///
  /// **반환값:**
  /// - 동기화 결과
  ///
  /// **예외:**
  /// - [NetworkFailure]: 네트워크 오류
  /// - [CryptographyFailure]: 암호화/복호화 오류
  Future<SyncResult> performSync({
    required String syncKey,
    Set<SyncDataType>? dataTypes,
  }) async {
    try {
      await _auditLogger.log(
        AuditEventType.securitySettingsChanged,
        metadata: {'action': 'sync_started'},
      );

      final effectiveDataTypes = dataTypes ?? _config.enabledDataTypes;
      int uploadedCount = 0;
      int downloadedCount = 0;
      final List<SyncConflict> conflicts = [];

      // 데이터 유형별 동기화
      for (final dataType in effectiveDataTypes) {
        if (!_config.isDataTypeEnabled(dataType)) continue;

        final result = await _syncDataType(
          dataType: dataType,
          syncKey: syncKey,
        );

        uploadedCount += result.uploadedCount;
        downloadedCount += result.downloadedCount;
        conflicts.addAll(result.conflicts);
      }

      // 오프라인 큐 처리
      await processOfflineQueue(syncKey: syncKey);

      final now = DateTime.now();
      await _saveLastSyncTime(now);

      await _auditLogger.log(
        AuditEventType.securitySettingsChanged,
        metadata: {
          'action': 'sync_completed',
          'uploaded': uploadedCount,
          'downloaded': downloadedCount,
          'conflicts': conflicts.length,
        },
      );

      if (conflicts.isEmpty) {
        return SyncResult.success(
          uploadedCount: uploadedCount,
          downloadedCount: downloadedCount,
          lastSyncTime: now,
        );
      } else {
        return SyncResult.partialSuccess(
          uploadedCount: uploadedCount,
          downloadedCount: downloadedCount,
          conflicts: conflicts,
          lastSyncTime: now,
        );
      }
    } catch (e) {
      await _auditLogger.logError(
        AuditEventType.securitySettingsChanged,
        e,
        metadata: {'action': 'sync_failed'},
      );

      if (e is DioException) {
        throw NetworkFailure('Sync failed: ${e.message}', cause: e);
      }
      if (e is Failure) rethrow;
      throw NetworkFailure('Sync failed', cause: e);
    }
  }

  /// 감사 로그를 동기화합니다.
  ///
  /// **매개변수:**
  /// - [syncKey]: 동기화 키 (Base64)
  ///
  /// **반환값:**
  /// - 동기화 결과
  Future<SyncResult> syncAuditLogs({required String syncKey}) async {
    return performSync(
      syncKey: syncKey,
      dataTypes: {SyncDataType.auditLogs},
    );
  }

  /// 보안 설정을 동기화합니다.
  ///
  /// **매개변수:**
  /// - [syncKey]: 동기화 키 (Base64)
  ///
  /// **반환값:**
  /// - 동기화 결과
  Future<SyncResult> syncSecuritySettings({required String syncKey}) async {
    return performSync(
      syncKey: syncKey,
      dataTypes: {SyncDataType.securitySettings},
    );
  }

  /// 동기화 상태를 조회합니다.
  ///
  /// **반환값:**
  /// - 현재 동기화 상태
  Future<SyncStatus> getSyncStatus() async {
    // 현재는 단순 구현 (향후 확장 가능)
    final lastSyncTime = await getLastSyncTime();
    if (lastSyncTime == null) {
      return SyncStatus.noChanges;
    }

    final now = DateTime.now();
    final diff = now.difference(lastSyncTime);

    if (diff > _config.syncInterval * 2) {
      return SyncStatus.failed; // 동기화 지연
    }

    return SyncStatus.success;
  }

  /// 마지막 동기화 시각을 조회합니다.
  ///
  /// **반환값:**
  /// - 마지막 동기화 시각 (없으면 `null`)
  Future<DateTime?> getLastSyncTime() async {
    final timeStr = await _secureStorage.read(StorageKeys.syncLastTime);
    if (timeStr == null || timeStr.isEmpty) {
      return null;
    }
    return DateTime.parse(timeStr);
  }

  /// 오프라인 큐를 처리합니다.
  ///
  /// **매개변수:**
  /// - [syncKey]: 동기화 키 (Base64)
  ///
  /// **동작:**
  /// - 오프라인 상태에서 쌓인 페이로드를 서버로 업로드
  /// - 성공 시 큐에서 제거
  /// - 실패 시 재시도 (최대 횟수 제한)
  Future<void> processOfflineQueue({required String syncKey}) async {
    final queue = await _loadOfflineQueue();
    if (queue.isEmpty) return;

    final List<SyncPayload> processed = [];

    for (final payload in queue) {
      try {
        await _uploadPayload(payload);
        processed.add(payload);
      } catch (e) {
        // 업로드 실패 시 큐에 유지
        await _auditLogger.logError(
          AuditEventType.securitySettingsChanged,
          e,
          metadata: {'action': 'offline_queue_upload_failed'},
        );
      }
    }

    // 성공한 페이로드는 큐에서 제거
    queue.removeWhere((p) => processed.contains(p));
    await _saveOfflineQueue(queue);
  }

  /// 디바이스를 등록합니다.
  ///
  /// **매개변수:**
  /// - [deviceId]: 디바이스 ID
  /// - [deviceName]: 디바이스 이름
  /// - [publicKey]: 공개 키 (향후 디바이스 간 암호화에 사용)
  Future<void> registerDevice({
    required String deviceId,
    required String deviceName,
    required String publicKey,
  }) async {
    try {
      await _dio.post(
        '${_config.serverUrl}/sync/devices',
        data: {
          'deviceId': deviceId,
          'deviceName': deviceName,
          'publicKey': publicKey,
          'registeredAt': DateTime.now().toIso8601String(),
        },
      );

      await _secureStorage.write(
        key: StorageKeys.syncDeviceId,
        value: deviceId,
        isSensitive: false,
      );

      await _auditLogger.log(
        AuditEventType.securitySettingsChanged,
        metadata: {'action': 'device_registered', 'deviceId': deviceId},
      );
    } catch (e) {
      if (e is DioException) {
        throw NetworkFailure('Device registration failed: ${e.message}');
      }
      throw NetworkFailure('Device registration failed', cause: e);
    }
  }

  /// 등록된 디바이스 목록을 조회합니다.
  ///
  /// **반환값:**
  /// - 디바이스 목록
  Future<List<SyncDevice>> getRegisteredDevices() async {
    try {
      final response = await _dio.get('${_config.serverUrl}/sync/devices');
      final List<dynamic> data = response.data as List<dynamic>;

      final currentDeviceId =
          await _secureStorage.read(StorageKeys.syncDeviceId);

      return data
          .map((e) => SyncDevice.fromJson(
                e as Map<String, dynamic>,
                currentDeviceId: currentDeviceId,
              ))
          .toList();
    } catch (e) {
      if (e is DioException) {
        throw NetworkFailure('Failed to get devices: ${e.message}');
      }
      throw NetworkFailure('Failed to get devices', cause: e);
    }
  }

  /// 특정 데이터 유형을 동기화합니다.
  Future<SyncResult> _syncDataType({
    required SyncDataType dataType,
    required String syncKey,
  }) async {
    // 1. 로컬 데이터 수집
    final localData = await _collectLocalData(dataType);
    if (localData.isEmpty) {
      return SyncResult.noChanges();
    }

    // 2. 암호화 및 페이로드 생성
    final deviceId = await _getOrCreateDeviceId();
    final payload = await _syncProtocol.encryptPayload(
      data: jsonEncode(localData),
      dataType: dataType,
      syncKey: syncKey,
      deviceId: deviceId,
    );

    // 3. 서버 업로드
    try {
      await _uploadPayload(payload);
    } catch (e) {
      // 오프라인 큐에 추가
      await _addToOfflineQueue(payload);
      return SyncResult.failure(errorMessage: 'Upload failed, queued offline');
    }

    // 4. 원격 변경사항 다운로드 (현재는 단순 구현)
    // 향후 마지막 동기화 시각 이후 변경사항만 다운로드 가능

    return SyncResult.success(
      uploadedCount: 1,
      downloadedCount: 0,
      lastSyncTime: DateTime.now(),
    );
  }

  /// 로컬 데이터를 수집합니다.
  Future<Map<String, dynamic>> _collectLocalData(SyncDataType dataType) async {
    switch (dataType) {
      case SyncDataType.auditLogs:
        final logs = await _auditLogger.getLogs(limit: 100);
        return {'logs': logs.map((e) => e.toJson()).toList()};

      case SyncDataType.securitySettings:
        // 향후 구현: 보안 설정 수집
        return {};

      case SyncDataType.deviceRegistry:
      case SyncDataType.backupMetadata:
        // 향후 구현
        return {};
    }
  }

  /// 페이로드를 서버에 업로드합니다.
  Future<void> _uploadPayload(SyncPayload payload) async {
    await _dio.post(
      '${_config.serverUrl}/sync/upload',
      data: payload.toJson(),
    );
  }

  /// 디바이스 ID를 가져오거나 생성합니다.
  Future<String> _getOrCreateDeviceId() async {
    var deviceId = await _secureStorage.read(StorageKeys.syncDeviceId);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _syncProtocol.generateDeviceId();
      await _secureStorage.write(
        key: StorageKeys.syncDeviceId,
        value: deviceId,
        isSensitive: false,
      );
    }
    return deviceId;
  }

  /// 오프라인 큐를 로드합니다.
  Future<List<SyncPayload>> _loadOfflineQueue() async {
    final json = await _secureStorage.read(StorageKeys.syncOfflineQueue);
    if (json == null || json.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((e) => SyncPayload.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 오프라인 큐를 저장합니다.
  Future<void> _saveOfflineQueue(List<SyncPayload> queue) async {
    final json = jsonEncode(queue.map((e) => e.toJson()).toList());
    await _secureStorage.write(
      key: StorageKeys.syncOfflineQueue,
      value: json,
      isSensitive: false,
    );
  }

  /// 오프라인 큐에 추가합니다.
  Future<void> _addToOfflineQueue(SyncPayload payload) async {
    final queue = await _loadOfflineQueue();

    // 큐 크기 제한 확인
    if (queue.length >= _config.maxOfflineQueueSize) {
      // 가장 오래된 것 제거
      queue.removeAt(0);
    }

    queue.add(payload);
    await _saveOfflineQueue(queue);
  }

  /// 마지막 동기화 시각을 저장합니다.
  Future<void> _saveLastSyncTime(DateTime time) async {
    await _secureStorage.write(
      key: StorageKeys.syncLastTime,
      value: time.toIso8601String(),
      isSensitive: false,
    );
  }
}

/// 동기화 디바이스 정보.
class SyncDevice with EquatableMixin {
  const SyncDevice({
    required this.deviceId,
    required this.deviceName,
    required this.publicKey,
    required this.registeredAt,
    this.lastSyncAt,
    required this.isCurrentDevice,
  });

  /// 디바이스 ID.
  final String deviceId;

  /// 디바이스 이름.
  final String deviceName;

  /// 공개 키.
  final String publicKey;

  /// 등록 시각.
  final DateTime registeredAt;

  /// 마지막 동기화 시각.
  final DateTime? lastSyncAt;

  /// 현재 디바이스 여부.
  final bool isCurrentDevice;

  /// JSON으로 변환합니다.
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'publicKey': publicKey,
      'registeredAt': registeredAt.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }

  /// JSON에서 생성합니다.
  factory SyncDevice.fromJson(
    Map<String, dynamic> json, {
    String? currentDeviceId,
  }) {
    return SyncDevice(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      publicKey: json['publicKey'] as String,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null,
      isCurrentDevice: json['deviceId'] == currentDeviceId,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        deviceName,
        publicKey,
        registeredAt,
        lastSyncAt,
        isCurrentDevice,
      ];

  @override
  String toString() {
    return 'SyncDevice('
        'deviceId: ${deviceId.substring(0, 8)}..., '
        'deviceName: $deviceName, '
        'isCurrentDevice: $isCurrentDevice'
        ')';
  }
}
