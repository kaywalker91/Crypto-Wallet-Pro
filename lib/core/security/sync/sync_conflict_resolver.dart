import 'dart:convert';

import '../../../shared/services/secure_storage_service.dart';
import 'sync_config.dart';
import 'sync_payload.dart';
import 'sync_result.dart';

/// 동기화 충돌 해결기.
///
/// **충돌 해결 전략:**
/// 1. **Last Write Wins**: 타임스탬프 기반 자동 해결
/// 2. **Local First**: 항상 로컬 데이터 유지
/// 3. **Remote First**: 항상 원격 데이터 유지
/// 4. **Manual**: 사용자 수동 해결
///
/// **충돌 시나리오:**
/// ```
/// Device A                 Device B
///    │                        │
///    ├─> Update v1 (10:00)    │
///    │                        ├─> Update v1 (10:05)
///    │                        │
///    ├─> Sync (10:10) ────────┼─> Conflict!
///    │   (v1 @ 10:00)         │   (v1 @ 10:05)
///    │                        │
///    └─> Resolve ─────────────┴─> Keep Latest (10:05)
/// ```
class SyncConflictResolver {
  SyncConflictResolver({
    required SecureStorageService secureStorage,
    required ConflictStrategy defaultStrategy,
  })  : _secureStorage = secureStorage,
        _defaultStrategy = defaultStrategy;

  final SecureStorageService _secureStorage;
  final ConflictStrategy _defaultStrategy;

  /// 대기 중인 충돌 저장소 키.
  static const String _pendingConflictsKey = 'wallet_sync_pending_conflicts';

  /// 충돌을 해결합니다.
  ///
  /// **매개변수:**
  /// - [localPayload]: 로컬 페이로드
  /// - [remotePayload]: 원격 페이로드
  /// - [strategy]: 충돌 해결 전략 (null이면 기본 전략 사용)
  ///
  /// **반환값:**
  /// - 해결된 [SyncConflict]
  Future<SyncConflict> resolveConflict({
    required SyncPayload localPayload,
    required SyncPayload remotePayload,
    ConflictStrategy? strategy,
  }) async {
    final effectiveStrategy = strategy ?? _defaultStrategy;

    // 타임스탬프가 동일한 경우 (매우 드문 케이스)
    if (localPayload.timestamp == remotePayload.timestamp) {
      return SyncConflict(
        payloadId: localPayload.id,
        dataType: localPayload.dataType,
        resolution: ConflictResolution.keepLocal,
        localTimestamp: localPayload.timestamp,
        remoteTimestamp: remotePayload.timestamp,
        localPayload: localPayload,
        remotePayload: remotePayload,
      );
    }

    // 전략별 해결
    switch (effectiveStrategy) {
      case ConflictStrategy.lastWriteWins:
        return _resolveLastWriteWins(localPayload, remotePayload);

      case ConflictStrategy.localFirst:
        return _resolveLocalFirst(localPayload, remotePayload);

      case ConflictStrategy.remoteFirst:
        return _resolveRemoteFirst(localPayload, remotePayload);

      case ConflictStrategy.manual:
        return _resolveManual(localPayload, remotePayload);
    }
  }

  /// 자동 병합을 시도합니다 (가능한 경우).
  ///
  /// **매개변수:**
  /// - [localPayload]: 로컬 페이로드
  /// - [remotePayload]: 원격 페이로드
  ///
  /// **반환값:**
  /// - 병합된 [SyncPayload] (병합 불가능하면 `null`)
  ///
  /// **병합 가능 조건:**
  /// - 데이터 유형이 같아야 함
  /// - 비충돌 필드만 수정되었을 경우
  Future<SyncPayload?> attemptAutoMerge({
    required SyncPayload localPayload,
    required SyncPayload remotePayload,
  }) async {
    // 데이터 유형이 다르면 병합 불가
    if (localPayload.dataType != remotePayload.dataType) {
      return null;
    }

    // 현재는 자동 병합을 지원하지 않음
    // 향후 데이터 유형별 병합 로직 추가 가능
    // 예: 감사 로그는 두 배열을 결합, 설정은 필드별 병합 등
    return null;
  }

  /// 수동 해결 대기 큐에 추가합니다.
  ///
  /// **매개변수:**
  /// - [conflict]: 대기 중인 충돌
  Future<void> queueForManualResolution(SyncConflict conflict) async {
    final pending = await getPendingConflicts();
    pending.add(conflict);
    await _savePendingConflicts(pending);
  }

