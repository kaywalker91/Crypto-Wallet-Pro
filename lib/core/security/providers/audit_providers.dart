import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/storage_providers.dart';
import '../audit/audit_log_entry.dart';
import '../audit/audit_log_statistics.dart';
import '../services/encryption_service.dart';
import '../services/key_derivation_service.dart';
import '../services/security_audit_logger.dart';

/// [EncryptionService] 프로바이더.
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// [KeyDerivationService] 프로바이더.
final keyDerivationServiceProvider = Provider<KeyDerivationService>((ref) {
  return KeyDerivationService();
});

/// [SecurityAuditLogger] 프로바이더.
///
/// **의존성:**
/// - [SecureStorageService]: 암호화된 저장소
/// - [EncryptionService]: AES-256-GCM 암호화
/// - [KeyDerivationService]: PBKDF2 키 파생
///
/// **설정:**
/// - 최대 로그 수: 1000
/// - 보관 기간: 30일
final securityAuditLoggerProvider = Provider<SecurityAuditLogger>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  final keyDerivationService = ref.watch(keyDerivationServiceProvider);

  return SecurityAuditLogger(
    secureStorage: secureStorage,
    encryptionService: encryptionService,
    keyDerivationService: keyDerivationService,
    maxLogEntries: 1000,
    retentionPeriod: const Duration(days: 30),
  );
});

/// 감사 로그 통계 프로바이더.
///
/// **반환값:**
/// - 전체 로그 통계 (비동기)
///
/// **자동 새로고침:**
/// - 로그가 추가될 때마다 invalidate 필요
final auditStatisticsProvider = FutureProvider<AuditLogStatistics>((ref) async {
  final logger = ref.watch(securityAuditLoggerProvider);
  return logger.getStatistics();
});

/// 최근 Critical 이벤트 프로바이더.
///
/// **반환값:**
/// - 최근 7일간의 Critical 이벤트 목록
final recentCriticalEventsProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final logger = ref.watch(securityAuditLoggerProvider);
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  return logger.getCriticalEvents(from: sevenDaysAgo);
});

/// 특정 카테고리의 로그 프로바이더 (패밀리).
///
/// **매개변수:**
/// - [category]: 카테고리 이름 (예: 'authentication', 'wallet')
///
/// **사용 예시:**
/// ```dart
/// final authLogs = ref.watch(categoryLogsProvider('authentication'));
/// ```
final categoryLogsProvider = FutureProvider.family<List<AuditLogEntry>, String>(
  (ref, category) async {
    final logger = ref.watch(securityAuditLoggerProvider);
    return logger.getLogsByCategory(category, limit: 50);
  },
);

/// 최근 로그 프로바이더.
///
/// **반환값:**
/// - 최근 50개 로그
final recentLogsProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final logger = ref.watch(securityAuditLoggerProvider);
  return logger.getLogs(limit: 50);
});
