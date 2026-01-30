
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/widgets/gradient_button.dart';

class SessionRequestDialog extends StatelessWidget {
  final SessionRequestEvent request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const SessionRequestDialog({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final method = request.method;
    final params = request.params.toString(); // Simplify for display

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        showGlow: true,
        glowColor: AppColors.primary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Signature Request',
                    style: AppTypography.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Text(
              'Method',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              method,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Params',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    params,
                    style: AppTypography.bodySmall.copyWith(
                      fontFamily: 'RobotoMono',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GradientButton(
                    text: 'Approve',
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
