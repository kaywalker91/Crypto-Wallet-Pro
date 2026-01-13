import 'package:crypto_wallet_pro/shared/services/secure_storage_service.dart';

/// Mock implementation of SecureStorageService for testing.
///
/// Uses in-memory Map to store data instead of platform secure storage.
class MockSecureStorageService implements SecureStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String value,
    bool isSensitive = true,
  }) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map.from(_storage);
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  /// Clear all stored data (for test cleanup).
  void clear() {
    _storage.clear();
  }
}
