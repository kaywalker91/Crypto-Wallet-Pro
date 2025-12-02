import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/wallet_provider.dart';
import '../widgets/mnemonic_grid.dart';

/// Create wallet page with multi-step flow
class CreateWalletPage extends ConsumerWidget {
  const CreateWalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final currentStep = walletState.currentStep;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(context, ref, currentStep, walletState),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(
    BuildContext context,
    WidgetRef ref,
    WalletCreationStep step,
    WalletState state,
  ) {
    switch (step) {
      case WalletCreationStep.intro:
        return _IntroStep(key: const ValueKey('intro'));
      case WalletCreationStep.showMnemonic:
        return _ShowMnemonicStep(
          key: const ValueKey('showMnemonic'),
          words: state.mnemonicWords,
          isLoading: state.isLoading,
        );
      case WalletCreationStep.confirmMnemonic:
        return _ConfirmMnemonicStep(
          key: const ValueKey('confirmMnemonic'),
          words: state.mnemonicWords,
          isLoading: state.isLoading,
        );
      case WalletCreationStep.complete:
        return _CompleteStep(
          key: const ValueKey('complete'),
          address: state.wallet?.shortAddress ?? '',
        );
    }
  }
}

/// Step 1: Intro - Create or Import wallet
class _IntroStep extends ConsumerWidget {
  const _IntroStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(walletProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const Spacer(),

          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyanGlow,
                  blurRadius: 30,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.background,
              size: 56,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Create New Wallet',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            'Your wallet will be secured with a 12-word recovery phrase. Make sure to write it down and keep it safe.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Create wallet button
          GradientButton(
            text: 'Create New Wallet',
            onPressed: isLoading
                ? null
                : () {
                    ref.read(walletProvider.notifier).generateNewWallet();
                  },
            isLoading: isLoading,
            width: double.infinity,
          ),

          const SizedBox(height: 16),

          // Import wallet button
          GradientOutlinedButton(
            text: 'Import Existing Wallet',
            onPressed: isLoading
                ? null
                : () {
                    context.push('/import-wallet');
                  },
            width: double.infinity,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Step 2: Show generated mnemonic
class _ShowMnemonicStep extends ConsumerStatefulWidget {
  final List<String> words;
  final bool isLoading;

  const _ShowMnemonicStep({
    super.key,
    required this.words,
    required this.isLoading,
  });

  @override
  ConsumerState<_ShowMnemonicStep> createState() => _ShowMnemonicStepState();
}

class _ShowMnemonicStepState extends ConsumerState<_ShowMnemonicStep> {
  bool _hasConfirmedBackup = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(walletProvider.notifier).goBack();
                },
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  'Recovery Phrase',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Write down these 12 words in order',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Mnemonic grid
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  MnemonicGrid(words: widget.words),
                  const SizedBox(height: 16),
                  const MnemonicSecurityWarning(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Confirmation checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                _hasConfirmedBackup = !_hasConfirmedBackup;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasConfirmedBackup
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _hasConfirmedBackup
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _hasConfirmedBackup
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        width: 2,
                      ),
                    ),
                    child: _hasConfirmedBackup
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.background,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I have written down my recovery phrase and stored it in a safe place',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Continue button
          GradientButton(
            text: 'Continue',
            onPressed: _hasConfirmedBackup
                ? () {
                    ref.read(walletProvider.notifier).proceedToConfirmation();
                  }
                : null,
            width: double.infinity,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Step 3: Confirm mnemonic
class _ConfirmMnemonicStep extends ConsumerStatefulWidget {
  final List<String> words;
  final bool isLoading;

  const _ConfirmMnemonicStep({
    super.key,
    required this.words,
    required this.isLoading,
  });

  @override
  ConsumerState<_ConfirmMnemonicStep> createState() =>
      _ConfirmMnemonicStepState();
}

class _ConfirmMnemonicStepState extends ConsumerState<_ConfirmMnemonicStep> {
  late List<int> _verificationIndices;
  final Map<int, String?> _selectedWords = {};
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    // Pick 3 random indices to verify
    final indices = List.generate(widget.words.length, (i) => i)..shuffle();
    _verificationIndices = indices.take(3).toList()..sort();
  }

  void _selectWord(int index, String word) {
    setState(() {
      _selectedWords[index] = word;
      _checkVerification();
    });
  }

  void _checkVerification() {
    _isVerified = _verificationIndices.every((index) {
      return _selectedWords[index] == widget.words[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(walletProvider.notifier).goBack();
                },
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  'Verify Phrase',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Select the correct words to verify your backup',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          // Verification slots
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _verificationIndices.map((index) {
                  return _VerificationSlot(
                    index: index,
                    correctWord: widget.words[index],
                    selectedWord: _selectedWords[index],
                    allWords: widget.words,
                    onSelect: (word) => _selectWord(index, word),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Complete button
          GradientButton(
            text: 'Complete Setup',
            onPressed: _isVerified && !widget.isLoading
                ? () {
                    ref.read(walletProvider.notifier).confirmMnemonicBackup();
                  }
                : null,
            isLoading: widget.isLoading,
            width: double.infinity,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Verification slot widget
class _VerificationSlot extends StatefulWidget {
  final int index;
  final String correctWord;
  final String? selectedWord;
  final List<String> allWords;
  final Function(String) onSelect;

  const _VerificationSlot({
    required this.index,
    required this.correctWord,
    required this.selectedWord,
    required this.allWords,
    required this.onSelect,
  });

  @override
  State<_VerificationSlot> createState() => _VerificationSlotState();
}

class _VerificationSlotState extends State<_VerificationSlot> {
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  void _generateOptions() {
    // Get 3 random wrong words + correct word
    final wrongWords = widget.allWords
        .where((w) => w != widget.correctWord)
        .toList()
      ..shuffle();
    _options = [widget.correctWord, ...wrongWords.take(3)]..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.selectedWord == widget.correctWord;
    final hasSelected = widget.selectedWord != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word number label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasSelected
                      ? (isCorrect ? AppColors.success : AppColors.error)
                          .withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Word #${widget.index + 1}',
                  style: AppTypography.labelMedium.copyWith(
                    color: hasSelected
                        ? (isCorrect ? AppColors.success : AppColors.error)
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? AppColors.success : AppColors.error,
                  size: 20,
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Options
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((word) {
              final isSelected = widget.selectedWord == word;
              return GestureDetector(
                onTap: hasSelected ? null : () => widget.onSelect(word),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isCorrect ? AppColors.success : AppColors.error)
                            .withOpacity(0.2)
                        : AppColors.surfaceLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (isCorrect ? AppColors.success : AppColors.error)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    word,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? (isCorrect ? AppColors.success : AppColors.error)
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Step 4: Wallet creation complete
class _CompleteStep extends ConsumerWidget {
  final String address;

  const _CompleteStep({
    super.key,
    required this.address,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
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
            'Wallet Created!',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            'Your wallet has been successfully created and secured.',
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
