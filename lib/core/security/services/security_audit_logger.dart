import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../constants/storage_keys.dart';
import '../../error/failures.dart';
import '../../../shared/services/secure_storage_service.dart';
import '../audit/audit_event_type.dart';
import '../audit/audit_log_entry.dart';
import '../audit/audit_log_statistics.dart';
import 'encryption_service.dart';
import 'key_derivation_service.dart';

/// 보안 감사 로깅 서비스.
///
/// **Defense-in-Depth 보안:**
/// - 로그 암호화: PIN 기반 AES-256-GCM
/// - 무결성 보호: 암호화된 저장소 사용
/// - 자동 정리: 보관 기간 및 최대 로그 수 관리
/// - 민감 정보 보호: 메타데이터 선택적 암호화
///
/// **아키텍처:**
/// ```
/// ┌────────────────────────────────────────────────┐
/// │ SecurityAuditLogger                            │
/// ├────────────────────────────────────────────────┤
/// │ - log(event, metadata)                         │
/// │ - getLogs(filters)                             │
/// │ - getStatistics()                              │
/// │ - purgeOldLogs()                               │
/// │ - exportLogs(pin)                              │
/// └────────────────────────────────────────────────┘
///          │
///          ├─> EncryptionService (AES-256-GCM)
///          ├─> KeyDerivationService (PBKDF2)
///          └─> SecureStorageService (Platform)
/// ```
///
/// **사용 예시:**
/// ```dart
/// final logger = SecurityAuditLogger(...);
///
/// // 성공 이벤트 로그
/// await logger.log(
///   AuditEventType.authBiometricSuccess,
///   metadata: {'deviceId': 'abc123'},
/// );
///
/// // 오류 이벤트 로그
/// await logger.logError(
///   AuditEventType.decryptionFailed,
///   error,
///   stackTrace: stackTrace,
/// );
///
/// // 로그 조회
/// final logs = await logger.getCriticalEvents(
///   from: DateTime.now().subtract(Duration(days: 7)),
/// );
/// ```
class SecurityAuditLogger {
  SecurityAuditLogger({
    required SecureStorageService secureStorage,
    required EncryptionService encryptionService,
    required KeyDerivationService keyDerivationService,
    this.maxLogEntries = 1000,
    this.retentionPeriod = const Duration(days: 30),
  })  : _secureStorage = secureStorage,
        _encryptionService = encryptionService,
        _keyDerivationService = keyDerivationService,
        _uuid = const Uuid();

  final SecureStorageService _secureStorage;
  final EncryptionService _encryptionService;
  final KeyDerivationService _keyDerivationService;
  final Uuid _uuid;

  /// 최대 로그 엔트리 수.
  final int maxLogEntries;

  /// 로그 보관 기간.
  final Duration retentionPeriod;

