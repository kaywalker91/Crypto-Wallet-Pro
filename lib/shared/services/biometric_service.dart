import 'package:local_auth/local_auth.dart';

/// Handles biometric authentication prompts.
class BiometricService {
  BiometricService(
    this._localAuth, {
    Duration sessionDuration = const Duration(minutes: 3),
  }) : _sessionDuration = sessionDuration;

  final LocalAuthentication _localAuth;
  final Duration _sessionDuration;
  DateTime? _authSessionValidUntil;

  bool get hasValidSession =>
      _authSessionValidUntil != null &&
      DateTime.now().isBefore(_authSessionValidUntil!);

  Future<bool> canCheck() async {
    final isSupported = await _localAuth.isDeviceSupported();
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    return isSupported && canCheckBiometrics;
  }

  void extendSession(DateTime validUntil) {
    _authSessionValidUntil = validUntil;
  }

  Future<bool> authenticate({String reason = 'Authenticate to access your wallet'}) async {
    final canCheckBiometrics = await canCheck();
    if (!canCheckBiometrics) return false;

    final success = await _localAuth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    if (success) {
      _authSessionValidUntil = DateTime.now().add(_sessionDuration);
    }

    return success;
  }

  Future<bool> ensureAuthenticated({String reason = 'Authenticate to access your wallet'}) async {
    if (hasValidSession) return true;
    return authenticate(reason: reason);
  }
}
