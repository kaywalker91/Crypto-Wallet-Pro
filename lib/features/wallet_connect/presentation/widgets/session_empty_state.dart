import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Empty state widget for WalletConnect sessions - Simplified design
class SessionEmptyState extends StatelessWidget {
  final String? message;
  final bool isFiltered;

  const SessionEmptyState({
    super.key,
    this.message,
    this.isFiltered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimal icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered ? Icons.filter_list_off : Icons.link_off_rounded,
              size: 28,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            isFiltered ? 'No results' : 'No active sessions',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Message
          Text(
            message ?? "Use 'Scan QR Code' above to connect to a dApp",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state widget for WalletConnect sessions
class SessionErrorState extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;

  const SessionErrorState({
    super.key,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(26),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withAlpha(77),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'Connection Error',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Error message
            Text(
              error ?? 'Failed to load sessions. Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              // Retry button
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
