
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Signature Request',
        style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Method: $method',
              style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Params:',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                params,
                style: AppTypography.bodySmall.copyWith(
                  fontFamily: 'RobotoMono',
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
          ),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: onApprove,
          child: const Text('Approve'),
        ),
      ],
    );
  }
}
