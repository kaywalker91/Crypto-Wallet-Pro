import 'package:crypto_wallet_pro/core/constants/storage_keys.dart';
import 'package:crypto_wallet_pro/shared/services/auth_session_service.dart';
import 'package:crypto_wallet_pro/shared/services/biometric_service.dart';
import 'package:crypto_wallet_pro/shared/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    bool isSensitive = true,
  }) async {
    _store[key] = value;
  }
}

class FakeBiometricService implements BiometricService {
  FakeBiometricService({
    this.canCheckResult = true,
    this.authResult = true,
  });

  final bool canCheckResult;
  final bool authResult;
  int authenticateCalls = 0;
  int extendCalls = 0;
  DateTime? extendedUntil;
  bool hasValidSessionFlag = false;

  @override
  bool get hasValidSession => hasValidSessionFlag;

  @override
  Future<bool> authenticate({String reason = 'Authenticate to access your wallet'}) async {
    authenticateCalls += 1;
    hasValidSessionFlag = authResult;
    return authResult;
  }

  @override
  Future<bool> canCheck() async => canCheckResult;

  @override
  void extendSession(DateTime validUntil) {
    extendCalls += 1;
    extendedUntil = validUntil;
    hasValidSessionFlag = true;
  }

  @override
  Future<bool> ensureAuthenticated({String reason = 'Authenticate to access your wallet'}) {
    return authenticate(reason: reason);
  }
}

void main() {
  test('ensureAuthenticated skips biometric when session is already valid', () async {
    final storage = InMemorySecureStorage();
    final biometric = FakeBiometricService();
    final service = AuthSessionService(
      storage,
      biometric,
      sessionDuration: const Duration(minutes: 5),
      authEnabled: true,
    );

    await service.markSessionValid();
    final authed = await service.ensureAuthenticated();

    expect(authed, isTrue);
    expect(biometric.authenticateCalls, 0);
    expect(await storage.read(StorageKeys.authSessionValidUntil), isNotNull);
  });

  test('persisted session restores on next launch without prompting biometrics', () async {
    final storage = InMemorySecureStorage();
    final firstBiometric = FakeBiometricService();
    final first = AuthSessionService(
      storage,
      firstBiometric,
      sessionDuration: const Duration(minutes: 5),
      authEnabled: true,
    );
    await first.markSessionValid();

    final secondBiometric = FakeBiometricService();
    final second = AuthSessionService(
      storage,
      secondBiometric,
      sessionDuration: const Duration(minutes: 5),
      authEnabled: true,
    );

    final hasSession = await second.hasValidSession();

    expect(hasSession, isTrue);
    expect(secondBiometric.authenticateCalls, 0);
    expect(secondBiometric.extendCalls, 1);
    expect(secondBiometric.extendedUntil, isNotNull);
  });

  test('ensureAuthenticated returns false when biometric fails', () async {
    final storage = InMemorySecureStorage();
    final biometric = FakeBiometricService(authResult: false);
    final service = AuthSessionService(storage, biometric, authEnabled: true);

    final authed = await service.ensureAuthenticated();

    expect(authed, isFalse);
    expect(biometric.authenticateCalls, 1);
    expect(await storage.read(StorageKeys.authSessionValidUntil), isNull);
  });

  test('auth disabled short-circuits without biometric prompt', () async {
    final storage = InMemorySecureStorage();
    final biometric = FakeBiometricService();
    final service = AuthSessionService(
      storage,
      biometric,
      authEnabled: false,
    );

    final authed = await service.ensureAuthenticated();

    expect(authed, isTrue);
    expect(biometric.authenticateCalls, 0);
  });
}
