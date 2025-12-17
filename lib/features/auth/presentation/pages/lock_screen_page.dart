import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Simple lock screen that requests biometric authentication before entering the app.
class LockScreenPage extends ConsumerStatefulWidget {
  const LockScreenPage({super.key});

  @override
  ConsumerState<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends ConsumerState<LockScreenPage> {
  bool _isAuthenticating = false;
  String? _error;
  final TextEditingController _pinController = TextEditingController();
  static const int _maxAttempts = 3;
  int _attemptsLeft = _maxAttempts;
  DateTime? _cooldownUntil;

  bool get _inCooldown =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  Duration get _cooldownRemaining =>
      _cooldownUntil != null ? _cooldownUntil!.difference(DateTime.now()) : Duration.zero;

  Future<void> _authenticate() async {
    final biometricEnabled =
        ref.read(settingsProvider).settings.biometricEnabled;
    if (!biometricEnabled) {
      setState(() {
        _error = '생체인증이 비활성화되어 있습니다. PIN을 사용하세요.';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });
    final authed = await ref.read(walletProvider.notifier).authenticate();
    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      _error = authed ? null : '인증에 실패했습니다. 다시 시도해주세요.';
    });
    if (authed && mounted) {
      context.go(Routes.main);
    }
  }

  Future<void> _verifyPin() async {
    if (_inCooldown) {
      setState(() {
        _error =
            '잠금 해제 시도가 일시 중단되었습니다. ${_cooldownRemaining.inSeconds}초 후 다시 시도하세요.';
      });
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _error = '4자리 이상 PIN을 입력하세요.';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    final pinService = ref.read(pinServiceProvider);
    final hasPin = await pinService.hasPin();
    if (!hasPin) {
      setState(() {
        _isAuthenticating = false;
        _error = '등록된 PIN이 없습니다. 생체인증을 사용하세요.';
      });
      return;
    }

    final success = await pinService.verifyPin(pin);
    if (!mounted) return;

    if (success) {
      await ref.read(authSessionServiceProvider).markSessionValid();
      await ref.read(walletProvider.notifier).markAuthenticated();
      setState(() {
        _isAuthenticating = false;
        _error = null;
        _attemptsLeft = _maxAttempts;
        _cooldownUntil = null;
      });
      if (mounted) {
        context.go(Routes.main);
      }
    } else {
      _attemptsLeft -= 1;
      if (_attemptsLeft <= 0) {
        _cooldownUntil = DateTime.now().add(const Duration(seconds: 30));
        _attemptsLeft = _maxAttempts;
      }
      setState(() {
        _isAuthenticating = false;
        _error = _cooldownUntil != null && _inCooldown
            ? '여러 번 실패했습니다. ${_cooldownRemaining.inSeconds}초 후에 다시 시도하세요.'
            : 'PIN이 올바르지 않습니다. 남은 시도: $_attemptsLeft';
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPinAsync = ref.watch(hasPinProvider);
    final hasPin = hasPinAsync.maybeWhen(data: (value) => value, orElse: () => false);
    final settingsState = ref.watch(settingsProvider);
    final biometricEnabled = settingsState.settings.biometricEnabled;
    final pinEnabled = settingsState.settings.pinEnabled;

    // If both biometrics and PIN are disabled, skip lock screen.
    if (!biometricEnabled && !pinEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(authSessionServiceProvider).markSessionValid();
        await ref.read(walletProvider.notifier).markAuthenticated();
        if (mounted) context.go(Routes.main);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceLight.withOpacity(0.15),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '지갑 잠금 해제',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '생체인증으로 지갑을 보호합니다.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                if (!hasPin) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PIN이 설정되지 않았습니다. 생체인증 실패 시 접근이 차단되지 않을 수 있습니다.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(Routes.pinSetup),
                          child: const Text('PIN 설정'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                GradientButton(
                  text: biometricEnabled ? '생체인증으로 잠금 해제' : '생체인증 사용 불가',
                  icon: Icons.fingerprint_rounded,
                  isLoading: _isAuthenticating,
                  onPressed:
                      _isAuthenticating || !biometricEnabled ? null : _authenticate,
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                if (pinEnabled) ...[
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceLight.withOpacity(0.12),
                      hintText: 'PIN 입력',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GradientButton(
                    text: _inCooldown
                        ? '쿨다운 중 (${_cooldownRemaining.inSeconds}s)'
                        : 'PIN으로 잠금 해제',
                    icon: Icons.lock_open_rounded,
                    isLoading: _isAuthenticating,
                    onPressed:
                        _isAuthenticating || _inCooldown ? null : _verifyPin,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'PIN 잠금이 비활성화되어 있습니다.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
