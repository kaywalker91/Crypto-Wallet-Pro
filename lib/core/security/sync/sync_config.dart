import 'package:equatable/equatable.dart';

import 'sync_payload.dart';
import 'sync_result.dart';

/// 동기화 설정.
///
/// 원격 동기화의 동작을 제어하는 설정입니다.
class SyncConfig with EquatableMixin {
  const SyncConfig({
    required this.serverUrl,
    this.syncInterval = const Duration(minutes: 15),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.autoSyncEnabled = true,
    this.enabledDataTypes = const {
      SyncDataType.auditLogs,
      SyncDataType.securitySettings,
      SyncDataType.deviceRegistry,
      SyncDataType.backupMetadata,
    },
    this.defaultConflictStrategy = ConflictStrategy.lastWriteWins,
    this.maxOfflineQueueSize = 100,
    this.syncTimeout = const Duration(minutes: 5),
    this.requiresWifiOnly = false,
  });

  /// 동기화 서버 URL.
  ///
  /// **예시:** `https://sync.example.com/api/v1`
  final String serverUrl;

  /// 자동 동기화 간격.
  ///
  /// 기본값: 15분
  final Duration syncInterval;

  /// 최대 재시도 횟수.
  ///
  /// 네트워크 오류 시 재시도 횟수입니다.
  /// 기본값: 3회
  final int maxRetries;

  /// 재시도 지연 시간.
  ///
  /// 실패 후 다음 재시도까지 대기 시간입니다.
  /// 기본값: 30초
  final Duration retryDelay;

  /// 자동 동기화 활성화 여부.
  ///
  /// `false`인 경우 수동으로만 동기화됩니다.
  final bool autoSyncEnabled;

  /// 동기화할 데이터 유형 목록.
  ///
  /// 기본값: 모든 유형
  final Set<SyncDataType> enabledDataTypes;

  /// 기본 충돌 해결 전략.
  ///
  /// 기본값: 최신 쓰기 우선 (Last Write Wins)
  final ConflictStrategy defaultConflictStrategy;

  /// 최대 오프라인 큐 크기.
  ///
  /// 오프라인 시 저장할 최대 페이로드 수입니다.
  /// 기본값: 100개
  final int maxOfflineQueueSize;

  /// 동기화 타임아웃.
  ///
  /// 동기화 작업의 최대 실행 시간입니다.
  /// 기본값: 5분
  final Duration syncTimeout;

  /// WiFi 전용 동기화 여부.
  ///
  /// `true`인 경우 WiFi 연결 시에만 동기화됩니다.
  final bool requiresWifiOnly;

  /// 기본 설정을 생성합니다.
  factory SyncConfig.defaultConfig({required String serverUrl}) {
    return SyncConfig(serverUrl: serverUrl);
  }

  /// 프로덕션 환경용 설정을 생성합니다.
  factory SyncConfig.production({required String serverUrl}) {
    return SyncConfig(
      serverUrl: serverUrl,
      syncInterval: const Duration(minutes: 30),
      maxRetries: 5,
      retryDelay: const Duration(minutes: 1),
      autoSyncEnabled: true,
      syncTimeout: const Duration(minutes: 10),
      requiresWifiOnly: true,
    );
  }

  /// 개발 환경용 설정을 생성합니다.
  factory SyncConfig.development({required String serverUrl}) {
    return SyncConfig(
      serverUrl: serverUrl,
      syncInterval: const Duration(minutes: 5),
      maxRetries: 2,
      retryDelay: const Duration(seconds: 10),
      autoSyncEnabled: true,
      syncTimeout: const Duration(minutes: 2),
      requiresWifiOnly: false,
    );
  }

