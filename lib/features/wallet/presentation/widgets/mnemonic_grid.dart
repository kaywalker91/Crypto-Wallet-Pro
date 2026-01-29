import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glassmorphism.dart';
import 'mnemonic_word_chip.dart';

/// Grid display for mnemonic words (12 or 24 words)
class MnemonicGrid extends StatelessWidget {
  final List<String> words;
  final bool isHidden;
  final bool showCopyButton;
  final VoidCallback? onCopy;

  const MnemonicGrid({
    super.key,
    required this.words,
    this.isHidden = false,
    this.showCopyButton = true,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with copy button
          if (showCopyButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.key_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recovery Phrase',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _CopyButton(
                  onPressed: onCopy ??
                      () {
                        Clipboard.setData(ClipboardData(text: words.join(' ')));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Recovery phrase copied!'),
                            backgroundColor: AppColors.surface,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                ),
              ],
            ),
          if (showCopyButton) const SizedBox(height: 16),

          // Word grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(words.length, (index) {
              return MnemonicWordChip(
                index: index,
                word: words[index],
                isHidden: isHidden,
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Copy button widget
class _CopyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CopyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.copy_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Copy',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Warning banner for mnemonic security
class MnemonicSecurityWarning extends StatelessWidget {
  const MnemonicSecurityWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep it safe!',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Write down these words in order and store them in a safe place. Never share your recovery phrase with anyone.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
