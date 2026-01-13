import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/storage_providers.dart';
import '../../../shared/services/secure_storage_service.dart';
import '../../constants/storage_keys.dart';
import '../../network/dio_provider.dart';
import '../services/encryption_service.dart';
import '../services/key_derivation_service.dart';
import '../services/remote_security_sync_service.dart';
import '../services/security_audit_logger.dart';
import '../sync/secure_sync_protocol.dart';
import '../sync/sync_config.dart';
import '../sync/sync_conflict_resolver.dart';
import '../sync/sync_result.dart';
import 'audit_providers.dart';

/// SecureSyncProtocol provider.
///
/// E2E 암호화 동기화 프로토콜을 제공합니다.
final secureSyncProtocolProvider = Provider<SecureSyncProtocol>((ref) {
  final encryptionService = ref.watch(encryptionServiceProvider);
  final keyDerivationService = ref.watch(keyDerivationServiceProvider);

  return SecureSyncProtocol(
    encryptionService: encryptionService,
    keyDerivationService: keyDerivationService,
  );
});

/// SyncConfig provider.
///
/// 저장소에서 동기화 설정을 로드합니다.
final syncConfigProvider = FutureProvider<SyncConfig>((ref) async {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final configJson = await secureStorage.read(StorageKeys.syncConfig);

  if (configJson == null || configJson.isEmpty) {
    // 기본 설정 (개발 환경)
    return SyncConfig.development(
      serverUrl: 'https://sync-dev.example.com/api/v1',
    );
  }

  try {
    final Map<String, dynamic> decoded = jsonDecode(configJson);
    return SyncConfig.fromJson(decoded);
  } catch (e) {
    // 손상된 설정 처리
    return SyncConfig.development(
      serverUrl: 'https://sync-dev.example.com/api/v1',
    );
  }
});

/// SyncConflictResolver provider.
///
/// 동기화 충돌 해결기를 제공합니다.
final syncConflictResolverProvider = Provider<SyncConflictResolver>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final config = ref.watch(syncConfigProvider).value ??
      SyncConfig.development(serverUrl: 'https://sync-dev.example.com/api/v1');

  return SyncConflictResolver(
    secureStorage: secureStorage,
    defaultStrategy: config.defaultConflictStrategy,
  );
});

/// RemoteSecuritySyncService provider.
///
/// 원격 보안 동기화 서비스를 제공합니다.
final remoteSecuritySyncServiceProvider =
    Provider<RemoteSecuritySyncService>((ref) {
  final dio = ref.watch(dioProvider);
  final syncProtocol = ref.watch(secureSyncProtocolProvider);
  final conflictResolver = ref.watch(syncConflictResolverProvider);
  final auditLogger = ref.watch(securityAuditLoggerProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final config = ref.watch(syncConfigProvider).value ??
      SyncConfig.development(serverUrl: 'https://sync-dev.example.com/api/v1');

  return RemoteSecuritySyncService(
    dio: dio,
    syncProtocol: syncProtocol,
    conflictResolver: conflictResolver,
    auditLogger: auditLogger,
    secureStorage: secureStorage,
    config: config,
  );
});

/// SyncState provider.
///
/// 동기화 상태를 관리합니다.
final syncStateProvider =
    StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  final syncService = ref.watch(remoteSecuritySyncServiceProvider);
  return SyncStateNotifier(syncService: syncService);
});

/// 동기화 상태.
class SyncState {
  const SyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastResult,
    this.pendingConflicts = const [],
    this.error,
  });

  /// 동기화 진행 중 여부.
  final bool isSyncing;

  /// 마지막 동기화 시각.
  final DateTime? lastSyncTime;

  /// 마지막 동기화 결과.
  final SyncResult? lastResult;

  /// 대기 중인 충돌 목록.
  final List<SyncConflict> pendingConflicts;

  /// 오류 메시지.
  final String? error;

  /// 복사본을 생성합니다.
  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    SyncResult? lastResult,
    List<SyncConflict>? pendingConflicts,
    String? error,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastResult: lastResult ?? this.lastResult,
      pendingConflicts: pendingConflicts ?? this.pendingConflicts,
      error: error,
    );
  }

  /// 동기화가 필요한지 확인합니다.
  bool needsSync(Duration syncInterval) {
    if (lastSyncTime == null) return true;
    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);
    return diff >= syncInterval;
  }

  @override
  String toString() {
    return 'SyncState('
        'isSyncing: $isSyncing, '
        'lastSyncTime: ${lastSyncTime?.toIso8601String()}, '
        'pendingConflicts: ${pendingConflicts.length}'
        '${error != null ? ', error: $error' : ''}'
        ')';
  }
}

/// 동기화 상태 관리자.
class SyncStateNotifier extends StateNotifier<SyncState> {
  SyncStateNotifier({
    required RemoteSecuritySyncService syncService,
  })  : _syncService = syncService,
        super(const SyncState()) {
    _initialize();
  }

  final RemoteSecuritySyncService _syncService;

  /// 초기화합니다.
  Future<void> _initialize() async {
    final lastSyncTime = await _syncService.getLastSyncTime();
    state = state.copyWith(lastSyncTime: lastSyncTime);
  }

  /// 동기화를 수행합니다.
  ///
  /// **매개변수:**
  /// - [syncKey]: 동기화 키 (Base64)
  Future<void> performSync({required String syncKey}) async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final result = await _syncService.performSync(syncKey: syncKey);

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: result.lastSyncTime ?? DateTime.now(),
        lastResult: result,
        pendingConflicts: result.conflicts,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
    }
  }

  /// 감사 로그만 동기화합니다.
  Future<void> syncAuditLogs({required String syncKey}) async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final result = await _syncService.syncAuditLogs(syncKey: syncKey);

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: result.lastSyncTime ?? DateTime.now(),
        lastResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
    }
  }

  /// 보안 설정만 동기화합니다.
  Future<void> syncSecuritySettings({required String syncKey}) async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final result =
          await _syncService.syncSecuritySettings(syncKey: syncKey);

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: result.lastSyncTime ?? DateTime.now(),
        lastResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
    }
  }

  /// 오프라인 큐를 처리합니다.
  Future<void> processOfflineQueue({required String syncKey}) async {
    try {
      await _syncService.processOfflineQueue(syncKey: syncKey);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 충돌을 다시 로드합니다.
  Future<void> refreshConflicts() async {
    // 현재 lastResult에서 충돌 가져오기
    if (state.lastResult != null) {
      state = state.copyWith(
        pendingConflicts: state.lastResult!.conflicts,
      );
    }
  }
}
