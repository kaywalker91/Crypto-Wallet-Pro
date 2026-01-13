import 'package:equatable/equatable.dart';

import 'audit_event_type.dart';

/// 보안 감사 로그 엔트리.
///
/// **속성:**
/// - [id]: UUID 고유 식별자
/// - [timestamp]: 이벤트 발생 시각 (ISO 8601)
/// - [eventType]: 이벤트 유형
/// - [severity]: 심각도 수준
/// - [category]: 이벤트 카테고리
/// - [metadata]: 추가 정보 (IP, device info, transaction hash 등)
/// - [errorMessage]: 오류 메시지 (실패 이벤트 시)
/// - [stackTrace]: 스택 트레이스 (오류 시)
/// - [isEncrypted]: 민감 정보 암호화 여부
///
/// **사용 예시:**
/// ```dart
/// final entry = AuditLogEntry(
///   id: uuid.v4(),
///   timestamp: DateTime.now(),
///   eventType: AuditEventType.authBiometricSuccess,
///   metadata: {'deviceId': 'abc123'},
/// );
/// ```
class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.eventType,
    this.metadata = const {},
    this.errorMessage,
    this.stackTrace,
    this.isEncrypted = false,
  });

  /// 고유 식별자 (UUID v4).
  final String id;

  /// 이벤트 발생 시각.
  final DateTime timestamp;

  /// 이벤트 유형.
  final AuditEventType eventType;

  /// 추가 메타데이터.
  ///
  /// **일반적인 키:**
  /// - `deviceId`: 디바이스 고유 ID
  /// - `walletAddress`: 지갑 주소
  /// - `transactionHash`: 트랜잭션 해시
  /// - `attemptCount`: 시도 횟수
  /// - `ipAddress`: IP 주소 (서버 연동 시)
  final Map<String, dynamic> metadata;

  /// 오류 메시지 (실패 이벤트 시).
  final String? errorMessage;

  /// 스택 트레이스 (오류 시).
  final String? stackTrace;

  /// 민감 정보가 암호화되었는지 여부.
  final bool isEncrypted;

  /// 이벤트 심각도 (자동 계산).
  AuditSeverity get severity => eventType.severity;

  /// 이벤트 카테고리 (자동 계산).
  String get category => eventType.category;

  /// JSON으로 변환합니다.
  ///
  /// **출력 포맷:**
  /// ```json
  /// {
  ///   "id": "uuid-string",
  ///   "timestamp": "2024-01-15T10:30:00.000Z",
  ///   "eventType": "authBiometricSuccess",
  ///   "severity": "info",
  ///   "category": "authentication",
  ///   "metadata": {...},
  ///   "errorMessage": null,
  ///   "stackTrace": null,
  ///   "isEncrypted": false
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.name,
      'severity': severity.name,
      'category': category,
      'metadata': metadata,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
      'isEncrypted': isEncrypted,
    };
  }

  /// JSON에서 복원합니다.
  ///
  /// **필수 필드:**
  /// - `id`: 문자열
  /// - `timestamp`: ISO 8601 문자열
  /// - `eventType`: [AuditEventType] 이름
  ///
  /// **예외:**
  /// - [FormatException]: 잘못된 JSON 형식
  /// - [ArgumentError]: 알 수 없는 이벤트 유형
  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    // metadata를 안전하게 변환
    Map<String, dynamic> metadata = {};
    if (json['metadata'] != null) {
      final metadataRaw = json['metadata'];
      if (metadataRaw is Map) {
        metadata = Map<String, dynamic>.from(metadataRaw);
      }
    }

    return AuditLogEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventType: AuditEventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => throw ArgumentError('Unknown event type: ${json['eventType']}'),
      ),
      metadata: metadata,
      errorMessage: json['errorMessage'] as String?,
      stackTrace: json['stackTrace'] as String?,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
    );
  }

  /// 엔트리를 복사하여 일부 속성을 변경합니다.
  AuditLogEntry copyWith({
    String? id,
    DateTime? timestamp,
    AuditEventType? eventType,
    Map<String, dynamic>? metadata,
    String? errorMessage,
    String? stackTrace,
    bool? isEncrypted,
  }) {
    return AuditLogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        eventType,
        metadata,
        errorMessage,
        stackTrace,
        isEncrypted,
      ];

  @override
  String toString() {
    return 'AuditLogEntry('
        'id: $id, '
        'timestamp: $timestamp, '
        'eventType: ${eventType.name}, '
        'severity: ${severity.name}, '
        'category: $category, '
        'metadata: $metadata, '
        'errorMessage: $errorMessage, '
        'isEncrypted: $isEncrypted'
        ')';
  }
}
