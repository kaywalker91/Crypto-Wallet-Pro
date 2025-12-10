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
