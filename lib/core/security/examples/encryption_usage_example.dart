// ignore_for_file: unused_local_variable, avoid_print

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../security/services/encrypted_storage_service.dart';
import '../../security/services/encryption_service.dart';
import '../../security/services/key_derivation_service.dart';
import '../../../shared/services/secure_storage_service.dart';

/// EncryptedStorageService 사용 예제.
///
/// **주의:** 이 파일은 예제 코드이며 실제 앱에서는 사용되지 않습니다.
///
/// 실제 구현은 다음 파일들을 참조하세요:
/// - `lib/features/wallet/data/datasources/wallet_local_datasource.dart`
/// - `lib/features/wallet/data/repositories/wallet_repository_impl.dart`
class EncryptionUsageExample {
  /// 서비스 초기화 예제.
  ///
  /// 실제 앱에서는 Riverpod Provider로 의존성을 주입합니다.
  static Future<void> setupExample() async {
    // 1. FlutterSecureStorage 초기화
    const secureStorage = FlutterSecureStorage();
    final secureStorageService = SecureStorageService(secureStorage);

    // 2. 암호화 서비스 초기화
    final encryptionService = EncryptionService();
    final keyDerivationService = KeyDerivationService();

    // 3. EncryptedStorageService 초기화
    final encryptedStorage = EncryptedStorageService(
      secureStorage: secureStorageService,
      encryptionService: encryptionService,
      keyDerivationService: keyDerivationService,
    );

    // 이제 encryptedStorage를 사용하여 니모닉 저장/조회 가능
  }

  /// 기본 사용 예제: 니모닉 저장 및 조회.
  static Future<void> basicUsageExample(
    EncryptedStorageService storage,
  ) async {
    // 1. 사용자로부터 PIN 입력 받기
    const userPin = '123456'; // 실제로는 UI에서 입력받음

    // 2. 니모닉 생성 (BIP-39)
    const mnemonic = 'word1 word2 word3 word4 word5 word6 '
        'word7 word8 word9 word10 word11 word12';

    // 3. 니모닉 암호화하여 저장
    await storage.saveMnemonic(
      mnemonic: mnemonic,
      pin: userPin,
    );
    print('✅ 니모닉 저장 완료 (암호화됨)');

    // 4. 니모닉 조회 (PIN 필요)
    final retrievedMnemonic = await storage.getMnemonic(pin: userPin);
    print('✅ 니모닉 조회 완료: $retrievedMnemonic');

    // 5. 니모닉 삭제
    await storage.deleteMnemonic();
    print('✅ 니모닉 삭제 완료');
  }

  /// 평문 니모닉 마이그레이션 예제.
  ///
  /// 앱 업데이트 시 기존 평문 니모닉을 암호화하는 시나리오입니다.
  static Future<void> migrationExample(
    EncryptedStorageService storage,
  ) async {
    // 1. 평문 니모닉 확인
    final isPlaintext = await storage.isPlaintextMnemonic();

    if (isPlaintext) {
      print('⚠️ 평문 니모닉 감지! 마이그레이션이 필요합니다.');

      // 2. 사용자에게 PIN 설정 요청
      // (실제로는 UI 다이얼로그를 통해 입력받음)
      const newPin = '123456';

      // 3. 평문 → 암호문 마이그레이션
      await storage.migratePlaintextMnemonic(pin: newPin);
      print('✅ 마이그레이션 완료! 이제 PIN이 필요합니다.');
    } else {
      print('✅ 이미 암호화된 니모닉입니다.');
    }
  }

  /// 에러 핸들링 예제.
  static Future<void> errorHandlingExample(
    EncryptedStorageService storage,
  ) async {
    const correctPin = '123456';
    const wrongPin = '654321';

    // 1. 니모닉 저장
    await storage.saveMnemonic(
      mnemonic: 'test mnemonic phrase',
      pin: correctPin,
    );

    // 2. 올바른 PIN으로 조회
    try {
      final mnemonic = await storage.getMnemonic(pin: correctPin);
      print('✅ 복호화 성공: $mnemonic');
    } catch (e) {
      print('❌ 오류 발생: $e');
    }

    // 3. 잘못된 PIN으로 조회 시도
    try {
      final mnemonic = await storage.getMnemonic(pin: wrongPin);
      print('⚠️ 이 코드는 실행되지 않아야 합니다!');
    } on Exception catch (e) {
      // CryptographyFailure 발생
      print('❌ 예상된 오류: 잘못된 PIN ($e)');
    }
  }

  /// 고급 사용 예제: 직접 암호화/복호화.
  ///
  /// 니모닉 외에 다른 민감 데이터를 암호화해야 하는 경우.
  static Future<void> advancedUsageExample() async {
    // 1. 서비스 초기화
    final keyDerivation = KeyDerivationService();
    final encryption = EncryptionService();

    // 2. Salt 생성
    final salt = keyDerivation.generateSalt();
    print('Salt: $salt');

    // 3. 사용자 PIN으로부터 키 파생
    const userPin = '123456';
    final derivedKey = keyDerivation.deriveKey(
      pin: userPin,
      salt: salt,
    );
    print('파생 키: $derivedKey');

    // 4. 데이터 암호화
    const sensitiveData = '프라이빗 키 또는 기타 민감 데이터';
    final encrypted = encryption.encrypt(
      plaintext: sensitiveData,
      key: derivedKey,
    );
    print('암호화된 데이터: $encrypted');

    // 5. 데이터 복호화
    final decrypted = encryption.decrypt(
      ciphertext: encrypted,
      key: derivedKey,
    );
    print('복호화된 데이터: $decrypted');

    // 6. 검증
    assert(decrypted == sensitiveData);
    print('✅ 암호화/복호화 성공!');
  }

