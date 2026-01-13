import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../constants/storage_keys.dart';
import '../../error/failures.dart';
import '../../../shared/services/secure_storage_service.dart';
import 'encryption_service.dart';
import 'enhanced_biometric_service.dart';
import 'key_derivation_service.dart';

/// 생체인증 보호 키 관리 서비스.
///
/// **아키텍처 (2계층 보안):**
/// ```
/// ┌──────────────────────────────────────────────────────────────┐
/// │                  Biometric-Protected Key Flow                │
/// ├──────────────────────────────────────────────────────────────┤
/// │ [PIN 설정 시]                                                 │
/// │ 1. User PIN → PBKDF2 → PIN-based Key                         │
/// │ 2. Generate Random Biometric Key (32 bytes)                  │
/// │ 3. PIN-based Key encrypts Biometric Key                      │
/// │ 4. Encrypted Biometric Key → Secure Storage                  │
/// │ 5. Biometric Key → Platform Keystore (생체인증 보호)          │
/// ├──────────────────────────────────────────────────────────────┤
/// │ [생체인증으로 접근 시]                                         │
/// │ 1. Biometric Auth → 성공                                      │
/// │ 2. Biometric Key → Secure Storage에서 조회                    │
/// │ 3. Biometric Key → 니모닉 복호화에 사용                        │
/// ├──────────────────────────────────────────────────────────────┤
/// │ [PIN으로 접근 시 (폴백)]                                       │
/// │ 1. User PIN → PBKDF2 → PIN-based Key                         │
/// │ 2. PIN-based Key decrypts Encrypted Biometric Key            │
/// │ 3. Biometric Key → 니모닉 복호화에 사용                        │
/// └──────────────────────────────────────────────────────────────┘
/// ```
///
/// **보안 특성:**
/// - CSPRNG 기반 키 생성 (FortunaRandom)
/// - AES-256-GCM 암호화 (기존 EncryptionService 재사용)
/// - PBKDF2-SHA256 키 파생 (100,000 iterations)
/// - Android Keystore / iOS Keychain 플랫폼 보안
///
/// **사용 예시:**
/// ```dart
/// final service = BiometricKeyService(...);
///
/// // 1. 생체인증 키 생성 및 저장
/// await service.generateAndSaveBiometricKey(pin: '123456');
///
/// // 2. 생체인증으로 키 조회
/// final key = await service.getBiometricKey();
///
/// // 3. PIN으로 키 조회 (폴백)
/// final keyFromPin = await service.getBiometricKeyWithPin(pin: '123456');
/// ```
class BiometricKeyService {
  BiometricKeyService({
    required SecureStorageService secureStorage,
    required EnhancedBiometricService biometricService,
    required EncryptionService encryptionService,
    required KeyDerivationService keyDerivationService,
  })  : _secureStorage = secureStorage,
        _biometricService = biometricService,
        _encryptionService = encryptionService,
        _keyDerivationService = keyDerivationService;

  final SecureStorageService _secureStorage;
  final EnhancedBiometricService _biometricService;
  final EncryptionService _encryptionService;
  final KeyDerivationService _keyDerivationService;

  /// 생체인증 보호 키가 존재하는지 확인합니다.
  ///
  /// **반환값:**
  /// - `true`: 생체인증 키 존재
  /// - `false`: 생체인증 키 없음
  Future<bool> isBiometricKeyAvailable() async {
    final key = await _secureStorage.read(StorageKeys.biometricKey);
    return key != null;
  }

