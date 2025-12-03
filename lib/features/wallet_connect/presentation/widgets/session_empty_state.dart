import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Empty state widget for WalletConnect sessions
class SessionEmptyState extends StatelessWidget {
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isFiltered;

  const SessionEmptyState({
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isFiltered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardBorder,
                  width: 2,
                ),
              ),
              child: Icon(
                isFiltered ? Icons.filter_list_off : Icons.link_off_rounded,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              isFiltered ? 'No Sessions Found' : 'No Connected dApps',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              message ??
                  (isFiltered
                      ? 'Try adjusting your filter to see more sessions'
                      : 'Connect to dApps by scanning a WalletConnect QR code'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              // Action button
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
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
