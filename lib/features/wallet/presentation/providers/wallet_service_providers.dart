import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../shared/services/biometric_service.dart';
import '../../../../shared/services/auth_session_service.dart';
import '../../../../shared/services/pin_service.dart';
import '../../../../shared/providers/storage_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

// ============================================================================
// Service Providers
// ============================================================================

/// Biometric Service Provider
/// 
/// 생체 인증(지문, Face ID) 서비스를 제공합니다.
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(LocalAuthentication());
});

/// Auth Session Service Provider
/// 
/// 인증 세션을 관리합니다.
/// - 생체 인증 활성화 상태 확인
/// - 세션 유효성 검증
/// - 인증 요청 처리
final authSessionServiceProvider = Provider<AuthSessionService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final biometric = ref.watch(biometricServiceProvider);
  final settings = ref.watch(settingsProvider).settings;
  final authEnabled = settings.biometricEnabled || settings.pinEnabled;
  return AuthSessionService(
    storage,
    biometric,
    authEnabled: authEnabled,
  );
});

/// PIN Service Provider
/// 
/// PIN 인증 서비스를 제공합니다.
final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return PinService(storage);
});

/// PIN 설정 여부 확인 Provider
/// 
/// PIN이 설정되어 있는지 비동기로 확인합니다.
final hasPinProvider = FutureProvider<bool>((ref) async {
  final pinService = ref.watch(pinServiceProvider);
  return pinService.hasPin();
});
