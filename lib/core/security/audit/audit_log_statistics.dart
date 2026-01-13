import 'package:equatable/equatable.dart';

import 'audit_event_type.dart';
import 'audit_log_entry.dart';

/// 감사 로그 통계 정보.
///
/// **통계 항목:**
/// - 전체 로그 수
/// - 심각도별 로그 수
/// - 카테고리별 로그 수
/// - 이벤트 유형별 로그 수
/// - 로그 시간 범위
/// - 최근 위험 이벤트 목록
///
/// **사용 예시:**
/// ```dart
/// final stats = await auditLogger.getStatistics(
///   from: DateTime.now().subtract(Duration(days: 7)),
/// );
/// print('Total logs: ${stats.totalLogs}');
/// print('Critical: ${stats.criticalCount}');
/// ```
class AuditLogStatistics extends Equatable {
  const AuditLogStatistics({
    required this.totalLogs,
    required this.criticalCount,
    required this.warningCount,
    required this.infoCount,
    required this.byCategory,
    required this.byEventType,
    this.oldestLog,
    this.newestLog,
    this.recentCriticalEvents = const [],
  });

  /// 전체 로그 수.
  final int totalLogs;

  /// Critical 심각도 로그 수.
  final int criticalCount;

  /// Warning 심각도 로그 수.
  final int warningCount;

  /// Info 심각도 로그 수.
  final int infoCount;

  /// 카테고리별 로그 수.
  ///
  /// 예: `{'authentication': 100, 'wallet': 50, ...}`
  final Map<String, int> byCategory;

  /// 이벤트 유형별 로그 수.
  ///
  /// 예: `{AuditEventType.authBiometricSuccess: 80, ...}`
  final Map<AuditEventType, int> byEventType;

  /// 가장 오래된 로그 시각.
  final DateTime? oldestLog;

  /// 가장 최근 로그 시각.
  final DateTime? newestLog;

  /// 최근 Critical 이벤트 목록 (최대 10개).
  final List<AuditLogEntry> recentCriticalEvents;

  /// 로그 보관 기간 (일).
  int? get retentionDays {
    if (oldestLog == null || newestLog == null) return null;
    return newestLog!.difference(oldestLog!).inDays;
  }

  /// Critical 이벤트 비율 (%).
  double get criticalPercentage {
    if (totalLogs == 0) return 0.0;
    return (criticalCount / totalLogs) * 100;
  }

  /// Warning 이벤트 비율 (%).
  double get warningPercentage {
    if (totalLogs == 0) return 0.0;
    return (warningCount / totalLogs) * 100;
  }

  /// Info 이벤트 비율 (%).
  double get infoPercentage {
    if (totalLogs == 0) return 0.0;
    return (infoCount / totalLogs) * 100;
  }

  /// 가장 빈번한 이벤트 유형 (상위 5개).
  List<MapEntry<AuditEventType, int>> get topEventTypes {
    final entries = byEventType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  /// 빈 통계 객체를 생성합니다.
  factory AuditLogStatistics.empty() {
    return const AuditLogStatistics(
      totalLogs: 0,
      criticalCount: 0,
      warningCount: 0,
      infoCount: 0,
      byCategory: {},
      byEventType: {},
    );
  }

  /// 로그 목록으로부터 통계를 계산합니다.
  factory AuditLogStatistics.fromLogs(List<AuditLogEntry> logs) {
    if (logs.isEmpty) {
      return AuditLogStatistics.empty();
    }

    // 심각도별 카운트
    final severityCounts = <AuditSeverity, int>{};
    for (final log in logs) {
      severityCounts[log.severity] = (severityCounts[log.severity] ?? 0) + 1;
    }

    // 카테고리별 카운트
    final categoryCount = <String, int>{};
    for (final log in logs) {
      categoryCount[log.category] = (categoryCount[log.category] ?? 0) + 1;
    }

    // 이벤트 유형별 카운트
    final eventTypeCount = <AuditEventType, int>{};
    for (final log in logs) {
      eventTypeCount[log.eventType] = (eventTypeCount[log.eventType] ?? 0) + 1;
    }

    // 시간 범위
    final sortedByTime = List<AuditLogEntry>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final oldestLog = sortedByTime.first.timestamp;
    final newestLog = sortedByTime.last.timestamp;

    // 최근 Critical 이벤트 (최대 10개)
    final criticalEvents = logs
        .where((log) => log.severity == AuditSeverity.critical)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentCritical = criticalEvents.take(10).toList();

    return AuditLogStatistics(
      totalLogs: logs.length,
      criticalCount: severityCounts[AuditSeverity.critical] ?? 0,
      warningCount: severityCounts[AuditSeverity.warning] ?? 0,
      infoCount: severityCounts[AuditSeverity.info] ?? 0,
      byCategory: categoryCount,
      byEventType: eventTypeCount,
      oldestLog: oldestLog,
      newestLog: newestLog,
      recentCriticalEvents: recentCritical,
    );
  }

  /// JSON으로 변환합니다.
  Map<String, dynamic> toJson() {
    return {
      'totalLogs': totalLogs,
      'criticalCount': criticalCount,
      'warningCount': warningCount,
      'infoCount': infoCount,
      'byCategory': byCategory,
      'byEventType': byEventType.map((k, v) => MapEntry(k.name, v)),
      'oldestLog': oldestLog?.toIso8601String(),
      'newestLog': newestLog?.toIso8601String(),
      'recentCriticalEvents': recentCriticalEvents.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        totalLogs,
        criticalCount,
        warningCount,
        infoCount,
        byCategory,
        byEventType,
        oldestLog,
        newestLog,
        recentCriticalEvents,
      ];

  @override
  String toString() {
    return 'AuditLogStatistics('
        'totalLogs: $totalLogs, '
        'critical: $criticalCount, '
        'warning: $warningCount, '
        'info: $infoCount, '
        'period: ${oldestLog?.toString() ?? 'N/A'} ~ ${newestLog?.toString() ?? 'N/A'}'
        ')';
  }
}
