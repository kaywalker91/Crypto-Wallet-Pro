import 'package:equatable/equatable.dart';

import 'sync_payload.dart';

/// 동기화 결과.
///
/// 동기화 작업의 성공/실패 여부 및 상세 정보를 포함합니다.
class SyncResult with EquatableMixin {
  const SyncResult({
    required this.status,
    required this.uploadedCount,
    required this.downloadedCount,
    required this.conflictCount,
    required this.conflicts,
    this.lastSyncTime,
    this.errorMessage,
  });

  /// 동기화 상태.
  final SyncStatus status;

  /// 업로드된 페이로드 수.
  final int uploadedCount;

  /// 다운로드된 페이로드 수.
  final int downloadedCount;

  /// 충돌 발생 횟수.
  final int conflictCount;

  /// 충돌 목록.
  final List<SyncConflict> conflicts;

  /// 마지막 동기화 시각 (성공 시).
  final DateTime? lastSyncTime;

  /// 오류 메시지 (실패 시).
  final String? errorMessage;

  /// 성공 결과를 생성합니다.
  factory SyncResult.success({
    required int uploadedCount,
    required int downloadedCount,
    required DateTime lastSyncTime,
  }) {
    return SyncResult(
      status: SyncStatus.success,
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      conflictCount: 0,
      conflicts: const [],
      lastSyncTime: lastSyncTime,
    );
  }

  /// 실패 결과를 생성합니다.
  factory SyncResult.failure({
    required String errorMessage,
  }) {
    return SyncResult(
      status: SyncStatus.failed,
      uploadedCount: 0,
      downloadedCount: 0,
      conflictCount: 0,
      conflicts: const [],
      errorMessage: errorMessage,
    );
  }

  /// 부분 성공 결과를 생성합니다.
  factory SyncResult.partialSuccess({
    required int uploadedCount,
    required int downloadedCount,
    required List<SyncConflict> conflicts,
    required DateTime lastSyncTime,
  }) {
    return SyncResult(
      status: SyncStatus.partialSuccess,
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      conflictCount: conflicts.length,
      conflicts: conflicts,
      lastSyncTime: lastSyncTime,
    );
  }

  /// 변경 사항 없음 결과를 생성합니다.
  factory SyncResult.noChanges() {
    return const SyncResult(
      status: SyncStatus.noChanges,
      uploadedCount: 0,
      downloadedCount: 0,
      conflictCount: 0,
      conflicts: [],
    );
  }

  /// 충돌 결과를 생성합니다.
  factory SyncResult.conflict({
    required List<SyncConflict> conflicts,
  }) {
    return SyncResult(
      status: SyncStatus.conflict,
      uploadedCount: 0,
      downloadedCount: 0,
      conflictCount: conflicts.length,
      conflicts: conflicts,
    );
  }

  /// 동기화가 성공적으로 완료되었는지 확인합니다.
  bool get isSuccess =>
      status == SyncStatus.success || status == SyncStatus.noChanges;

  /// 충돌이 해결되어야 하는지 확인합니다.
  bool get requiresConflictResolution => conflictCount > 0;

  @override
  List<Object?> get props => [
        status,
        uploadedCount,
        downloadedCount,
        conflictCount,
        conflicts,
        lastSyncTime,
        errorMessage,
      ];

  @override
  String toString() {
    return 'SyncResult('
        'status: ${status.name}, '
        'uploaded: $uploadedCount, '
        'downloaded: $downloadedCount, '
        'conflicts: $conflictCount'
        '${errorMessage != null ? ', error: $errorMessage' : ''}'
        ')';
  }
}

/// 동기화 상태.
enum SyncStatus {
  /// 성공적으로 완료됨.
  success,

  /// 실패함.
  failed,

  /// 부분적으로 성공함 (일부 충돌 발생).
  partialSuccess,

  /// 변경 사항 없음.
  noChanges,

  /// 충돌 발생 (수동 해결 필요).
  conflict,
}

/// 동기화 충돌.
///
/// 동일한 데이터를 여러 디바이스에서 동시에 수정했을 때 발생합니다.
class SyncConflict with EquatableMixin {
  const SyncConflict({
    required this.payloadId,
    required this.dataType,
    required this.resolution,
    required this.localTimestamp,
    required this.remoteTimestamp,
    this.localPayload,
    this.remotePayload,
  });

  /// 충돌이 발생한 페이로드 ID.
  final String payloadId;

  /// 데이터 유형.
  final SyncDataType dataType;

  /// 충돌 해결 전략.
  final ConflictResolution resolution;

  /// 로컬 타임스탬프.
  final DateTime localTimestamp;

  /// 원격 타임스탬프.
  final DateTime remoteTimestamp;

  /// 로컬 페이로드 (선택).
  final SyncPayload? localPayload;

  /// 원격 페이로드 (선택).
  final SyncPayload? remotePayload;

  /// 로컬이 더 최신인지 확인합니다.
  bool get isLocalNewer => localTimestamp.isAfter(remoteTimestamp);

  /// 원격이 더 최신인지 확인합니다.
  bool get isRemoteNewer => remoteTimestamp.isAfter(localTimestamp);

  /// 수동 해결이 필요한지 확인합니다.
  bool get requiresManualResolution => resolution == ConflictResolution.pending;

  @override
  List<Object?> get props => [
        payloadId,
        dataType,
        resolution,
        localTimestamp,
        remoteTimestamp,
        localPayload,
        remotePayload,
      ];

  @override
  String toString() {
    return 'SyncConflict('
        'payloadId: $payloadId, '
        'dataType: ${dataType.name}, '
        'resolution: ${resolution.name}, '
        'localTime: ${localTimestamp.toIso8601String()}, '
        'remoteTime: ${remoteTimestamp.toIso8601String()}'
        ')';
  }
}

/// 충돌 해결 전략.
enum ConflictResolution {
  /// 로컬 데이터 유지.
  keepLocal,

  /// 원격 데이터 유지.
  keepRemote,

  /// 자동 병합 (가능한 경우).
  merge,

  /// 수동 해결 대기.
  pending,
}

/// [SyncStatus]의 확장 메서드.
extension SyncStatusExtension on SyncStatus {
  /// 사람이 읽을 수 있는 이름을 반환합니다.
  String get displayName {
    switch (this) {
      case SyncStatus.success:
        return 'Success';
      case SyncStatus.failed:
        return 'Failed';
      case SyncStatus.partialSuccess:
        return 'Partial Success';
      case SyncStatus.noChanges:
        return 'No Changes';
      case SyncStatus.conflict:
        return 'Conflict';
    }
  }

  /// 성공 여부를 반환합니다.
  bool get isSuccessful =>
      this == SyncStatus.success || this == SyncStatus.noChanges;
}

/// [ConflictResolution]의 확장 메서드.
extension ConflictResolutionExtension on ConflictResolution {
  /// 사람이 읽을 수 있는 이름을 반환합니다.
  String get displayName {
    switch (this) {
      case ConflictResolution.keepLocal:
        return 'Keep Local';
      case ConflictResolution.keepRemote:
        return 'Keep Remote';
      case ConflictResolution.merge:
        return 'Merge';
      case ConflictResolution.pending:
        return 'Pending';
    }
  }
}
