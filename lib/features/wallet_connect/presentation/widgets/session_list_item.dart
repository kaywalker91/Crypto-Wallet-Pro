import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/wallet_session.dart';

/// Session list item widget for WalletConnect sessions
class SessionListItem extends StatelessWidget {
  final WalletSession session;
  final VoidCallback? onTap;

  const SessionListItem({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // dApp Icon
              Hero(
                tag: 'session_${session.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: session.dapp.iconUrl != null
                      ? _buildDappIcon(session.dapp.iconUrl!)
                      : _buildIconPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),
              // Session Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // dApp name and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.dapp.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Chain and connection time
                    Text(
                      '${session.chainName} • ${session.connectionDuration}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Methods preview
                    if (session.methods.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: session.methods
                            .take(3)
                            .map((method) => _buildMethodChip(method))
                            .toList(),
                      ),
                  ],
                ),
              ),
              // Arrow
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDappIcon(String iconUrl) {
    if (iconUrl.startsWith('http')) {
      return Image.network(
        iconUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildIconPlaceholder();
        },
      );
    } else {
      return Image.asset(
        iconUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildIconPlaceholder();
        },
      );
    }
  }

  Widget _buildIconPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          session.dapp.name.isNotEmpty ? session.dapp.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (session.status) {
      case SessionStatus.active:
        backgroundColor = AppColors.success.withAlpha(26);
        textColor = AppColors.success;
        label = 'Active';
        break;
      case SessionStatus.expired:
        backgroundColor = AppColors.error.withAlpha(26);
        textColor = AppColors.error;
        label = 'Expired';
        break;
      case SessionStatus.pending:
        backgroundColor = AppColors.warning.withAlpha(26);
        textColor = AppColors.warning;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMethodChip(String method) {
    // Simplify method name for display
    String displayName = method;
    if (method.startsWith('eth_')) {
      displayName = method.substring(4);
    } else if (method.startsWith('personal_')) {
      displayName = method.substring(9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Text(
        displayName,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
