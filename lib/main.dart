import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/deep_link_service.dart';
import 'core/security/services/device_integrity_service.dart';
import 'core/security/widgets/integrity_warning_dialog.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF16213E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: CryptoWalletApp(),
    ),
  );
}

/// Root application widget with device integrity check
class CryptoWalletApp extends ConsumerStatefulWidget {
  const CryptoWalletApp({super.key});

  @override
  ConsumerState<CryptoWalletApp> createState() => _CryptoWalletAppState();
}

class _CryptoWalletAppState extends ConsumerState<CryptoWalletApp> {
  final DeviceIntegrityService _integrityService = DeviceIntegrityService();
  bool _hasCheckedIntegrity = false;

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 기기 무결성 검사 수행 (비동기)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeviceIntegrity();
    });
  }

  /// 기기 무결성 검사 및 경고 표시
  ///
  /// 루팅/탈옥이 감지되면 사용자에게 경고 다이얼로그를 표시합니다.
  /// 사용자가 위험을 감수하고 계속 사용하거나, 앱을 종료할 수 있습니다.
  Future<void> _checkDeviceIntegrity() async {
    if (_hasCheckedIntegrity) return;
    _hasCheckedIntegrity = true;

    try {
      // 백그라운드에서 무결성 검사 수행
      final result = await _integrityService.checkDeviceIntegrity();

      // 위험 감지 시 경고 다이얼로그 표시
      if (result.isCompromised && mounted) {
        final shouldContinue = await showIntegrityWarning(context, result);

        // 사용자가 앱 종료를 선택한 경우
        if (shouldContinue == false && mounted) {
          // Android: 앱 종료
          SystemNavigator.pop();
        }
      }
    } catch (e) {
      // 검사 실패 시 로그만 남기고 계속 진행 (Graceful Degradation)
      debugPrint('Device integrity check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize DeepLinkService to listen for incoming links
    ref.watch(deepLinkServiceProvider);

    return MaterialApp.router(
      title: 'Crypto Wallet Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
