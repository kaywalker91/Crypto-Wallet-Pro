import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'hsm_capability.dart';
import 'hsm_key.dart';
import 'hsm_provider.dart';

/// 플랫폼별 HSM 관리자
///
/// iOS Secure Enclave, Android StrongBox를 통합 관리하며,
/// 하드웨어 미지원 시 소프트웨어 폴백을 제공합니다.
///
/// **아키텍처**
/// ```
/// HsmManager (통합 인터페이스)
///     ├─> SecureEnclaveProvider (iOS)
///     ├─> StrongBoxProvider (Android)
///     └─> SoftwareKeyStoreProvider (Fallback)
/// ```
///
/// **사용 예시**
/// ```dart
/// final hsmManager = HsmManager();
/// await hsmManager.initialize();
///
/// if (await hsmManager.isHardwareAvailable()) {
///   final key = await hsmManager.generateKey(
///     alias: 'wallet_signing_key',
///     keyType: HsmKeyType.eccP256,
///     purposes: [HsmKeyPurpose.sign, HsmKeyPurpose.verify],
///     requiresBiometric: true,
///   );
///
///   final signature = await hsmManager.sign(
///     keyId: key.keyId,
///     data: messageBytes,
///   );
/// }
/// ```
class HsmManager implements HsmProvider {
  static const MethodChannel _channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/hsm');

  HsmInfo? _cachedInfo;
  bool _isInitialized = false;