  /// 복사본을 생성합니다.
  SyncConfig copyWith({
    String? serverUrl,
    Duration? syncInterval,
    int? maxRetries,
    Duration? retryDelay,
    bool? autoSyncEnabled,
    Set<SyncDataType>? enabledDataTypes,
    ConflictStrategy? defaultConflictStrategy,
    int? maxOfflineQueueSize,
    Duration? syncTimeout,
    bool? requiresWifiOnly,
  }) {
    return SyncConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      syncInterval: syncInterval ?? this.syncInterval,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      enabledDataTypes: enabledDataTypes ?? this.enabledDataTypes,
      defaultConflictStrategy:
          defaultConflictStrategy ?? this.defaultConflictStrategy,
      maxOfflineQueueSize: maxOfflineQueueSize ?? this.maxOfflineQueueSize,
      syncTimeout: syncTimeout ?? this.syncTimeout,
      requiresWifiOnly: requiresWifiOnly ?? this.requiresWifiOnly,
    );
  }

  /// JSON으로 변환합니다.
  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'syncInterval': syncInterval.inSeconds,
      'maxRetries': maxRetries,
      'retryDelay': retryDelay.inSeconds,
      'autoSyncEnabled': autoSyncEnabled,
      'enabledDataTypes': enabledDataTypes.map((e) => e.name).toList(),
      'defaultConflictStrategy': defaultConflictStrategy.name,
      'maxOfflineQueueSize': maxOfflineQueueSize,
      'syncTimeout': syncTimeout.inSeconds,
      'requiresWifiOnly': requiresWifiOnly,
    };
  }

  /// JSON에서 생성합니다.
  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      serverUrl: json['serverUrl'] as String,
      syncInterval: Duration(seconds: json['syncInterval'] as int),
      maxRetries: json['maxRetries'] as int,
      retryDelay: Duration(seconds: json['retryDelay'] as int),
      autoSyncEnabled: json['autoSyncEnabled'] as bool,
      enabledDataTypes: (json['enabledDataTypes'] as List<dynamic>)
          .map((e) => SyncDataType.values.firstWhere((t) => t.name == e))
          .toSet(),
      defaultConflictStrategy: ConflictStrategy.values.firstWhere(
        (e) => e.name == json['defaultConflictStrategy'],
      ),
      maxOfflineQueueSize: json['maxOfflineQueueSize'] as int,
      syncTimeout: Duration(seconds: json['syncTimeout'] as int),
      requiresWifiOnly: json['requiresWifiOnly'] as bool,
    );
  }

  /// 특정 데이터 유형이 활성화되어 있는지 확인합니다.
  bool isDataTypeEnabled(SyncDataType dataType) {
    return enabledDataTypes.contains(dataType);
  }

  @override
  List<Object?> get props => [
        serverUrl,
        syncInterval,
        maxRetries,
        retryDelay,
        autoSyncEnabled,
        enabledDataTypes,
        defaultConflictStrategy,
        maxOfflineQueueSize,
        syncTimeout,
        requiresWifiOnly,
      ];

  @override
  String toString() {
    return 'SyncConfig('
        'serverUrl: $serverUrl, '
        'syncInterval: ${syncInterval.inMinutes}m, '
        'autoSyncEnabled: $autoSyncEnabled, '
        'conflictStrategy: ${defaultConflictStrategy.name}'
        ')';
  }
}

/// 충돌 해결 전략.
enum ConflictStrategy {
  /// 최신 쓰기 우선 (타임스탬프 기반).
  lastWriteWins,

  /// 로컬 우선 (로컬 데이터 유지).
  localFirst,

  /// 원격 우선 (원격 데이터 유지).
  remoteFirst,

  /// 수동 해결 (사용자 선택).
  manual,
}

/// [ConflictStrategy]의 확장 메서드.
extension ConflictStrategyExtension on ConflictStrategy {
  /// 사람이 읽을 수 있는 이름을 반환합니다.
  String get displayName {
    switch (this) {
      case ConflictStrategy.lastWriteWins:
        return 'Last Write Wins';
      case ConflictStrategy.localFirst:
        return 'Local First';
      case ConflictStrategy.remoteFirst:
        return 'Remote First';
      case ConflictStrategy.manual:
        return 'Manual Resolution';
    }
  }

  /// 설명을 반환합니다.
  String get description {
    switch (this) {
      case ConflictStrategy.lastWriteWins:
        return 'Automatically keeps the most recent change based on timestamp';
      case ConflictStrategy.localFirst:
        return 'Always keeps local changes when conflicts occur';
      case ConflictStrategy.remoteFirst:
        return 'Always keeps remote changes when conflicts occur';
      case ConflictStrategy.manual:
        return 'Prompts user to manually resolve conflicts';
    }
  }
}
