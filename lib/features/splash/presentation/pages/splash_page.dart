import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

/// Splash screen with animated logo and app name
/// Automatically navigates to onboarding after delay
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.wait([
      Future.delayed(AppConstants.splashDuration),
      _waitForWalletLoad(),
    ]);

    if (!mounted) return;
    final walletState = ref.read(walletViewProvider);

    final hasWallet = walletState.wallet != null;
    final settingsState = ref.read(settingsProvider);
    final requireAuth =
        settingsState.settings.biometricEnabled || settingsState.settings.pinEnabled;

    if (hasWallet) {
      if (walletState.isAuthenticated) {
        context.go(Routes.main);
        return;
      }
      if (requireAuth) {
        context.go(Routes.lock);
        return;
      }
      await ref.read(walletProvider.notifier).markAuthenticated();
      context.go(Routes.main);
      return;
    }

    context.go(Routes.onboarding);
  }

  /// Waits until the wallet provider finishes its initial load.
  Future<WalletState> _waitForWalletLoad() {
    return ref.read(walletProvider.future);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Logo
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: const AppLogo(
                        size: 140,
                        showGlow: true,
                        animated: true,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // App Name
              AnimatedBuilder(
                animation: _textFadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFadeAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          AppConstants.appName,
                          style: AppTypography.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: Text(
                            AppConstants.appTagline,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              // Loading indicator
              FadeTransition(
                opacity: _textFadeAnimation,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
