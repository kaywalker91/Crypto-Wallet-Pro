import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

/// Enhanced settings header with Glassmorphism design
/// Displays wallet connection status and address
class SettingsHeader extends StatelessWidget {
  final String? walletAddress;
  final bool isConnected;
  final String appVersion;
  final VoidCallback? onAddressTap;

  const SettingsHeader({
    super.key,
    this.walletAddress,
    this.isConnected = false,
    this.appVersion = 'v1.0.0',
    this.onAddressTap,
  });

  String get _shortAddress {
    if (walletAddress == null || walletAddress!.length < 10) {
      return walletAddress ?? '';
    }
    return '${walletAddress!.substring(0, 6)}...${walletAddress!.substring(walletAddress!.length - 4)}';
  }

  void _copyAddress(BuildContext context) {
    if (walletAddress != null) {
      Clipboard.setData(ClipboardData(text: walletAddress!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Address copied to clipboard'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              // Settings icon with gradient background
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: AppTypography.textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your wallet preferences',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Version badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  appVersion,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Wallet status card
        if (isConnected && walletAddress != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GlassmorphicAccentCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Connection status indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Address info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Wallet Connected',
                              style: AppTypography.textTheme.labelMedium?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _shortAddress,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Copy button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _copyAddress(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