  /// 대기 중인 충돌 목록을 가져옵니다.
  ///
  /// **반환값:**
  /// - 수동 해결 대기 중인 충돌 목록
  Future<List<SyncConflict>> getPendingConflicts() async {
    final json = await _secureStorage.read(_pendingConflictsKey);
    if (json == null || json.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((e) => _conflictFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 손상된 데이터 처리
      return [];
    }
  }

  /// 충돌을 해결하고 대기 큐에서 제거합니다.
  ///
  /// **매개변수:**
  /// - [payloadId]: 해결할 충돌의 페이로드 ID
  /// - [resolution]: 해결 방법
  Future<void> resolveManualConflict({
    required String payloadId,
    required ConflictResolution resolution,
  }) async {
    final pending = await getPendingConflicts();
    pending.removeWhere((c) => c.payloadId == payloadId);
    await _savePendingConflicts(pending);
  }

  /// 모든 대기 중인 충돌을 삭제합니다.
  Future<void> clearPendingConflicts() async {
    await _secureStorage.delete(_pendingConflictsKey);
  }

  /// Last Write Wins 전략으로 해결합니다.
  SyncConflict _resolveLastWriteWins(
    SyncPayload localPayload,
    SyncPayload remotePayload,
  ) {
    final resolution = localPayload.timestamp.isAfter(remotePayload.timestamp)
        ? ConflictResolution.keepLocal
        : ConflictResolution.keepRemote;

    return SyncConflict(
      payloadId: localPayload.id,
      dataType: localPayload.dataType,
      resolution: resolution,
      localTimestamp: localPayload.timestamp,
      remoteTimestamp: remotePayload.timestamp,
      localPayload: localPayload,
      remotePayload: remotePayload,
    );
  }

  /// Local First 전략으로 해결합니다.
  SyncConflict _resolveLocalFirst(
    SyncPayload localPayload,
    SyncPayload remotePayload,
  ) {
    return SyncConflict(
      payloadId: localPayload.id,
      dataType: localPayload.dataType,
      resolution: ConflictResolution.keepLocal,
      localTimestamp: localPayload.timestamp,
      remoteTimestamp: remotePayload.timestamp,
      localPayload: localPayload,
      remotePayload: remotePayload,
    );
  }

  /// Remote First 전략으로 해결합니다.
  SyncConflict _resolveRemoteFirst(
    SyncPayload localPayload,
    SyncPayload remotePayload,
  ) {
    return SyncConflict(
      payloadId: localPayload.id,
      dataType: localPayload.dataType,
      resolution: ConflictResolution.keepRemote,
      localTimestamp: localPayload.timestamp,
      remoteTimestamp: remotePayload.timestamp,
      localPayload: localPayload,
      remotePayload: remotePayload,
    );
  }

  /// Manual 전략으로 해결합니다 (대기 큐에 추가).
  SyncConflict _resolveManual(
    SyncPayload localPayload,
    SyncPayload remotePayload,
  ) {
    final conflict = SyncConflict(
      payloadId: localPayload.id,
      dataType: localPayload.dataType,
      resolution: ConflictResolution.pending,
      localTimestamp: localPayload.timestamp,
      remoteTimestamp: remotePayload.timestamp,
      localPayload: localPayload,
      remotePayload: remotePayload,
    );

    // 대기 큐에 추가 (비동기 작업이지만 결과는 무시)
    queueForManualResolution(conflict);

    return conflict;
  }

  /// 대기 중인 충돌을 저장합니다.
  Future<void> _savePendingConflicts(List<SyncConflict> conflicts) async {
    final json = jsonEncode(conflicts.map((e) => _conflictToJson(e)).toList());
    await _secureStorage.write(
      key: _pendingConflictsKey,
      value: json,
      isSensitive: false,
    );
  }

  /// [SyncConflict]를 JSON으로 변환합니다.
  Map<String, dynamic> _conflictToJson(SyncConflict conflict) {
    return {
      'payloadId': conflict.payloadId,
      'dataType': conflict.dataType.name,
      'resolution': conflict.resolution.name,
      'localTimestamp': conflict.localTimestamp.toIso8601String(),
      'remoteTimestamp': conflict.remoteTimestamp.toIso8601String(),
      'localPayload': conflict.localPayload?.toJson(),
      'remotePayload': conflict.remotePayload?.toJson(),
    };
  }

  /// JSON에서 [SyncConflict]를 생성합니다.
  SyncConflict _conflictFromJson(Map<String, dynamic> json) {
    return SyncConflict(
      payloadId: json['payloadId'] as String,
      dataType: SyncDataType.values.firstWhere(
        (e) => e.name == json['dataType'],
      ),
      resolution: ConflictResolution.values.firstWhere(
        (e) => e.name == json['resolution'],
      ),
      localTimestamp: DateTime.parse(json['localTimestamp'] as String),
      remoteTimestamp: DateTime.parse(json['remoteTimestamp'] as String),
      localPayload: json['localPayload'] != null
          ? SyncPayload.fromJson(json['localPayload'] as Map<String, dynamic>)
          : null,
      remotePayload: json['remotePayload'] != null
          ? SyncPayload.fromJson(
              json['remotePayload'] as Map<String, dynamic>)
          : null,
    );
  }
}
