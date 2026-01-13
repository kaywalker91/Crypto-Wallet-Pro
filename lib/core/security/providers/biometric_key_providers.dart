import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../shared/providers/storage_providers.dart';
import '../services/biometric_key_service.dart';
import '../services/encryption_service.dart';
import '../services/enhanced_biometric_service.dart';
import '../services/key_derivation_service.dart';

/// EnhancedBiometricService 인스턴스를 제공하는 Provider.
///
/// **의존성:**
/// - `LocalAuthentication` (local_auth 패키지)
///
/// **라이프사이클:**
/// - 싱글톤 (앱 전체에서 동일한 인스턴스 사용)
final enhancedBiometricServiceProvider = Provider<EnhancedBiometricService>(
  (ref) => EnhancedBiometricService(
    LocalAuthentication(),
    sessionDuration: const Duration(minutes: 3),
  ),
);

/// EncryptionService 인스턴스를 제공하는 Provider.
///
/// **의존성:**
/// - 없음 (상태 없는 서비스)
///
/// **라이프사이클:**
/// - 싱글톤
final encryptionServiceProvider = Provider<EncryptionService>(
  (ref) => EncryptionService(),
);

/// KeyDerivationService 인스턴스를 제공하는 Provider.
///
/// **의존성:**
/// - 없음 (상태 없는 서비스)
///
/// **라이프사이클:**
/// - 싱글톤
final keyDerivationServiceProvider = Provider<KeyDerivationService>(
  (ref) => KeyDerivationService(),
);

/// BiometricKeyService 인스턴스를 제공하는 Provider.
///
/// **의존성:**
/// - `SecureStorageService`
/// - `EnhancedBiometricService`
/// - `EncryptionService`
/// - `KeyDerivationService`
///
/// **라이프사이클:**
/// - 싱글톤
///
/// **사용 예시:**
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final biometricKeyService = ref.read(biometricKeyServiceProvider);
///
///     return ElevatedButton(
///       onPressed: () async {
///         // 생체인증 키 생성
///         await biometricKeyService.generateAndSaveBiometricKey(
///           pin: '123456',
///         );
///
///         // 생체인증으로 키 조회
///         final key = await biometricKeyService.getBiometricKey();
///       },
///       child: Text('생체인증 설정'),
///     );
///   }
/// }
/// ```
final biometricKeyServiceProvider = Provider<BiometricKeyService>(
  (ref) => BiometricKeyService(
    secureStorage: ref.watch(secureStorageServiceProvider),
    biometricService: ref.watch(enhancedBiometricServiceProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
    keyDerivationService: ref.watch(keyDerivationServiceProvider),
  ),
);

/// 생체인증 가능 여부를 제공하는 FutureProvider.
///
/// **반환값:**
/// - `true`: 하드웨어 지원 + 생체정보 등록됨
/// - `false`: 지원 안 함 또는 생체정보 미등록
///
/// **사용 예시:**
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final canUseBiometrics = ref.watch(canUseBiometricsProvider);
///
///     return canUseBiometrics.when(
///       data: (canUse) => Text(canUse ? '생체인증 사용 가능' : '사용 불가'),
///       loading: () => CircularProgressIndicator(),
///       error: (err, stack) => Text('오류: $err'),
///     );
///   }
/// }
/// ```
final canUseBiometricsProvider = FutureProvider<bool>((ref) async {
  final biometricService = ref.watch(enhancedBiometricServiceProvider);
  return biometricService.canCheck();
});

/// 사용 가능한 생체인증 유형을 제공하는 FutureProvider.
///
/// **반환값:**
/// - 생체인증 유형 리스트 (Face ID, Touch ID, 지문 등)
///
/// **사용 예시:**
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final biometricTypes = ref.watch(availableBiometricsProvider);
///
///     return biometricTypes.when(
///       data: (types) {
///         if (types.contains(BiometricType.face)) {
///           return Icon(Icons.face);
///         } else if (types.contains(BiometricType.fingerprint)) {
///           return Icon(Icons.fingerprint);
///         }
///         return Icon(Icons.lock);
///       },
///       loading: () => CircularProgressIndicator(),
///       error: (err, stack) => Icon(Icons.error),
///     );
///   }
/// }
/// ```
final availableBiometricsProvider = FutureProvider<List<BiometricType>>((ref) async {
  final biometricService = ref.watch(enhancedBiometricServiceProvider);
  return biometricService.getAvailableBiometrics();
});

/// 생체인증 키 존재 여부를 제공하는 FutureProvider.
///
/// **반환값:**
/// - `true`: 생체인증 키 존재
/// - `false`: 생체인증 키 없음
///
/// **사용 예시:**
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final hasBiometricKey = ref.watch(hasBiometricKeyProvider);
///
///     return hasBiometricKey.when(
///       data: (hasKey) => Text(hasKey ? '생체인증 활성화' : '생체인증 비활성화'),
///       loading: () => CircularProgressIndicator(),
///       error: (err, stack) => Text('오류: $err'),
///     );
///   }
/// }
/// ```
final hasBiometricKeyProvider = FutureProvider<bool>((ref) async {
  final biometricKeyService = ref.watch(biometricKeyServiceProvider);
  return biometricKeyService.isBiometricKeyAvailable();
});

/// 주 생체인증 유형을 제공하는 FutureProvider.
///
/// **반환값:**
/// - 주 생체인증 유형 (Face ID > Touch ID > 홍채 순)
/// - `null` (생체인증 사용 불가)
///
/// **사용 예시:**
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final primaryType = ref.watch(primaryBiometricTypeProvider);
///
///     return primaryType.when(
///       data: (type) {
///         if (type == BiometricType.face) {
///           return Text('Face ID로 잠금 해제');
///         } else if (type == BiometricType.fingerprint) {
///           return Text('지문으로 잠금 해제');
///         }
///         return Text('생체인증 사용 불가');
///       },
///       loading: () => CircularProgressIndicator(),
///       error: (err, stack) => Text('오류: $err'),
///     );
///   }
/// }
/// ```
final primaryBiometricTypeProvider = FutureProvider<BiometricType?>((ref) async {
  final biometricService = ref.watch(enhancedBiometricServiceProvider);
  return biometricService.getPrimaryBiometricType();
});