  /// 암호학적으로 안전한 랜덤 생체인증 키를 생성합니다.
  ///
  /// **반환값:**
  /// - Base64 인코딩된 32바이트 랜덤 키
  ///
  /// **보안 특성:**
  /// - FortunaRandom (CSPRNG)
  /// - 256비트 엔트로피
  String _generateBiometricKey() {
    final random = FortunaRandom();

    // Cryptographically Secure Seed
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seeds)));

    // 32바이트 (256비트) 랜덤 키 생성
    final keyBytes = random.nextBytes(EncryptionService.keyLength);

    return base64.encode(keyBytes);
  }

  /// 생체인증 보호 키를 생성하고 PIN으로 암호화하여 저장합니다.
  ///
  /// **매개변수:**
  /// - [pin]: 사용자 PIN (키 암호화에 사용)
  ///
  /// **저장 과정:**
  /// 1. 32바이트 랜덤 Biometric Key 생성
  /// 2. Salt 생성 또는 기존 Salt 사용
  /// 3. PIN + Salt → PBKDF2 → PIN-based Key
  /// 4. PIN-based Key로 Biometric Key 암호화
  /// 5. 암호화된 Biometric Key → Secure Storage 저장
  /// 6. Biometric Key → Secure Storage 저장 (플랫폼 암호화)
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 암호화 실패
  /// - [StorageFailure]: 저장소 쓰기 실패
  ///
  /// **주의사항:**
  /// - 생체인증 키는 플랫폼 Keystore/Keychain에 저장됨
  /// - PIN으로 암호화된 백업도 함께 저장됨 (PIN 복구 시나리오)
  Future<void> generateAndSaveBiometricKey({
    required String pin,
  }) async {
    try {
      // 1. 랜덤 Biometric Key 생성
      final biometricKey = _generateBiometricKey();

      // 2. Salt 생성 또는 기존 Salt 사용
      String salt;
      final existingSalt = await _secureStorage.read(StorageKeys.biometricKeySalt);
      if (existingSalt != null && _keyDerivationService.validateSalt(existingSalt)) {
        salt = existingSalt;
      } else {
        salt = _keyDerivationService.generateSalt();
        await _secureStorage.write(
          key: StorageKeys.biometricKeySalt,
          value: salt,
          isSensitive: true,
        );
      }

      // 3. PIN으로부터 암호화 키 파생
      final pinBasedKey = _keyDerivationService.deriveKey(
        pin: pin,
        salt: salt,
      );

      // 4. Biometric Key를 PIN-based Key로 암호화
      final encryptedBiometricKey = _encryptionService.encrypt(
        plaintext: biometricKey,
        key: pinBasedKey,
      );

      // 5. 암호화된 Biometric Key 저장 (PIN 복구용)
      await _secureStorage.write(
        key: StorageKeys.encryptedBiometricKey,
        value: encryptedBiometricKey,
        isSensitive: true,
      );

      // 6. Biometric Key 저장 (플랫폼 암호화)
      await _secureStorage.write(
        key: StorageKeys.biometricKey,
        value: biometricKey,
        isSensitive: true,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to generate and save biometric key', cause: e);
    }
  }

  /// 생체인증 후 생체인증 키를 조회합니다.
  ///
  /// **반환값:**
  /// - Base64 인코딩된 생체인증 키 (인증 성공 시)
  /// - `null` (생체인증 실패 또는 키 없음)
  ///
  /// **인증 흐름:**
  /// 1. 생체인증 수행
  /// 2. 인증 성공 → Secure Storage에서 키 조회
  /// 3. 키 반환
  ///
  /// **예외:**
  /// - [StorageFailure]: 저장소 읽기 실패
  ///
  /// **주의사항:**
  /// - 생체인증 실패 시 `null` 반환 (예외 발생 안 함)
  /// - 세션이 유효한 경우 재인증 없이 조회 가능
  Future<String?> getBiometricKey({
    String reason = '지갑 잠금을 해제하려면 인증이 필요합니다',
  }) async {
    try {
      // 1. 생체인증 수행
      final authenticated = await _biometricService.ensureAuthenticated(
        reason: reason,
      );

      if (!authenticated) {
        return null; // 인증 실패
      }

      // 2. Biometric Key 조회
      final biometricKey = await _secureStorage.read(StorageKeys.biometricKey);
      return biometricKey;
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to retrieve biometric key', cause: e);
    }
  }

  /// PIN으로 암호화된 생체인증 키를 복호화하여 조회합니다 (폴백).
  ///
  /// **매개변수:**
  /// - [pin]: 사용자 PIN
  ///
  /// **반환값:**
  /// - Base64 인코딩된 생체인증 키 (복호화 성공 시)
  /// - `null` (암호화된 키가 없는 경우)
  ///
  /// **복호화 흐름:**
  /// 1. 암호화된 Biometric Key 로드
  /// 2. Salt 로드
  /// 3. PIN + Salt → PBKDF2 → PIN-based Key
  /// 4. PIN-based Key로 복호화
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 복호화 실패 (잘못된 PIN)
  /// - [StorageFailure]: 저장소 읽기 실패
  ///
  /// **사용 사례:**
  /// - 생체인증 실패 시 PIN 폴백
  /// - 생체인증 비활성화 기기
  /// - 생체인증 정보 재등록 필요 시
  Future<String?> getBiometricKeyWithPin({
    required String pin,
  }) async {
    try {
      // 1. 암호화된 Biometric Key 로드
      final encryptedBiometricKey = await _secureStorage.read(
        StorageKeys.encryptedBiometricKey,
      );
      if (encryptedBiometricKey == null) {
        return null;
      }

      // 2. Salt 로드
      final salt = await _secureStorage.read(StorageKeys.biometricKeySalt);
      if (salt == null) {
        throw const CryptographyFailure('Biometric key salt not found');
      }

      // 3. PIN으로부터 암호화 키 파생
      final pinBasedKey = _keyDerivationService.deriveKey(
        pin: pin,
        salt: salt,
      );

      // 4. Biometric Key 복호화
      final biometricKey = _encryptionService.decrypt(
        ciphertext: encryptedBiometricKey,
        key: pinBasedKey,
      );

      return biometricKey;
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to retrieve biometric key with PIN', cause: e);
    }
  }

  /// 생체인증 키로 데이터를 암호화합니다.
  ///
  /// **매개변수:**
  /// - [plaintext]: 암호화할 평문
  /// - [pin]: 사용자 PIN (생체인증 실패 시 폴백)
  /// - [useBiometric]: `true`인 경우 생체인증 사용, `false`인 경우 PIN 사용
  ///
  /// **반환값:**
  /// - Base64 인코딩된 암호문
  ///
  /// **암호화 흐름:**
  /// 1. 생체인증 키 조회 (생체인증 또는 PIN)
  /// 2. AES-256-GCM 암호화
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 암호화 실패
  /// - [StorageFailure]: 생체인증 키 조회 실패
  ///
  /// **사용 예시:**
  /// ```dart
  /// // 생체인증으로 니모닉 암호화
  /// final encrypted = await service.encryptWithBiometricKey(
  ///   plaintext: mnemonic,
  ///   pin: userPin,
  ///   useBiometric: true,
  /// );
  ///
  /// // PIN으로 니모닉 암호화 (폴백)
  /// final encrypted = await service.encryptWithBiometricKey(
  ///   plaintext: mnemonic,
  ///   pin: userPin,
  ///   useBiometric: false,
  /// );
  /// ```
  Future<String> encryptWithBiometricKey({
    required String plaintext,
    required String pin,
    bool useBiometric = true,
  }) async {
    try {
      // 1. 생체인증 키 조회
      String? biometricKey;
      if (useBiometric) {
        biometricKey = await getBiometricKey();
      }

      // 생체인증 실패 시 PIN으로 폴백
      biometricKey ??= await getBiometricKeyWithPin(pin: pin);

      if (biometricKey == null) {
        throw const CryptographyFailure('Failed to retrieve biometric key');
      }

      // 2. AES-256-GCM 암호화
      return _encryptionService.encrypt(
        plaintext: plaintext,
        key: biometricKey,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw CryptographyFailure('Failed to encrypt with biometric key', cause: e);
    }
  }

  /// 생체인증 키로 데이터를 복호화합니다.
  ///
  /// **매개변수:**
  /// - [ciphertext]: 복호화할 암호문 (Base64 인코딩)
  /// - [pin]: 사용자 PIN (생체인증 실패 시 폴백)
  /// - [useBiometric]: `true`인 경우 생체인증 사용, `false`인 경우 PIN 사용
  ///
  /// **반환값:**
  /// - 복호화된 평문
  ///
  /// **복호화 흐름:**
  /// 1. 생체인증 키 조회 (생체인증 또는 PIN)
  /// 2. AES-256-GCM 복호화
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 복호화 실패
  /// - [StorageFailure]: 생체인증 키 조회 실패
  ///
  /// **사용 예시:**
  /// ```dart
  /// // 생체인증으로 니모닉 복호화
  /// final mnemonic = await service.decryptWithBiometricKey(
  ///   ciphertext: encrypted,
  ///   pin: userPin,
  ///   useBiometric: true,
  /// );
  ///
  /// // PIN으로 니모닉 복호화 (폴백)
  /// final mnemonic = await service.decryptWithBiometricKey(
  ///   ciphertext: encrypted,
  ///   pin: userPin,
  ///   useBiometric: false,
  /// );
  /// ```
  Future<String> decryptWithBiometricKey({
    required String ciphertext,
    required String pin,
    bool useBiometric = true,
  }) async {
    try {
      // 1. 생체인증 키 조회
      String? biometricKey;
      if (useBiometric) {
        biometricKey = await getBiometricKey();
      }

      // 생체인증 실패 시 PIN으로 폴백
      biometricKey ??= await getBiometricKeyWithPin(pin: pin);

      if (biometricKey == null) {
        throw const CryptographyFailure('Failed to retrieve biometric key');
      }

      // 2. AES-256-GCM 복호화
      return _encryptionService.decrypt(
        ciphertext: ciphertext,
        key: biometricKey,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw CryptographyFailure('Failed to decrypt with biometric key', cause: e);
    }
  }

  /// 생체인증 키와 관련 데이터를 모두 삭제합니다.
  ///
  /// **삭제 대상:**
  /// - Biometric Key
  /// - Encrypted Biometric Key
  /// - Biometric Key Salt
  ///
  /// **예외:**
  /// - [StorageFailure]: 삭제 실패
  ///
  /// **사용 사례:**
  /// - 지갑 삭제
  /// - 생체인증 비활성화
  /// - 보안 초기화
  Future<void> deleteBiometricKey() async {
    try {
      await _secureStorage.delete(StorageKeys.biometricKey);
      await _secureStorage.delete(StorageKeys.encryptedBiometricKey);
      await _secureStorage.delete(StorageKeys.biometricKeySalt);
    } catch (e) {
      throw StorageFailure('Failed to delete biometric key', cause: e);
    }
  }

  /// PIN을 변경하면서 생체인증 키를 재암호화합니다.
  ///
  /// **매개변수:**
  /// - [oldPin]: 기존 PIN
  /// - [newPin]: 새로운 PIN
  ///
  /// **재암호화 과정:**
  /// 1. 기존 PIN으로 Biometric Key 복호화
  /// 2. 새로운 Salt 생성
  /// 3. 새로운 PIN + Salt → PBKDF2 → 새로운 PIN-based Key
  /// 4. 새로운 PIN-based Key로 Biometric Key 재암호화
  /// 5. 재암호화된 데이터 저장
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 복호화 또는 암호화 실패
  /// - [StorageFailure]: 저장소 쓰기 실패
  ///
  /// **주의사항:**
  /// - 기존 PIN이 틀리면 복호화 실패
  /// - Biometric Key 자체는 변경되지 않음 (PIN 암호화만 변경)
  Future<void> changePinForBiometricKey({
    required String oldPin,
    required String newPin,
  }) async {
    try {
      // 1. 기존 PIN으로 Biometric Key 복호화
      final biometricKey = await getBiometricKeyWithPin(pin: oldPin);
      if (biometricKey == null) {
        throw const CryptographyFailure('Failed to decrypt biometric key with old PIN');
      }

      // 2. 새로운 Salt 생성
      final newSalt = _keyDerivationService.generateSalt();

      // 3. 새로운 PIN으로 암호화 키 파생
      final newPinBasedKey = _keyDerivationService.deriveKey(
        pin: newPin,
        salt: newSalt,
      );

      // 4. Biometric Key를 새로운 PIN-based Key로 재암호화
      final reEncryptedBiometricKey = _encryptionService.encrypt(
        plaintext: biometricKey,
        key: newPinBasedKey,
      );

      // 5. 재암호화된 데이터 저장
      await _secureStorage.write(
        key: StorageKeys.encryptedBiometricKey,
        value: reEncryptedBiometricKey,
        isSensitive: true,
      );

      await _secureStorage.write(
        key: StorageKeys.biometricKeySalt,
        value: newSalt,
        isSensitive: true,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw CryptographyFailure('Failed to change PIN for biometric key', cause: e);
    }
  }
}
