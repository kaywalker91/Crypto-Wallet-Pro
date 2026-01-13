import 'dart:typed_data';
import 'hsm_capability.dart';
import 'hsm_key.dart';

/// HSM 제공자 인터페이스
///
/// 플랫폼별 HSM 구현체가 구현해야 하는 추상 인터페이스.
/// iOS Secure Enclave, Android StrongBox, 소프트웨어 폴백 등
/// 다양한 구현체를 추상화합니다.
abstract class HsmProvider {
  /// HSM 정보 반환
  Future<HsmInfo> getHsmInfo();

  /// HSM 초기화
  Future<void> initialize();

  /// 키 생성
  ///
  /// [alias]: 키의 별칭 (사용자 친화적 이름)
  /// [keyType]: 생성할 키 타입
  /// [purposes]: 키 용도 목록
  /// [requiresBiometric]: 생체 인증 필수 여부
  /// [expiresAt]: 키 만료 시각 (null이면 무기한)
  ///
  /// Returns: 생성된 키의 메타데이터
  Future<HsmKey> generateKey({
    required String alias,
    required HsmKeyType keyType,
    required List<HsmKeyPurpose> purposes,
    bool requiresBiometric = false,
    DateTime? expiresAt,
  });

  /// 키 조회
  ///
  /// [keyId]: 조회할 키의 ID
  ///
  /// Returns: 키 메타데이터 (없으면 null)
  Future<HsmKey?> getKey(String keyId);

  /// 별칭으로 키 조회
  ///
  /// [alias]: 키의 별칭
  ///
  /// Returns: 키 메타데이터 (없으면 null)
  Future<HsmKey?> getKeyByAlias(String alias);

  /// 모든 키 목록 조회
  ///
  /// Returns: 저장된 모든 키의 목록
  Future<List<HsmKey>> listKeys();

  /// 키 삭제
  ///
  /// [keyId]: 삭제할 키의 ID
  ///
  /// Returns: 삭제 성공 여부
  Future<bool> deleteKey(String keyId);

  /// 데이터 서명
  ///
  /// [keyId]: 서명에 사용할 키 ID
  /// [data]: 서명할 데이터
  ///
  /// Returns: 서명 값 (바이트 배열)
  ///
  /// Throws: Exception if key doesn't support signing
  Future<Uint8List> sign({
    required String keyId,
    required Uint8List data,
  });

  /// 서명 검증
  ///
  /// [keyId]: 검증에 사용할 키 ID
  /// [data]: 원본 데이터
  /// [signature]: 서명 값
  ///
  /// Returns: 서명이 유효하면 true
  ///
  /// Throws: Exception if key doesn't support verification
  Future<bool> verify({
    required String keyId,
    required Uint8List data,
    required Uint8List signature,
  });

  /// 데이터 암호화
  ///
  /// [keyId]: 암호화에 사용할 키 ID
  /// [plaintext]: 평문 데이터
  ///
  /// Returns: 암호문 (바이트 배열)
  ///
  /// Throws: Exception if key doesn't support encryption
  Future<Uint8List> encrypt({
    required String keyId,
    required Uint8List plaintext,
  });

  /// 데이터 복호화
  ///
  /// [keyId]: 복호화에 사용할 키 ID
  /// [ciphertext]: 암호문
  ///
  /// Returns: 평문 데이터
  ///
  /// Throws: Exception if key doesn't support decryption
  Future<Uint8List> decrypt({
    required String keyId,
    required Uint8List ciphertext,
  });

  /// 키가 존재하는지 확인
  ///
  /// [keyId]: 확인할 키의 ID
  ///
  /// Returns: 키가 존재하면 true
  Future<bool> keyExists(String keyId);

  /// HSM이 사용 가능한지 확인
  ///
  /// Returns: HSM이 초기화되고 사용 가능하면 true
  Future<bool> isAvailable();

  /// 특정 기능 지원 여부 확인
  ///
  /// [capability]: 확인할 기능
  ///
  /// Returns: 기능을 지원하면 true
  Future<bool> supportsCapability(HsmCapability capability);
}
