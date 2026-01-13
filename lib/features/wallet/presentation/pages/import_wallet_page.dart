import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/widgets/gradient_button.dart';
// ✅ SECURITY: 스크린샷 방지 위젯 import
import '../../../../core/security/widgets/secure_content_wrapper.dart';
import '../providers/wallet_provider.dart';
import '../widgets/mnemonic_input_grid.dart';

/// Import wallet page - restore wallet from 12-word mnemonic
class ImportWalletPage extends ConsumerStatefulWidget {
  const ImportWalletPage({super.key});

  @override
  ConsumerState<ImportWalletPage> createState() => _ImportWalletPageState();
}

class _ImportWalletPageState extends ConsumerState<ImportWalletPage> {
  List<String> _words = List.filled(12, '');
  bool _isValidMnemonic = false;
  bool _showImportSuccess = false;

  void _onWordsChanged(List<String> words) {
    setState(() {
      _words = words;
      _validateMnemonic();
    });
  }

  void _validateMnemonic() {
    final notifier = ref.read(walletProvider.notifier);
    _isValidMnemonic = notifier.validateMnemonic(_words);
  }

  Future<void> _importWallet() async {
    if (!_isValidMnemonic) return;

    final mnemonic = _words.join(' ');
    await ref.read(walletProvider.notifier).importWallet(mnemonic);

    final walletState = ref.read(walletViewProvider);
    if (walletState.hasWallet && mounted) {
      setState(() {
        _showImportSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletViewProvider);
    final isLoading = walletState.isLoading;
    final error = walletState.error;

    if (_showImportSuccess && walletState.hasWallet) {
      return _ImportSuccessScreen(
        address: walletState.wallet!.shortAddress,
      );
    }

    // ✅ SECURITY: 니모닉 입력 화면 스크린샷 방지
    return SecureContentWrapper(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Import Wallet',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info banner
                        const ImportWalletInfo(),

                        const SizedBox(height: 24),

                        // Mnemonic input grid
                        MnemonicInputGrid(
                          words: _words,
                          onWordsChanged: _onWordsChanged,
                          wordCount: 12,
                        ),

                        const SizedBox(height: 16),

                        // Word count indicator
                        _WordCountIndicator(
                          filledCount: _words.where((w) => w.trim().isNotEmpty).length,
                          totalCount: 12,
                        ),

                        // Error message
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: error),
                        ],

                        const SizedBox(height: 24),

                        // Security note
                        const _SecurityNote(),
                      ],
                    ),
                  ),
                ),

                // Import button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: GradientButton(
                    text: 'Import Wallet',
                    onPressed: _isValidMnemonic && !isLoading ? _importWallet : null,
                    isLoading: isLoading,
                    width: double.infinity,
                    icon: Icons.download_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Word count indicator
class _WordCountIndicator extends StatelessWidget {
  final int filledCount;
  final int totalCount;

  const _WordCountIndicator({
    required this.filledCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = filledCount == totalCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isComplete ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: isComplete ? AppColors.success : AppColors.textTertiary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '$filledCount / $totalCount words entered',
          style: AppTypography.bodySmall.copyWith(
            color: isComplete ? AppColors.success : AppColors.textTertiary,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Error banner
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Security note
class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Security Tips',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SecurityTip(
            icon: Icons.visibility_off_rounded,
            text: 'Make sure no one is watching your screen',
          ),
          const SizedBox(height: 8),
          _SecurityTip(
            icon: Icons.wifi_off_rounded,
            text: 'Use a secure network connection',
          ),
          const SizedBox(height: 8),
          _SecurityTip(
            icon: Icons.lock_rounded,
            text: 'Never share your recovery phrase with anyone',
          ),
        ],
      ),
    );
  }
}

/// Single security tip
class _SecurityTip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SecurityTip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.textTertiary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Import success screen
class _ImportSuccessScreen extends ConsumerWidget {
  final String address;

  const _ImportSuccessScreen({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPinAsync = ref.watch(hasPinProvider);
    final hasPin = hasPinAsync.maybeWhen(data: (value) => value, orElse: () => false);

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

                // Success icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 64,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Wallet Imported!',
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Your wallet has been successfully imported and is ready to use.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Wallet address card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Your Wallet Address',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Continue button
                GradientButton(
                  text: 'Go to Wallet',
                  onPressed: () {
                    context.go('/main');
                  },
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                GradientOutlinedButton(
                  text: hasPin ? 'PIN 설정 완료' : 'Set PIN for Backup',
                  onPressed: hasPin ? null : () => context.push('/pin-setup'),
                  width: double.infinity,
                  icon: Icons.lock_rounded,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
