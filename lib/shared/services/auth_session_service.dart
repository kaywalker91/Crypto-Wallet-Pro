import 'package:crypto_wallet_pro/core/constants/storage_keys.dart';

import 'biometric_service.dart';
import 'secure_storage_service.dart';

/// Manages short-lived authentication sessions to avoid repeated biometric prompts.
class AuthSessionService {
  AuthSessionService(
    this._storage,
    this._biometricService, {
    Duration sessionDuration = const Duration(minutes: 3),
    this.authEnabled = true,
  }) : _sessionDuration = sessionDuration;

  final SecureStorageService _storage;
  final BiometricService _biometricService;
  final Duration _sessionDuration;
  final bool authEnabled;

  DateTime? _memoryValidUntil;

  bool _isStillValid(DateTime? target) {
    if (target == null) return false;
    return DateTime.now().isBefore(target);
  }

  Future<DateTime?> _readPersistedSession() async {
    if (!authEnabled) return null;
    final raw = await _storage.read(StorageKeys.authSessionValidUntil);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> hasValidSession() async {
    if (!authEnabled) return true;
    if (_isStillValid(_memoryValidUntil) || _biometricService.hasValidSession) {
      return true;
    }
    final persisted = await _readPersistedSession();
    if (_isStillValid(persisted)) {
      _memoryValidUntil = persisted;
      _biometricService.extendSession(persisted!);
      return true;
    }
    return false;
  }

  Future<void> _persistSession(DateTime until) async {
    if (!authEnabled) return;
    _memoryValidUntil = until;
    _biometricService.extendSession(until);
    await _storage.write(
      key: StorageKeys.authSessionValidUntil,
      value: until.toIso8601String(),
      isSensitive: false,
    );
  }

  Future<bool> ensureAuthenticated({
    String reason = '지갑 접근을 위해 인증이 필요합니다.',
  }) async {
    if (!authEnabled) return true;
    if (await hasValidSession()) return true;

    final success = await _biometricService.authenticate(reason: reason);
    if (success) {
      await markSessionValid();
    }
    return success;
  }

  Future<void> markSessionValid() async {
    final until = DateTime.now().add(_sessionDuration);
    await _persistSession(until);
  }

  Future<void> clearSession() async {
    _memoryValidUntil = null;
    if (authEnabled) {
      await _storage.delete(StorageKeys.authSessionValidUntil);
    }
  }
}
