import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/token.dart';

/// Token list item widget
class TokenListTile extends StatelessWidget {
  final Token token;
  final VoidCallback? onTap;

  const TokenListTile({
    super.key,
    required this.token,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Token icon
            _TokenIcon(color: token.color, symbol: token.symbol),

            const SizedBox(width: 12),

            // Token info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.symbol,
                    style: AppTypography.tokenAmount,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    token.name,
                    style: AppTypography.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Balance info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  token.balance,
                  style: AppTypography.tokenAmount,
                ),
                const SizedBox(height: 2),
                Text(
                  token.valueUsd,
                  style: AppTypography.tokenValue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Token icon with colored background
class _TokenIcon extends StatelessWidget {
  final Color color;
  final String symbol;

  const _TokenIcon({
    required this.color,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          symbol.length > 2 ? symbol.substring(0, 2) : symbol,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
