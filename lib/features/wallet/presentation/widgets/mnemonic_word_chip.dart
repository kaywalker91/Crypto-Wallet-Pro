import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Single mnemonic word chip with index number
class MnemonicWordChip extends StatelessWidget {
  final int index;
  final String word;
  final bool isHidden;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const MnemonicWordChip({
    super.key,
    required this.index,
    required this.word,
    this.isHidden = false,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Index number
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Word
            Text(
              isHidden ? '••••••' : word,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty mnemonic slot for input
class MnemonicEmptySlot extends StatelessWidget {
  final int index;
  final bool isActive;
  final VoidCallback? onTap;

  const MnemonicEmptySlot({
    super.key,
    required this.index,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.cardBorder.withValues(alpha: 0.5),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Index number
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Placeholder
            Text(
              'Word ${index + 1}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