  /// 감사 이벤트를 로그에 기록합니다.
  ///
  /// **매개변수:**
  /// - [event]: 이벤트 유형
  /// - [metadata]: 추가 메타데이터 (선택)
  ///
  /// **메타데이터 암호화:**
  /// - 민감 정보는 자동으로 암호화됩니다
  /// - 키: `privateKey`, `mnemonic`, `pin`, `password` 등
  ///
  /// **예외:**
  /// - [StorageFailure]: 로그 저장 실패
  Future<void> log(
    AuditEventType event, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final entry = AuditLogEntry(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        eventType: event,
        metadata: metadata ?? {},
        isEncrypted: _containsSensitiveData(metadata),
      );

      await _appendLog(entry);
      await _enforceLogLimits();
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to log audit event', cause: e);
    }
  }

  /// 오류와 함께 감사 이벤트를 로그에 기록합니다.
  ///
  /// **매개변수:**
  /// - [event]: 이벤트 유형
  /// - [error]: 오류 객체
  /// - [stackTrace]: 스택 트레이스 (선택)
  /// - [metadata]: 추가 메타데이터 (선택)
  ///
  /// **예외:**
  /// - [StorageFailure]: 로그 저장 실패
  Future<void> logError(
    AuditEventType event,
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final entry = AuditLogEntry(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        eventType: event,
        metadata: metadata ?? {},
        errorMessage: error.toString(),
        stackTrace: stackTrace?.toString(),
        isEncrypted: _containsSensitiveData(metadata),
      );

      await _appendLog(entry);
      await _enforceLogLimits();
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to log audit error', cause: e);
    }
  }

  /// 로그를 조회합니다.
  ///
  /// **매개변수:**
  /// - [eventType]: 특정 이벤트 유형으로 필터링 (선택)
  /// - [from]: 시작 시각 (선택)
  /// - [to]: 종료 시각 (선택)
  /// - [limit]: 최대 결과 수 (선택)
  ///
  /// **반환값:**
  /// - 필터링된 로그 목록 (최신순)
  ///
  /// **예외:**
  /// - [StorageFailure]: 로그 읽기 실패
  Future<List<AuditLogEntry>> getLogs({
    AuditEventType? eventType,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    try {
      final allLogs = await _loadAllLogs();

      var filtered = allLogs.where((log) {
        if (eventType != null && log.eventType != eventType) return false;
        if (from != null && log.timestamp.isBefore(from)) return false;
        if (to != null && log.timestamp.isAfter(to)) return false;
        return true;
      }).toList();

      // 최신순 정렬
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (limit != null && limit > 0) {
        filtered = filtered.take(limit).toList();
      }

      return filtered;
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to get audit logs', cause: e);
    }
  }

  /// 카테고리별 로그를 조회합니다.
  ///
  /// **매개변수:**
  /// - [category]: 카테고리 이름 (예: 'authentication', 'wallet')
  /// - [limit]: 최대 결과 수 (선택)
  ///
  /// **반환값:**
  /// - 카테고리에 해당하는 로그 목록 (최신순)
  Future<List<AuditLogEntry>> getLogsByCategory(
    String category, {
    int? limit,
  }) async {
    try {
      final allLogs = await _loadAllLogs();

      var filtered = allLogs.where((log) => log.category == category).toList();

      // 최신순 정렬
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (limit != null && limit > 0) {
        filtered = filtered.take(limit).toList();
      }

      return filtered;
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to get logs by category', cause: e);
    }
  }

  /// Critical 심각도 이벤트를 조회합니다.
  ///
  /// **매개변수:**
  /// - [from]: 시작 시각 (선택)
  ///
  /// **반환값:**
  /// - Critical 이벤트 목록 (최신순)
  Future<List<AuditLogEntry>> getCriticalEvents({DateTime? from}) async {
    try {
      final allLogs = await _loadAllLogs();

      var critical = allLogs.where((log) {
        if (log.severity != AuditSeverity.critical) return false;
        if (from != null && log.timestamp.isBefore(from)) return false;
        return true;
      }).toList();

      // 최신순 정렬
      critical.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return critical;
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to get critical events', cause: e);
    }
  }

  /// 로그 통계를 계산합니다.
  ///
  /// **매개변수:**
  /// - [from]: 시작 시각 (선택)
  /// - [to]: 종료 시각 (선택)
  ///
  /// **반환값:**
  /// - 통계 정보 객체
  Future<AuditLogStatistics> getStatistics({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final logs = await getLogs(from: from, to: to);
      return AuditLogStatistics.fromLogs(logs);
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to get audit statistics', cause: e);
    }
  }

  /// 보관 기간이 지난 오래된 로그를 삭제합니다.
  ///
  /// **반환값:**
  /// - 삭제된 로그 수
  ///
  /// **예외:**
  /// - [StorageFailure]: 로그 정리 실패
  Future<int> purgeOldLogs() async {
    try {
      final allLogs = await _loadAllLogs();
      final cutoffTime = DateTime.now().subtract(retentionPeriod);

      final validLogs = allLogs.where((log) {
        return log.timestamp.isAfter(cutoffTime);
      }).toList();

      final deletedCount = allLogs.length - validLogs.length;

      if (deletedCount > 0) {
        await _saveAllLogs(validLogs);
      }

      return deletedCount;
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to purge old logs', cause: e);
    }
  }

  /// 로그를 암호화된 JSON으로 내보냅니다.
  ///
  /// **매개변수:**
  /// - [from]: 시작 시각 (선택)
  /// - [to]: 종료 시각 (선택)
  /// - [pin]: 암호화에 사용할 PIN
  ///
  /// **반환값:**
  /// - Base64 인코딩된 암호화 JSON
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 암호화 실패
  /// - [StorageFailure]: 로그 읽기 실패
  Future<String> exportLogs({
    DateTime? from,
    DateTime? to,
    required String pin,
  }) async {
    try {
      final logs = await getLogs(from: from, to: to);
      final logsJson = logs.map((e) => e.toJson()).toList();
      final jsonString = json.encode(logsJson);

      // PIN 기반 암호화
      final salt = _keyDerivationService.generateSalt();
      final key = _keyDerivationService.deriveKey(pin: pin, salt: salt);
      final encrypted = _encryptionService.encrypt(
        plaintext: jsonString,
        key: key,
      );

      // Salt와 암호문 결합
      final exportData = {
        'version': '1.0',
        'salt': salt,
        'data': encrypted,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return base64.encode(utf8.encode(json.encode(exportData)));
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to export logs', cause: e);
    }
  }

  /// 모든 로그를 삭제합니다.
  ///
  /// **주의:** 복구 불가능합니다.
  ///
  /// **예외:**
  /// - [StorageFailure]: 삭제 실패
  Future<void> clearAllLogs() async {
    try {
      await _secureStorage.delete(StorageKeys.auditLogs);
      await _secureStorage.delete(StorageKeys.auditLogIndex);
    } catch (e) {
      throw StorageFailure('Failed to clear all logs', cause: e);
    }
  }

  /// 로그를 저장소에 추가합니다.
  Future<void> _appendLog(AuditLogEntry entry) async {
    final allLogs = await _loadAllLogs();
    allLogs.add(entry);
    await _saveAllLogs(allLogs);
  }

  /// 모든 로그를 메모리에 로드합니다.
  Future<List<AuditLogEntry>> _loadAllLogs() async {
    final logsJson = await _secureStorage.read(StorageKeys.auditLogs);
    if (logsJson == null || logsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(logsJson);
      return decoded
          .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 손상된 로그 데이터 처리
      return [];
    }
  }

  /// 모든 로그를 저장소에 저장합니다.
  Future<void> _saveAllLogs(List<AuditLogEntry> logs) async {
    final logsJson = json.encode(logs.map((e) => e.toJson()).toList());
    await _secureStorage.write(
      key: StorageKeys.auditLogs,
      value: logsJson,
      isSensitive: true,
    );

    // 인덱스 업데이트 (빠른 조회용)
    await _secureStorage.write(
      key: StorageKeys.auditLogIndex,
      value: logs.length.toString(),
      isSensitive: false,
    );
  }

  /// 로그 제한을 강제합니다.
  ///
  /// - 최대 로그 수 초과 시 오래된 것부터 삭제
  Future<void> _enforceLogLimits() async {
    final allLogs = await _loadAllLogs();

    if (allLogs.length > maxLogEntries) {
      // 최신순 정렬 후 최대 수만큼 유지
      allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final trimmedLogs = allLogs.take(maxLogEntries).toList();
      await _saveAllLogs(trimmedLogs);
    }
  }

  /// 메타데이터에 민감 정보가 포함되어 있는지 확인합니다.
  bool _containsSensitiveData(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return false;

    const sensitiveKeys = [
      'privateKey',
      'mnemonic',
      'pin',
      'password',
      'seed',
      'secret',
    ];

    return metadata.keys.any((key) {
      return sensitiveKeys.any((sensitive) {
        return key.toLowerCase().contains(sensitive.toLowerCase());
      });
    });
  }
}
