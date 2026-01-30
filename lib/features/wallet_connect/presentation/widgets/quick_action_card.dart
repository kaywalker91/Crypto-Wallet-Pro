import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A compact, reusable action card for the Connect screen
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final Widget? trailing;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.cardBackground;
    final iconClr = iconColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconClr.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconClr,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Label and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing widget or chevron
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
          ],
        ),
      ),
    );
  }
}

/// MetaMask-styled action card with status indicator
class MetaMaskActionCard extends StatelessWidget {
  final bool isConnected;
  final String? connectedAddress;
  final VoidCallback onTap;
  final VoidCallback? onDisconnect;

  const MetaMaskActionCard({
    super.key,
    required this.isConnected,
    this.connectedAddress,
    required this.onTap,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade900.withValues(alpha: 0.2),
              Colors.orange.shade800.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // MetaMask icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Label and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MetaMask',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isConnected && connectedAddress != null)
                    Text(
                      connectedAddress!,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    )
                  else
                    Text(
                      'Tap to connect',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            // Status indicator or disconnect button
            if (isConnected && onDisconnect != null)
              IconButton(
                icon: const Icon(Icons.link_off_rounded),
                color: AppColors.error,
                iconSize: 20,
                onPressed: onDisconnect,
                tooltip: 'Disconnect',
              )
            else
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.success : AppColors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
