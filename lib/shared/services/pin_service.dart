import '../../core/constants/storage_keys.dart';
import 'secure_storage_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

/// Simple PIN storage/verification helper.
class PinService {
  PinService(this._storage);

  final SecureStorageService _storage;

  Future<String> _getOrCreateSalt() async {
    final existing = await _storage.read(StorageKeys.pinSalt);
    if (existing != null) return existing;
    final salt = _generateSalt();
    await _storage.write(
      key: StorageKeys.pinSalt,
      value: salt,
      isSensitive: true,
    );
    return salt;
  }

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Encode(bytes);
  }

  Future<String> _hashPin(String pin) async {
    final salt = await _getOrCreateSalt();
    final bytes = utf8.encode('$salt|$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> savePin(String pin) {
    return _hashPin(pin).then(
      (hashed) => _storage.write(key: StorageKeys.pin, value: hashed),
    );
  }

  Future<bool> hasPin() async {
    final existing = await _storage.read(StorageKeys.pin);
    return existing != null && existing.isNotEmpty;
  }

  Future<bool> verifyPin(String pin) async {
    final existing = await _storage.read(StorageKeys.pin);
    if (existing == null) return false;
    final hashed = await _hashPin(pin);
    return existing == hashed;
  }

  Future<void> clearPin() {
    return _storage.delete(StorageKeys.pin);
  }
}
