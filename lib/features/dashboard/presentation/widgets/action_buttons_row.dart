import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Row of action buttons (Send, Receive, Swap, Buy)
class ActionButtonsRow extends StatelessWidget {
  final VoidCallback? onSend;
  final VoidCallback? onReceive;
  final VoidCallback? onSwap;
  final VoidCallback? onBuy;

  const ActionButtonsRow({
    super.key,
    this.onSend,
    this.onReceive,
    this.onSwap,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.arrow_upward,
          label: 'Send',
          color: AppColors.primary,
          onTap: onSend,
        ),
        _ActionButton(
          icon: Icons.arrow_downward,
          label: 'Receive',
          color: AppColors.success,
          onTap: onReceive,
        ),
        _ActionButton(
          icon: Icons.swap_horiz,
          label: 'Swap',
          color: AppColors.secondary,
          onTap: onSwap,
        ),
        _ActionButton(
          icon: Icons.add,
          label: 'Buy',
          color: AppColors.warning,
          onTap: onBuy,
        ),
      ],
    );
  }
}

/// Single action button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
