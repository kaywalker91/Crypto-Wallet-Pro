import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../error/failures.dart';

/// AES-256-GCM 암호화/복호화 서비스.
///
/// Galois/Counter Mode (GCM)를 사용한 고급 암호화 표준 구현체입니다.
///
/// **보안 특성:**
/// - AES-256-GCM (Authenticated Encryption with Associated Data)
/// - 96-bit IV (GCM 표준 권장)
/// - 128-bit Authentication Tag (변조 방지)
/// - 매 암호화마다 랜덤 IV 생성 (재사용 방지)
///
/// **암호화 데이터 포맷:**
/// ```
/// [IV (12 bytes)] || [Ciphertext (variable)] || [Auth Tag (16 bytes)]
/// └─────────────────────────────────────────────────────────────────┘
///                        Base64 인코딩
/// ```
///
/// **사용 예시:**
/// ```dart
/// final service = EncryptionService();
/// final encrypted = service.encrypt(plaintext: 'secret', key: derivedKey);
/// final decrypted = service.decrypt(ciphertext: encrypted, key: derivedKey);
/// ```
class EncryptionService {
  /// IV 길이 (바이트).
  ///
  /// GCM 모드 표준 권장: 96비트 = 12바이트
  static const int ivLength = 12;

  /// Authentication Tag 길이 (비트).
  ///
  /// GCM 모드 표준: 128비트 (16바이트)
  static const int macLength = 128;

  /// AES 키 길이 (바이트).
  ///
  /// AES-256: 256비트 = 32바이트
  static const int keyLength = 32;

  /// 평문을 AES-256-GCM으로 암호화합니다.
  ///
  /// **매개변수:**
  /// - [plaintext]: 암호화할 평문
  /// - [key]: AES-256 키 (Base64 인코딩, 32바이트)
  ///
  /// **반환값:**
  /// - Base64 인코딩된 암호화 데이터 (IV + Ciphertext + Tag)
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 암호화 실패 시
  ///
  /// **주의사항:**
  /// - 매 호출마다 새로운 랜덤 IV를 생성합니다
  /// - 동일한 평문이라도 매번 다른 암호문이 생성됩니다
  String encrypt({
    required String plaintext,
    required String key,
  }) {
    try {
      // 키 검증 및 디코딩
      final keyBytes = _validateAndDecodeKey(key);

      // 랜덤 IV 생성
      final iv = _generateIV();

      // AES-GCM 암호화 엔진 초기화
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(keyBytes),
        macLength,
        iv,
        Uint8List(0), // Additional Authenticated Data (사용 안 함)
      );
      cipher.init(true, params); // true = 암호화 모드

      // 평문을 UTF-8 바이트로 변환
      final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

      // 암호화 수행
      final ciphertext = cipher.process(plaintextBytes);

      // IV || Ciphertext (Tag 포함) 결합
      final combined = Uint8List(iv.length + ciphertext.length);
      combined.setRange(0, iv.length, iv);
      combined.setRange(iv.length, combined.length, ciphertext);

      // Base64 인코딩
      return base64.encode(combined);
    } catch (e) {
      if (e is CryptographyFailure) rethrow;
      throw CryptographyFailure('Encryption failed', cause: e);
    }
  }

  /// AES-256-GCM 암호문을 복호화합니다.
  ///
  /// **매개변수:**
  /// - [ciphertext]: 암호화된 데이터 (Base64 인코딩)
  /// - [key]: AES-256 키 (Base64 인코딩, 32바이트)
  ///
  /// **반환값:**
  /// - 복호화된 평문
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 복호화 실패 시 (잘못된 키, 변조된 데이터 등)
  ///
  /// **주의사항:**
  /// - Authentication Tag 검증 실패 시 예외 발생 (변조 감지)
  /// - 잘못된 키 사용 시 복호화 실패
  String decrypt({
    required String ciphertext,
    required String key,
  }) {
    try {
      // 키 검증 및 디코딩
      final keyBytes = _validateAndDecodeKey(key);

      // Base64 디코딩
      final combined = base64.decode(ciphertext);

      // 최소 길이 검증 (IV + Tag 최소값)
      if (combined.length < ivLength + (macLength ~/ 8)) {
        throw const CryptographyFailure('Invalid ciphertext format');
      }

      // IV와 암호문 분리
      final iv = combined.sublist(0, ivLength);
      final encrypted = combined.sublist(ivLength);

      // AES-GCM 복호화 엔진 초기화
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(keyBytes),
        macLength,
        iv,
        Uint8List(0),
      );
      cipher.init(false, params); // false = 복호화 모드

      // 복호화 수행 (Tag 검증 포함)
      final decrypted = cipher.process(encrypted);

      // UTF-8 문자열로 변환
      return utf8.decode(decrypted);
    } catch (e) {
      if (e is CryptographyFailure) rethrow;
      throw CryptographyFailure('Decryption failed', cause: e);
    }
  }

  /// 암호학적으로 안전한 랜덤 IV를 생성합니다.
  ///
  /// **반환값:**
  /// - 12바이트 랜덤 IV
  ///
  /// **주의사항:**
  /// - FortunaRandom 사용 (CSPRNG)
  /// - IV는 절대 재사용하면 안 됩니다 (GCM 모드 보안 요구사항)
  Uint8List _generateIV() {
    final random = FortunaRandom();

    // 시드 초기화 (Cryptographically Secure)
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seeds)));

    return random.nextBytes(ivLength);
  }

  /// Base64 키를 검증하고 바이트로 변환합니다.
  ///
  /// **매개변수:**
  /// - [key]: Base64 인코딩된 키
  ///
  /// **반환값:**
  /// - 32바이트 키
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 잘못된 키 길이 또는 형식
  Uint8List _validateAndDecodeKey(String key) {
    try {
      final keyBytes = base64.decode(key);
      if (keyBytes.length != keyLength) {
        throw CryptographyFailure(
          'Invalid key length: expected $keyLength bytes, got ${keyBytes.length}',
        );
      }
      return keyBytes;
    } catch (e) {
      if (e is CryptographyFailure) rethrow;
      throw CryptographyFailure('Invalid key format', cause: e);
    }
  }
}
