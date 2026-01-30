import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/widgets/animated_counter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../domain/entities/wallet_balance.dart';

/// Main balance card showing total wallet value
class BalanceCard extends StatelessWidget {
  final WalletBalance? balance;
  final bool isLoading;
  final VoidCallback? onCopyAddress;

  const BalanceCard({
    super.key,
    this.balance,
    this.isLoading = false,
    this.onCopyAddress,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _BalanceCardSkeleton();
    }

    return GlassCard(
      showGlow: true,
      glowColor: AppColors.neonCyanGlow,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Total Balance',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // USD Balance
          _buildAnimatedBalance(
            context,
            balance?.balanceUsd ?? '\$0.00',
            style: AppTypography.balanceAmount,
            isUsd: true,
          ),

          const SizedBox(height: 4),

          // ETH Balance
          _buildAnimatedBalance(
            context,
            balance?.balanceEth ?? '0.0000 ETH',
            style: AppTypography.balanceUsd,
            isUsd: false,
          ),

          const SizedBox(height: 20),

          // Wallet address
          InkWell(
            onTap: () {
              if (balance?.address != null) {
                Clipboard.setData(ClipboardData(text: balance!.address));
                onCopyAddress?.call();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    balance?.shortAddress ?? '0x...',
                    style: AppTypography.addressText,
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBalance(
    BuildContext context,
    String distinctString,
    {TextStyle? style, bool isUsd = true}
  ) {
    // Basic parsing: remove $, ETH, commas
    final cleanString = distinctString
        .replaceAll('\$', '')
        .replaceAll('ETH', '')
        .replaceAll(',', '')
        .trim();
    final value = double.tryParse(cleanString) ?? 0.0;

    return AnimatedCounter(
      value: value,
      style: style,
      prefix: isUsd ? '\$' : '',
      suffix: isUsd ? '' : ' ETH',
      fractionalDigits: isUsd ? 2 : 4,
    );
  }
}

/// Skeleton loading state for balance card
class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Shimmer.fromColors(
        baseColor: AppColors.cardBackground,
        highlightColor: AppColors.glassSurface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: 180,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 160,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
