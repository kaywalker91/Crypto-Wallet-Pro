import 'package:equatable/equatable.dart';

/// 동기화 페이로드 - End-to-End 암호화된 데이터 전송 단위.
///
/// **보안 특성:**
/// - E2E 암호화: 클라이언트에서 암호화, 서버는 복호화 불가
/// - AEAD: Authentication Tag으로 무결성 보호
/// - 체크섬: SHA-256 기반 추가 무결성 검증
/// - 버전 관리: 충돌 해결 및 데이터 마이그레이션 지원
///
/// **데이터 포맷:**
/// ```
/// ┌─────────────────────────────────────────┐
/// │ Metadata (평문)                         │
/// │ - id, timestamp, version, deviceId      │
/// ├─────────────────────────────────────────┤
/// │ Encrypted Data (AES-256-GCM)            │
/// │ - encryptedData (Base64)                │
/// │ - iv (Base64)                           │
/// │ - authTag (Base64)                      │
/// ├─────────────────────────────────────────┤
/// │ Integrity                                │
/// │ - checksum (SHA-256)                    │
/// └─────────────────────────────────────────┘
/// ```
class SyncPayload with EquatableMixin {
  const SyncPayload({
    required this.id,
    required this.dataType,
    required this.encryptedData,
    required this.iv,
    required this.authTag,
    required this.version,
    required this.timestamp,
    required this.deviceId,
    required this.checksum,
  });

  /// 페이로드 고유 ID (UUID v4).
  final String id;

  /// 데이터 유형 (auditLogs, securitySettings 등).
  final SyncDataType dataType;

  /// E2E 암호화된 데이터 (Base64).
  final String encryptedData;

  /// 초기화 벡터 (Base64, 12바이트).
  final String iv;

  /// AEAD 인증 태그 (Base64, 16바이트).
  final String authTag;

  /// 데이터 버전 (충돌 해결용).
  ///
  /// 동일한 데이터를 수정할 때마다 증가합니다.
  final int version;

  /// 생성 시각 (UTC).
  final DateTime timestamp;

  /// 원본 디바이스 ID.
  final String deviceId;

  /// 무결성 체크섬 (SHA-256).
  ///
  /// 복호화 전 데이터 무결성 검증에 사용됩니다.
  final String checksum;

  /// JSON으로 변환합니다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataType': dataType.name,
      'encryptedData': encryptedData,
      'iv': iv,
      'authTag': authTag,
      'version': version,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'checksum': checksum,
    };
  }

  /// JSON에서 생성합니다.
  factory SyncPayload.fromJson(Map<String, dynamic> json) {
    return SyncPayload(
      id: json['id'] as String,
      dataType: SyncDataType.values.firstWhere(
        (e) => e.name == json['dataType'],
      ),
      encryptedData: json['encryptedData'] as String,
      iv: json['iv'] as String,
      authTag: json['authTag'] as String,
      version: json['version'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceId: json['deviceId'] as String,
      checksum: json['checksum'] as String,
    );
  }

  /// 복사본을 생성합니다.
  SyncPayload copyWith({
    String? id,
    SyncDataType? dataType,
    String? encryptedData,
    String? iv,
    String? authTag,
    int? version,
    DateTime? timestamp,
    String? deviceId,
    String? checksum,
  }) {
    return SyncPayload(
      id: id ?? this.id,
      dataType: dataType ?? this.dataType,
      encryptedData: encryptedData ?? this.encryptedData,
      iv: iv ?? this.iv,
      authTag: authTag ?? this.authTag,
      version: version ?? this.version,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dataType,
        encryptedData,
        iv,
        authTag,
        version,
        timestamp,
        deviceId,
        checksum,
      ];

  @override
  String toString() {
    final deviceIdPreview = deviceId.length > 8 ? '${deviceId.substring(0, 8)}...' : deviceId;
    final checksumPreview = checksum.length > 16 ? '${checksum.substring(0, 16)}...' : checksum;

    return 'SyncPayload('
        'id: $id, '
        'dataType: ${dataType.name}, '
        'version: $version, '
        'timestamp: ${timestamp.toIso8601String()}, '
        'deviceId: $deviceIdPreview, '
        'encryptedData: [REDACTED], '
        'checksum: $checksumPreview'
        ')';
  }
}

/// 동기화 데이터 유형.
enum SyncDataType {
  /// 감사 로그 (보안 이벤트 기록).
  auditLogs,

  /// 보안 설정 (생체인증, PIN 등).
  securitySettings,

  /// 등록된 디바이스 목록.
  deviceRegistry,

  /// 백업 메타데이터 (백업 시각, 체크섬 등).
  backupMetadata,
}

/// [SyncDataType]의 확장 메서드.
extension SyncDataTypeExtension on SyncDataType {
  /// 사람이 읽을 수 있는 이름을 반환합니다.
  String get displayName {
    switch (this) {
      case SyncDataType.auditLogs:
        return 'Audit Logs';
      case SyncDataType.securitySettings:
        return 'Security Settings';
      case SyncDataType.deviceRegistry:
        return 'Device Registry';
      case SyncDataType.backupMetadata:
        return 'Backup Metadata';
    }
  }

  /// 데이터 유형이 민감한지 여부를 반환합니다.
  ///
  /// 민감한 데이터는 추가 보안 조치가 필요합니다.
  bool get isSensitive {
    switch (this) {
      case SyncDataType.auditLogs:
      case SyncDataType.securitySettings:
        return true;
      case SyncDataType.deviceRegistry:
      case SyncDataType.backupMetadata:
        return false;
    }
  }
}
