import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../services/encryption_service.dart';
import '../services/key_derivation_service.dart';
import 'sync_payload.dart';

/// E2E 암호화 동기화 프로토콜.
///
/// **보안 아키텍처:**
/// ```
/// ┌─────────────────────────────────────────────────────────┐
/// │ Client                                                   │
/// │ ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐ │
/// │ │ Raw Data    │→│ AES-256-GCM  │→│ TLS 1.3 Channel  │ │
/// │ │ (plaintext) │  │ E2E Encrypt  │  │ (transport)     │ │
/// │ └─────────────┘  └──────────────┘  └─────────────────┘ │
/// └─────────────────────────────────────────────────────────┘
///                           ↓
/// ┌─────────────────────────────────────────────────────────┐
/// │ Server (Zero-Knowledge)                                  │
/// │ - 암호화된 blob만 저장                                   │
/// │ - 복호화 키 미보유                                       │
/// │ - 메타데이터만 인덱싱                                    │
/// └─────────────────────────────────────────────────────────┘
/// ```
///
/// **키 파생 체계:**
/// ```
/// Master Key (사용자 PIN/생체인증)
///     │
///     ├─> PBKDF2-SHA512
///     │   - Salt: 동기화 전용 Salt
///     │   - Iterations: 100,000
///     │   - Context: "SYNC_KEY_V1"
///     │
///     └─> Sync Key (AES-256)
///         - 동기화 암호화 전용
///         - 디바이스 간 공유 불가
///         - 안전한 저장소에 보관
/// ```
class SecureSyncProtocol {
  SecureSyncProtocol({
    required EncryptionService encryptionService,
    required KeyDerivationService keyDerivationService,
  })  : _encryptionService = encryptionService,
        _keyDerivationService = keyDerivationService,
        _uuid = const Uuid();

  final EncryptionService _encryptionService;
  final KeyDerivationService _keyDerivationService;
  final Uuid _uuid;

  /// 동기화 키 컨텍스트 (키 파생 시 사용).
  static const String syncKeyContext = 'SYNC_KEY_V1';

  /// 동기화 키를 생성합니다 (마스터 키에서 파생).
  ///
  /// **매개변수:**
  /// - [masterKey]: 마스터 키 (Base64)
  /// - [salt]: Salt (Base64)
  /// - [context]: 키 파생 컨텍스트 (기본값: SYNC_KEY_V1)
  ///
  /// **반환값:**
  /// - Base64 인코딩된 동기화 키 (32바이트)
  ///
  /// **보안:**
  /// - PBKDF2-SHA256, 100,000 iterations
  /// - 컨텍스트별 키 분리 (용도별 다른 키)
  /// - Salt는 동기화 전용으로 생성 권장
  Future<String> deriveSyncKey({
    required String masterKey,
    required String salt,
    String context = syncKeyContext,
  }) async {
    // 컨텍스트를 마스터 키에 혼합
    final contextualKey = _mixContext(masterKey, context);

    // PBKDF2로 키 파생
    return _keyDerivationService.deriveKey(
      pin: contextualKey,
      salt: salt,
    );
  }

  /// 페이로드를 암호화합니다.
  ///
  /// **매개변수:**
  /// - [data]: 평문 데이터 (JSON 문자열)
  /// - [dataType]: 데이터 유형
  /// - [syncKey]: 동기화 키 (Base64)
  /// - [deviceId]: 디바이스 ID
  ///
  /// **반환값:**
  /// - 암호화된 [SyncPayload]
  ///
  /// **보안:**
  /// - AES-256-GCM (인증 암호화)
  /// - 랜덤 IV (매번 다른 IV)
  /// - SHA-256 체크섬 (무결성 검증)
  Future<SyncPayload> encryptPayload({
    required String data,
    required SyncDataType dataType,
    required String syncKey,
    required String deviceId,
    int version = 1,
  }) async {
    // AES-GCM 암호화
    final encrypted = _encryptionService.encrypt(
      plaintext: data,
      key: syncKey,
    );

    // 암호문을 Base64 디코딩하여 IV와 암호문 분리
    final combined = base64.decode(encrypted);
    final iv = base64.encode(combined.sublist(0, 12)); // IV (12바이트)
    final cipherWithTag = combined.sublist(12);
    final ciphertext = base64.encode(
      cipherWithTag.sublist(0, cipherWithTag.length - 16),
    );
    final authTag = base64.encode(
      cipherWithTag.sublist(cipherWithTag.length - 16),
    );

    // 체크섬 생성 (원본 데이터)
    final checksum = generateChecksum(data);

    // 페이로드 생성
    return SyncPayload(
      id: _uuid.v4(),
      dataType: dataType,
      encryptedData: ciphertext,
      iv: iv,
      authTag: authTag,
      version: version,
      timestamp: DateTime.now().toUtc(),
      deviceId: deviceId,
      checksum: checksum,
    );
  }

  /// 페이로드를 복호화합니다.
  ///
  /// **매개변수:**
  /// - [payload]: 암호화된 페이로드
  /// - [syncKey]: 동기화 키 (Base64)
  ///
  /// **반환값:**
  /// - 복호화된 평문 데이터
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 복호화 실패 또는 체크섬 불일치
  ///
  /// **보안:**
  /// - 복호화 전 체크섬 검증
  /// - Authentication Tag 검증 (GCM)
  /// - 실패 시 예외 발생
  Future<String> decryptPayload({
    required SyncPayload payload,
    required String syncKey,
  }) async {
    // IV, 암호문, Tag 결합
    final ivBytes = base64.decode(payload.iv);
    final cipherBytes = base64.decode(payload.encryptedData);
    final tagBytes = base64.decode(payload.authTag);

    final combined = <int>[
      ...ivBytes,
      ...cipherBytes,
      ...tagBytes,
    ];

    final encryptedData = base64.encode(combined);

    // AES-GCM 복호화
    final decrypted = _encryptionService.decrypt(
      ciphertext: encryptedData,
      key: syncKey,
    );

    // 체크섬 검증
    if (!verifyChecksum(payload, decrypted)) {
      throw Exception('Checksum verification failed');
    }

    return decrypted;
  }

  /// 체크섬을 생성합니다 (SHA-256).
  ///
  /// **매개변수:**
  /// - [data]: 체크섬을 계산할 데이터
  ///
  /// **반환값:**
  /// - Hex 인코딩된 SHA-256 해시
  String generateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 체크섬을 검증합니다.
  ///
  /// **매개변수:**
  /// - [payload]: 검증할 페이로드
  /// - [decryptedData]: 복호화된 데이터
  ///
  /// **반환값:**
  /// - 체크섬이 일치하면 `true`, 그렇지 않으면 `false`
  bool verifyChecksum(SyncPayload payload, String decryptedData) {
    final calculatedChecksum = generateChecksum(decryptedData);
    return calculatedChecksum == payload.checksum;
  }

  /// 디바이스 ID를 생성합니다.
  ///
  /// **반환값:**
  /// - UUID v4 형식의 디바이스 ID
  String generateDeviceId() {
    return _uuid.v4();
  }

  /// 컨텍스트를 키에 혼합합니다.
  ///
  /// 키 파생 시 컨텍스트를 포함하여 용도별로 다른 키를 생성합니다.
  String _mixContext(String key, String context) {
    final keyBytes = utf8.encode(key);
    final contextBytes = utf8.encode(context);
    final combined = <int>[...keyBytes, ...contextBytes];
    final digest = sha256.convert(combined);
    return base64.encode(digest.bytes);
  }
}