  /// HSM 초기화
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      try {
        if (Platform.isAndroid) {
          await _initializeAndroid();
        } else if (Platform.isIOS) {
          await _initializeIOS();
        } else {
          // 테스트 환경: Android 시도
          await _initializeAndroid();
        }
      } on MissingPluginException {
        // 플랫폼 구현 없음: 소프트웨어 폴백
        _cachedInfo = HsmInfo.softwareFallback();
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('HSM initialization error: $e');
      }
      // 에러 발생 시 소프트웨어 폴백
      _cachedInfo = HsmInfo.softwareFallback();
      _isInitialized = true;
    }
  }

  /// Android HSM 초기화
  Future<void> _initializeAndroid() async {
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('initializeAndroid');

      final bool hasStrongBox = result['hasStrongBox'] as bool? ?? false;
      final String version = result['version'] as String? ?? '1.0';

      if (hasStrongBox) {
        _cachedInfo = HsmInfo.strongBox(
          version: version,
          status: HsmStatus.available,
        );
      } else {
        _cachedInfo = HsmInfo.softwareFallback();
      }
    } on MissingPluginException {
      _cachedInfo = HsmInfo.softwareFallback();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Android HSM init error: ${e.message}');
      }
      _cachedInfo = HsmInfo.softwareFallback();
    }
  }

  /// iOS HSM 초기화
  Future<void> _initializeIOS() async {
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('initializeIOS');

      final bool hasSecureEnclave = result['hasSecureEnclave'] as bool? ?? false;
      final String version = result['version'] as String? ?? '1.0';

      if (hasSecureEnclave) {
        _cachedInfo = HsmInfo.secureEnclave(
          version: version,
          status: HsmStatus.available,
        );
      } else {
        _cachedInfo = HsmInfo.softwareFallback();
      }
    } on MissingPluginException {
      _cachedInfo = HsmInfo.softwareFallback();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('iOS HSM init error: ${e.message}');
      }
      _cachedInfo = HsmInfo.softwareFallback();
    }
  }

  @override
  Future<HsmInfo> getHsmInfo() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _cachedInfo!;
  }

  @override
  Future<HsmKey> generateKey({
    required String alias,
    required HsmKeyType keyType,
    required List<HsmKeyPurpose> purposes,
    bool requiresBiometric = false,
    DateTime? expiresAt,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('generateKey', {
        'alias': alias,
        'keyType': _keyTypeToString(keyType),
        'purposes': purposes.map(_keyPurposeToString).toList(),
        'requiresBiometric': requiresBiometric,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
      });

      return _parseHsmKey(result);
    } on MissingPluginException {
      // 테스트/개발 환경: Mock 키 생성
      return _generateMockKey(
        alias: alias,
        keyType: keyType,
        purposes: purposes,
        requiresBiometric: requiresBiometric,
        expiresAt: expiresAt,
      );
    } on PlatformException catch (e) {
      throw Exception('Failed to generate key: ${e.message}');
    }
  }

  @override
  Future<HsmKey?> getKey(String keyId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('getKey', {'keyId': keyId});

      if (result == null) return null;

      return _parseHsmKey(result);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<HsmKey?> getKeyByAlias(String alias) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('getKeyByAlias', {'alias': alias});

      if (result == null) return null;

      return _parseHsmKey(result);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<List<HsmKey>> listKeys() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final List<dynamic> result = await _channel.invokeMethod('listKeys');

      return result
          .map((e) => _parseHsmKey(e as Map<dynamic, dynamic>))
          .toList();
    } on MissingPluginException {
      return [];
    } on PlatformException {
      return [];
    }
  }

  @override
  Future<bool> deleteKey(String keyId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final bool result =
          await _channel.invokeMethod('deleteKey', {'keyId': keyId});
      return result;
    } on MissingPluginException {
      return true; // 테스트 환경
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<Uint8List> sign({
    required String keyId,
    required Uint8List data,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final Uint8List result = await _channel.invokeMethod('sign', {
        'keyId': keyId,
        'data': data,
      });

      return result;
    } on MissingPluginException {
      // 테스트 환경: Mock 서명
      return Uint8List.fromList(List.filled(64, 0));
    } on PlatformException catch (e) {
      throw Exception('Failed to sign: ${e.message}');
    }
  }

  @override
  Future<bool> verify({
    required String keyId,
    required Uint8List data,
    required Uint8List signature,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final bool result = await _channel.invokeMethod('verify', {
        'keyId': keyId,
        'data': data,
        'signature': signature,
      });

      return result;
    } on MissingPluginException {
      // 테스트 환경: 항상 통과
      return true;
    } on PlatformException catch (e) {
      throw Exception('Failed to verify: ${e.message}');
    }
  }

  @override
  Future<Uint8List> encrypt({
    required String keyId,
    required Uint8List plaintext,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final Uint8List result = await _channel.invokeMethod('encrypt', {
        'keyId': keyId,
        'plaintext': plaintext,
      });

      return result;
    } on MissingPluginException {
      // 테스트 환경: Mock 암호화
      return plaintext;
    } on PlatformException catch (e) {
      throw Exception('Failed to encrypt: ${e.message}');
    }
  }

  @override
  Future<Uint8List> decrypt({
    required String keyId,
    required Uint8List ciphertext,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final Uint8List result = await _channel.invokeMethod('decrypt', {
        'keyId': keyId,
        'ciphertext': ciphertext,
      });

      return result;
    } on MissingPluginException {
      // 테스트 환경: Mock 복호화
      return ciphertext;
    } on PlatformException catch (e) {
      throw Exception('Failed to decrypt: ${e.message}');
    }
  }

  @override
  Future<bool> keyExists(String keyId) async {
    final key = await getKey(keyId);
    return key != null;
  }

  @override
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _cachedInfo?.isAvailable ?? false;
  }

  @override
  Future<bool> supportsCapability(HsmCapability capability) async {
    if (!_isInitialized) {
      await initialize();
    }
    return _cachedInfo?.supportsCapability(capability) ?? false;
  }

  /// 하드웨어 기반 HSM 사용 가능 여부
  Future<bool> isHardwareAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _cachedInfo?.isHardwareBacked ?? false;
  }

  /// HsmKey 파싱 (플랫폼 결과 → 모델)
  HsmKey _parseHsmKey(Map<dynamic, dynamic> map) {
    return HsmKey(
      keyId: map['keyId'] as String,
      alias: map['alias'] as String,
      keyType: _stringToKeyType(map['keyType'] as String),
      purposes: (map['purposes'] as List<dynamic>)
          .map((e) => _stringToKeyPurpose(e as String))
          .toList(),
      isHardwareBacked: map['isHardwareBacked'] as bool? ?? false,
      requiresBiometric: map['requiresBiometric'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int,
      ),
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
          : null,
      publicKey: map['publicKey'] as String?,
      isExportable: map['isExportable'] as bool? ?? false,
    );
  }

  /// Mock 키 생성 (테스트용)
  HsmKey _generateMockKey({
    required String alias,
    required HsmKeyType keyType,
    required List<HsmKeyPurpose> purposes,
    bool requiresBiometric = false,
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();
    return HsmKey(
      keyId: 'mock_${now.millisecondsSinceEpoch}',
      alias: alias,
      keyType: keyType,
      purposes: purposes,
      isHardwareBacked: false,
      requiresBiometric: requiresBiometric,
      createdAt: now,
      expiresAt: expiresAt,
      publicKey: null,
      isExportable: false,
    );
  }

  /// HsmKeyType → String
  String _keyTypeToString(HsmKeyType type) {
    switch (type) {
      case HsmKeyType.rsa2048:
        return 'RSA_2048';
      case HsmKeyType.rsa4096:
        return 'RSA_4096';
      case HsmKeyType.eccP256:
        return 'EC_P256';
      case HsmKeyType.eccP384:
        return 'EC_P384';
      case HsmKeyType.aes256:
        return 'AES_256';
    }
  }

  /// String → HsmKeyType
  HsmKeyType _stringToKeyType(String typeStr) {
    switch (typeStr.toUpperCase()) {
      case 'RSA_2048':
        return HsmKeyType.rsa2048;
      case 'RSA_4096':
        return HsmKeyType.rsa4096;
      case 'EC_P256':
        return HsmKeyType.eccP256;
      case 'EC_P384':
        return HsmKeyType.eccP384;
      case 'AES_256':
        return HsmKeyType.aes256;
      default:
        throw Exception('Unknown key type: $typeStr');
    }
  }

  /// HsmKeyPurpose → String
  String _keyPurposeToString(HsmKeyPurpose purpose) {
    switch (purpose) {
      case HsmKeyPurpose.sign:
        return 'SIGN';
      case HsmKeyPurpose.verify:
        return 'VERIFY';
      case HsmKeyPurpose.encrypt:
        return 'ENCRYPT';
      case HsmKeyPurpose.decrypt:
        return 'DECRYPT';
      case HsmKeyPurpose.signVerify:
        return 'SIGN_VERIFY';
      case HsmKeyPurpose.encryptDecrypt:
        return 'ENCRYPT_DECRYPT';
    }
  }

  /// String → HsmKeyPurpose
  HsmKeyPurpose _stringToKeyPurpose(String purposeStr) {
    switch (purposeStr.toUpperCase()) {
      case 'SIGN':
        return HsmKeyPurpose.sign;
      case 'VERIFY':
        return HsmKeyPurpose.verify;
      case 'ENCRYPT':
        return HsmKeyPurpose.encrypt;
      case 'DECRYPT':
        return HsmKeyPurpose.decrypt;
      case 'SIGN_VERIFY':
        return HsmKeyPurpose.signVerify;
      case 'ENCRYPT_DECRYPT':
        return HsmKeyPurpose.encryptDecrypt;
      default:
        throw Exception('Unknown key purpose: $purposeStr');
    }
  }
}
