import 'dart:convert';

import '../../../core/constants/storage_keys.dart';
import '../../../core/error/failures.dart';
import '../../../shared/services/secure_storage_service.dart';
import 'encryption_service.dart';
import 'key_derivation_service.dart';

/// 이중 암호화 저장소 서비스.
///
/// **Defense-in-Depth 아키텍처:**
/// ```
/// ┌────────────────────────────────────────────────────────────┐
/// │ Layer 2: 플랫폼 암호화 (Android Keystore / iOS Keychain)  │
/// ├────────────────────────────────────────────────────────────┤
/// │ Layer 1: 앱 레벨 암호화 (AES-256-GCM + PBKDF2)            │
/// └────────────────────────────────────────────────────────────┘
/// ```
///
/// **암호화 흐름:**
/// 1. 사용자 PIN → PBKDF2-SHA256 → 파생 키 (256-bit)
/// 2. 니모닉 평문 → AES-256-GCM 암호화 → 암호문
/// 3. 암호문 → Flutter Secure Storage (플랫폼 암호화)
///
/// **복호화 흐름:**
/// 1. Flutter Secure Storage → 암호문
/// 2. 사용자 PIN → PBKDF2-SHA256 → 파생 키
/// 3. 암호문 → AES-256-GCM 복호화 → 니모닉 평문
///
/// **보안 특성:**
/// - 물리적 접근 보호: 플랫폼 암호화 (Keychain/Keystore)
/// - 논리적 접근 보호: 앱 레벨 암호화 (PIN 필요)
/// - 변조 방지: GCM 모드 Authentication Tag
/// - 브루트포스 방지: PBKDF2 100,000 iterations
///
/// **사용 예시:**
/// ```dart
/// final service = EncryptedStorageService(...);
///
/// // 니모닉 저장 (PIN 기반 암호화)
/// await service.saveMnemonic(mnemonic: 'word1 word2 ...', pin: '123456');
///
/// // 니모닉 조회 (PIN 기반 복호화)
/// final mnemonic = await service.getMnemonic(pin: '123456');
/// ```
class EncryptedStorageService {
  EncryptedStorageService({
    required SecureStorageService secureStorage,
    required EncryptionService encryptionService,
    required KeyDerivationService keyDerivationService,
  })  : _secureStorage = secureStorage,
        _encryptionService = encryptionService,
        _keyDerivationService = keyDerivationService;

  final SecureStorageService _secureStorage;
  final EncryptionService _encryptionService;
  final KeyDerivationService _keyDerivationService;

