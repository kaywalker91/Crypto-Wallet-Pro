/// Base failure for domain/data errors.
class Failure {
  final String message;
  final Object? cause;

  const Failure(this.message, {this.cause});
}

/// Failure representing validation issues (e.g., invalid mnemonic).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// Failure representing secure storage issues.
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

/// Failure representing network or blockchain API issues.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.cause});
}

/// Failure representing authentication issues.
///
/// 인증 실패 시 반환됩니다 (생체 인증, PIN 인증 등).
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.cause});
}

/// Failure representing cryptographic operations (encryption, decryption, key derivation).
///
/// 암호화/복호화 실패 시 반환됩니다.
class CryptographyFailure extends Failure {
  const CryptographyFailure(super.message, {super.cause});
}

