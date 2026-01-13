import 'package:equatable/equatable.dart';

/// HSM 키 타입
enum HsmKeyType {
  /// RSA 2048-bit
  rsa2048,

  /// RSA 4096-bit
  rsa4096,

  /// ECC P-256 (secp256r1)
  eccP256,

  /// ECC P-384 (secp384r1)
  eccP384,

  /// AES-256
  aes256,
}

/// HSM 키 용도
enum HsmKeyPurpose {
  /// 서명 전용
  sign,

  /// 검증 전용
  verify,

  /// 암호화 전용
  encrypt,

  /// 복호화 전용
  decrypt,

  /// 서명 및 검증
  signVerify,

  /// 암호화 및 복호화
  encryptDecrypt,
}

/// HSM 키 메타데이터
///
/// 하드웨어 보안 모듈에 저장된 키의 정보
class HsmKey extends Equatable {
  /// 키 식별자 (고유 ID)
  final String keyId;

  /// 키 별칭 (사용자 친화적 이름)
  final String alias;

  /// 키 타입
  final HsmKeyType keyType;

  /// 키 용도
  final List<HsmKeyPurpose> purposes;

  /// 하드웨어 기반 여부
  final bool isHardwareBacked;

  /// 생체 인증 필수 여부
  final bool requiresBiometric;

  /// 생성 시각
  final DateTime createdAt;

  /// 만료 시각 (null이면 무기한)
  final DateTime? expiresAt;

  /// 공개 키 (Base64 인코딩)
  final String? publicKey;

  /// 키가 내보내기 가능한지 여부
  final bool isExportable;

  const HsmKey({
    required this.keyId,
    required this.alias,
    required this.keyType,
    required this.purposes,
    required this.isHardwareBacked,
    this.requiresBiometric = false,
    required this.createdAt,
    this.expiresAt,
    this.publicKey,
    this.isExportable = false,
  });

  /// 서명용 키인지 확인
  bool get canSign =>
      purposes.contains(HsmKeyPurpose.sign) ||
      purposes.contains(HsmKeyPurpose.signVerify);

  /// 검증용 키인지 확인
  bool get canVerify =>
      purposes.contains(HsmKeyPurpose.verify) ||
      purposes.contains(HsmKeyPurpose.signVerify);

  /// 암호화용 키인지 확인
  bool get canEncrypt =>
      purposes.contains(HsmKeyPurpose.encrypt) ||
      purposes.contains(HsmKeyPurpose.encryptDecrypt);

  /// 복호화용 키인지 확인
  bool get canDecrypt =>
      purposes.contains(HsmKeyPurpose.decrypt) ||
      purposes.contains(HsmKeyPurpose.encryptDecrypt);

  /// 키가 만료되었는지 확인
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 키가 유효한지 확인 (만료되지 않음)
  bool get isValid => !isExpired;

  /// 키 타입의 알고리즘 이름 반환
  String get algorithmName {
    switch (keyType) {
      case HsmKeyType.rsa2048:
      case HsmKeyType.rsa4096:
        return 'RSA';
      case HsmKeyType.eccP256:
      case HsmKeyType.eccP384:
        return 'EC';
      case HsmKeyType.aes256:
        return 'AES';
    }
  }

  /// 키 크기 (비트)
  int get keySize {
    switch (keyType) {
      case HsmKeyType.rsa2048:
        return 2048;
      case HsmKeyType.rsa4096:
        return 4096;
      case HsmKeyType.eccP256:
        return 256;
      case HsmKeyType.eccP384:
        return 384;
      case HsmKeyType.aes256:
        return 256;
    }
  }

  @override
  List<Object?> get props => [
        keyId,
        alias,
        keyType,
        purposes,
        isHardwareBacked,
        requiresBiometric,
        createdAt,
        expiresAt,
        publicKey,
        isExportable,
      ];

  @override
  String toString() {
    return 'HsmKey(keyId: $keyId, alias: $alias, type: $keyType, '
        'hardwareBacked: $isHardwareBacked, valid: $isValid)';
  }

  /// 키 복사 (업데이트용)
  HsmKey copyWith({
    String? keyId,
    String? alias,
    HsmKeyType? keyType,
    List<HsmKeyPurpose>? purposes,
    bool? isHardwareBacked,
    bool? requiresBiometric,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? publicKey,
    bool? isExportable,
  }) {
    return HsmKey(
      keyId: keyId ?? this.keyId,
      alias: alias ?? this.alias,
      keyType: keyType ?? this.keyType,
      purposes: purposes ?? this.purposes,
      isHardwareBacked: isHardwareBacked ?? this.isHardwareBacked,
      requiresBiometric: requiresBiometric ?? this.requiresBiometric,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      publicKey: publicKey ?? this.publicKey,
      isExportable: isExportable ?? this.isExportable,
    );
  }
}
