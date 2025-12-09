import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    as fss;

/// Wrapper around [FlutterSecureStorage] to simplify usage and testing.
class SecureStorageService {
  SecureStorageService(this._storage);

  final fss.FlutterSecureStorage _storage;

  Future<void> write({
    required String key,
    required String value,
    bool isSensitive = true,
  }) {
    return _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions(isSensitive: isSensitive),
      iOptions: _iosOptions(isSensitive: isSensitive),
    );
  }

  Future<String?> read(String key) {
    return _storage.read(
      key: key,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<void> delete(String key) {
    return _storage.delete(
      key: key,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  fss.AndroidOptions _androidOptions({bool isSensitive = true}) {
    return fss.AndroidOptions(
      encryptedSharedPreferences: isSensitive,
    );
  }

  fss.IOSOptions _iosOptions({bool isSensitive = true}) {
    return fss.IOSOptions(
      accessibility: isSensitive
          ? fss.KeychainAccessibility.first_unlock
          : fss.KeychainAccessibility.unlocked,
    );
  }
}
