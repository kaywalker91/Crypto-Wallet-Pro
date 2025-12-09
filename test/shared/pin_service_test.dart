import 'package:crypto_wallet_pro/shared/services/pin_service.dart';
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

void main() {
  test('PIN 저장/검증 시 해싱+salt 적용', () async {
    final storage = InMemorySecureStorage();
    final service = PinService(storage);

    await service.savePin('1234');
    final rawStored = await storage.read('wallet_pin');

    expect(rawStored, isNot('1234')); // 해시로 저장됨
    expect(await service.verifyPin('1234'), isTrue);
    expect(await service.verifyPin('9999'), isFalse);
  });
}