  /// PIN 기반으로 니모닉을 암호화하여 저장합니다.
  ///
  /// **매개변수:**
  /// - [mnemonic]: 저장할 니모닉 구문
  /// - [pin]: 암호화에 사용할 사용자 PIN
  ///
  /// **저장 과정:**
  /// 1. Salt 생성 (또는 기존 Salt 사용)
  /// 2. PIN + Salt → PBKDF2 → 파생 키
  /// 3. 니모닉 평문 → AES-GCM 암호화 → 암호문
  /// 4. 암호문 → Secure Storage 저장
  /// 5. Salt → Secure Storage 저장 (별도 키)
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 암호화 실패
  /// - [StorageFailure]: 저장소 쓰기 실패
  ///
  /// **주의사항:**
  /// - 동일한 PIN을 사용해야 복호화 가능
  /// - Salt는 자동으로 생성 및 저장됨
  Future<void> saveMnemonic({
    required String mnemonic,
    required String pin,
  }) async {
    try {
      // 1. Salt 생성 또는 기존 Salt 로드
      String salt;
      final existingSalt = await _secureStorage.read(StorageKeys.pinSalt);
      if (existingSalt != null && _keyDerivationService.validateSalt(existingSalt)) {
        salt = existingSalt;
      } else {
        salt = _keyDerivationService.generateSalt();
        await _secureStorage.write(
          key: StorageKeys.pinSalt,
          value: salt,
          isSensitive: true,
        );
      }

      // 2. PIN으로부터 암호화 키 파생
      final derivedKey = _keyDerivationService.deriveKey(
        pin: pin,
        salt: salt,
      );

      // 3. 니모닉 암호화
      final encryptedMnemonic = _encryptionService.encrypt(
        plaintext: mnemonic,
        key: derivedKey,
      );

      // 4. 암호문 저장
      await _secureStorage.write(
        key: StorageKeys.mnemonic,
        value: encryptedMnemonic,
        isSensitive: true,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to save encrypted mnemonic', cause: e);
    }
  }

  /// PIN 기반으로 니모닉을 복호화하여 조회합니다.
  ///
  /// **매개변수:**
  /// - [pin]: 복호화에 사용할 사용자 PIN
  ///
  /// **반환값:**
  /// - 복호화된 니모닉 구문 (PIN이 올바른 경우)
  /// - `null` (저장된 니모닉이 없는 경우)
  ///
  /// **복호화 과정:**
  /// 1. Salt 로드
  /// 2. PIN + Salt → PBKDF2 → 파생 키
  /// 3. 암호문 → AES-GCM 복호화 → 니모닉 평문
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 복호화 실패 (잘못된 PIN, 변조된 데이터 등)
  /// - [StorageFailure]: 저장소 읽기 실패
  ///
  /// **주의사항:**
  /// - 잘못된 PIN 사용 시 복호화 실패 (Authentication Tag 검증 실패)
  /// - Salt가 없으면 복호화 불가
  Future<String?> getMnemonic({
    required String pin,
  }) async {
    try {
      // 1. 암호문 로드
      final encryptedMnemonic = await _secureStorage.read(StorageKeys.mnemonic);
      if (encryptedMnemonic == null) {
        return null;
      }

      // 2. Salt 로드
      final salt = await _secureStorage.read(StorageKeys.pinSalt);
      if (salt == null) {
        throw const CryptographyFailure('Salt not found');
      }

      // 3. PIN으로부터 암호화 키 파생
      final derivedKey = _keyDerivationService.deriveKey(
        pin: pin,
        salt: salt,
      );

      // 4. 니모닉 복호화
      final mnemonic = _encryptionService.decrypt(
        ciphertext: encryptedMnemonic,
        key: derivedKey,
      );

      return mnemonic;
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to retrieve encrypted mnemonic', cause: e);
    }
  }

  /// 저장된 니모닉이 평문인지 암호문인지 확인합니다.
  ///
  /// **반환값:**
  /// - `true`: 평문 니모닉 (마이그레이션 필요)
  /// - `false`: 암호문 또는 없음
  ///
  /// **판별 기준:**
  /// - Salt가 없으면 평문으로 간주
  /// - Base64 디코딩 실패 시 평문으로 간주
  Future<bool> isPlaintextMnemonic() async {
    try {
      final mnemonic = await _secureStorage.read(StorageKeys.mnemonic);
      if (mnemonic == null) return false;

      final salt = await _secureStorage.read(StorageKeys.pinSalt);
      if (salt == null) return true; // Salt 없음 = 평문

      // 암호화된 데이터는 Base64 형식이어야 함
      // 평문 니모닉은 일반 텍스트 (단어들)
      return !_isBase64(mnemonic);
    } catch (e) {
      return true; // 오류 시 안전하게 평문으로 간주
    }
  }

  /// 평문 니모닉을 암호문으로 마이그레이션합니다.
  ///
  /// **매개변수:**
  /// - [pin]: 암호화에 사용할 사용자 PIN
  ///
  /// **마이그레이션 과정:**
  /// 1. 평문 니모닉 로드
  /// 2. PIN 기반 암호화
  /// 3. 암호문으로 덮어쓰기
  ///
  /// **예외:**
  /// - [StorageFailure]: 마이그레이션 실패
  ///
  /// **주의사항:**
  /// - 기존 평문 니모닉이 없으면 아무 작업도 하지 않음
  /// - 이미 암호화된 경우 재암호화하지 않음
  Future<void> migratePlaintextMnemonic({
    required String pin,
  }) async {
    try {
      // 평문 확인
      final isPlaintext = await isPlaintextMnemonic();
      if (!isPlaintext) {
        return; // 이미 암호화됨
      }

      // 평문 니모닉 로드
      final plaintextMnemonic = await _secureStorage.read(StorageKeys.mnemonic);
      if (plaintextMnemonic == null) {
        return; // 니모닉 없음
      }

      // 암호화하여 저장
      await saveMnemonic(mnemonic: plaintextMnemonic, pin: pin);
    } catch (e) {
      throw StorageFailure('Failed to migrate plaintext mnemonic', cause: e);
    }
  }

  /// 니모닉과 관련 데이터를 모두 삭제합니다.
  ///
  /// **삭제 대상:**
  /// - 니모닉 (평문 또는 암호문)
  /// - Salt
  ///
  /// **예외:**
  /// - [StorageFailure]: 삭제 실패
  Future<void> deleteMnemonic() async {
    try {
      await _secureStorage.delete(StorageKeys.mnemonic);
      await _secureStorage.delete(StorageKeys.pinSalt);
    } catch (e) {
      throw StorageFailure('Failed to delete mnemonic', cause: e);
    }
  }

  /// 문자열이 유효한 Base64 형식인지 확인합니다.
  ///
  /// 암호화된 데이터는 Base64로 인코딩되어야 하며,
  /// 평문 니모닉은 일반 텍스트 (단어 공백으로 구분)입니다.
  bool _isBase64(String str) {
    try {
      // Base64 디코딩 시도
      base64.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}
