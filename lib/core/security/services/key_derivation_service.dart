import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../error/failures.dart';

/// 암호화 키 파생 서비스 (PBKDF2-SHA256).
///
/// PIN 또는 패스워드로부터 암호학적으로 안전한 암호화 키를 생성합니다.
///
/// **보안 특성:**
/// - PBKDF2-SHA256 알고리즘 사용
/// - 100,000 iterations (OWASP 2024 권장치)
/// - 32바이트 (256비트) 키 생성
/// - 32바이트 랜덤 Salt 생성
///
/// **사용 예시:**
/// ```dart
/// final service = KeyDerivationService();
/// final salt = service.generateSalt();
/// final key = service.deriveKey(pin: '123456', salt: salt);
/// ```
class KeyDerivationService {
  /// PBKDF2 반복 횟수 (보안 강도 결정).
  ///
  /// OWASP 2024 권장:
  /// - 최소 100,000 iterations
  /// - 권장 600,000 iterations (최신 하드웨어 기준)
  static const int kdfIterations = 100000;

  /// 파생 키 길이 (바이트).
  ///
  /// 256비트 = 32바이트 (AES-256 키 길이와 동일).
  static const int keyLength = 32;

  /// Salt 길이 (바이트).
  ///
  /// NIST SP 800-132 권장: 최소 16바이트, 권장 32바이트.
  static const int saltLength = 32;

  /// PIN/패스워드로부터 암호화 키를 파생합니다.
  ///
  /// **매개변수:**
  /// - [pin]: 사용자 PIN 또는 패스워드
  /// - [salt]: 랜덤 Salt (Base64 인코딩)
  /// - [iterations]: PBKDF2 반복 횟수 (기본값: 100,000)
  ///
  /// **반환값:**
  /// - Base64 인코딩된 파생 키 (32바이트)
  ///
  /// **예외:**
  /// - [CryptographyFailure]: 키 파생 실패 시
  ///
  /// **주의사항:**
  /// - 동일한 PIN + Salt 조합은 항상 동일한 키를 생성합니다
  /// - Salt는 반드시 안전하게 저장되어야 합니다
  /// - PIN이 짧을수록 브루트포스 공격에 취약합니다
  String deriveKey({
    required String pin,
    required String salt,
    int? iterations,
  }) {
    try {
      // Base64 Salt를 바이트로 변환
      final saltBytes = base64.decode(salt);

      // PBKDF2 파라미터 설정
      final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
      derivator.init(
        Pbkdf2Parameters(
          saltBytes,
          iterations ?? kdfIterations,
          keyLength,
        ),
      );

      // PIN을 UTF-8 바이트로 변환
      final pinBytes = Uint8List.fromList(utf8.encode(pin));

      // 키 파생
      final derivedKey = derivator.process(pinBytes);

      // Base64 인코딩하여 반환
      return base64.encode(derivedKey);
    } catch (e) {
      throw CryptographyFailure('Failed to derive key', cause: e);
    }
  }

  /// 암호학적으로 안전한 랜덤 Salt를 생성합니다.
  ///
  /// **반환값:**
  /// - Base64 인코딩된 랜덤 Salt (32바이트)
  ///
  /// **예외:**
  /// - [CryptographyFailure]: Salt 생성 실패 시
  ///
  /// **주의사항:**
  /// - 생성된 Salt는 반드시 안전한 저장소에 보관해야 합니다
  /// - 니모닉마다 고유한 Salt를 사용해야 합니다
  String generateSalt() {
    try {
      final random = FortunaRandom();

      // 시드 초기화 (Cryptographically Secure)
      final seedSource = Random.secure();
      final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
      random.seed(KeyParameter(Uint8List.fromList(seeds)));

      // 랜덤 바이트 생성
      final salt = random.nextBytes(saltLength);

      return base64.encode(salt);
    } catch (e) {
      throw CryptographyFailure('Failed to generate salt', cause: e);
    }
  }

  /// Salt의 유효성을 검증합니다.
  ///
  /// **매개변수:**
  /// - [salt]: 검증할 Salt (Base64 인코딩)
  ///
  /// **반환값:**
  /// - 유효한 Salt이면 `true`, 그렇지 않으면 `false`
  ///
  /// **검증 조건:**
  /// - Base64 디코딩 가능
  /// - 정확히 32바이트
  bool validateSalt(String salt) {
    try {
      final saltBytes = base64.decode(salt);
      return saltBytes.length == saltLength;
    } catch (e) {
      return false;
    }
  }
}