  /// 보안 모범 사례 예제.
  static Future<void> securityBestPracticesExample(
    EncryptedStorageService storage,
  ) async {
    // ✅ 권장: 강력한 PIN 사용 (6자리 이상)
    const strongPin = '123456';

    // ❌ 비권장: 약한 PIN
    // const weakPin = '1234';  // 너무 짧음
    // const weakPin = '000000'; // 반복 패턴

    // ✅ 권장: 니모닉 저장 전 검증
    const mnemonic = 'word1 word2 word3 word4 word5 word6 '
        'word7 word8 word9 word10 word11 word12';

    // BIP-39 검증 (실제 구현 참조)
    // final isValid = bip39.validateMnemonic(mnemonic);
    // if (!isValid) throw ValidationFailure('Invalid mnemonic');

    // ✅ 권장: PIN 변경 시 재암호화
    await storage.saveMnemonic(mnemonic: mnemonic, pin: strongPin);

    const newPin = '654321';
    final retrievedMnemonic = await storage.getMnemonic(pin: strongPin);
    await storage.saveMnemonic(mnemonic: retrievedMnemonic!, pin: newPin);
    print('✅ PIN 변경 완료');

    // ✅ 권장: 민감 데이터 사용 후 즉시 삭제
    String? tempMnemonic = await storage.getMnemonic(pin: newPin);
    // ... 니모닉 사용 ...
    tempMnemonic = null; // GC가 메모리에서 제거하도록 유도

    // ✅ 권장: 앱 종료 시 인증 세션 클리어
    // (실제 구현은 AuthSessionService 참조)
    // await authSessionService.clearSession();
  }

  /// Riverpod Provider 통합 예제.
  ///
  /// 실제 앱에서 사용하는 의존성 주입 패턴입니다.
  static String riverpodProviderExample() {
    return '''
// lib/shared/providers/encryption_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/secure_storage_service.dart';
import '../../core/security/services/encryption_service.dart';
import '../../core/security/services/key_derivation_service.dart';
import '../../core/security/services/encrypted_storage_service.dart';

/// FlutterSecureStorage Provider.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// SecureStorageService Provider.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SecureStorageService(storage);
});

/// EncryptionService Provider.
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// KeyDerivationService Provider.
final keyDerivationServiceProvider = Provider<KeyDerivationService>((ref) {
  return KeyDerivationService();
});

/// EncryptedStorageService Provider.
final encryptedStorageServiceProvider = Provider<EncryptedStorageService>((ref) {
  return EncryptedStorageService(
    secureStorage: ref.watch(secureStorageServiceProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
    keyDerivationService: ref.watch(keyDerivationServiceProvider),
  );
});

// 사용 예시:
// class MyWidget extends ConsumerWidget {
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final storage = ref.watch(encryptedStorageServiceProvider);
//     // ... storage 사용 ...
//   }
// }
    ''';
  }

  /// WalletLocalDataSource 통합 예제.
  ///
  /// 실제 Repository Layer에서 사용하는 패턴입니다.
  static String repositoryIntegrationExample() {
    return '''
// lib/features/wallet/data/datasources/wallet_local_datasource.dart

class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  WalletLocalDataSourceImpl(
    this._encryptedStorage,
    this._authSessionService,
  );

  final EncryptedStorageService _encryptedStorage;
  final AuthSessionService _authSessionService;

  @override
  Future<void> saveMnemonic(String mnemonic, {required String pin}) async {
    try {
      // PIN 기반 암호화 저장
      await _encryptedStorage.saveMnemonic(
        mnemonic: mnemonic,
        pin: pin,
      );
    } catch (e) {
      throw StorageFailure('Failed to save encrypted mnemonic', cause: e);
    }
  }

  @override
  Future<String?> getMnemonic({required String pin}) async {
    try {
      // 인증 확인
      await _authSessionService.ensureAuthenticated(
        reason: '지갑 정보를 불러오려면 인증이 필요합니다.',
      );

      // PIN 기반 복호화 조회
      return await _encryptedStorage.getMnemonic(pin: pin);
    } catch (e) {
      if (e is Failure) rethrow;
      throw StorageFailure('Failed to retrieve encrypted mnemonic', cause: e);
    }
  }

  @override
  Future<void> deleteMnemonic() async {
    try {
      await _encryptedStorage.deleteMnemonic();
    } catch (e) {
      throw StorageFailure('Failed to delete mnemonic', cause: e);
    }
  }
}
    ''';
  }
}

/// 메인 함수: 모든 예제 실행.
void main() async {
  print('=== 암호화 시스템 사용 예제 ===\n');

  // 서비스 초기화
  await EncryptionUsageExample.setupExample();

  // 예제 코드는 실제 앱에서는 사용되지 않으므로
  // 여기서는 문서화 목적으로만 제공됩니다.

  print('\n✅ 모든 예제 코드를 확인하려면 이 파일을 읽어보세요.');
  print('📂 lib/core/security/examples/encryption_usage_example.dart');
}
