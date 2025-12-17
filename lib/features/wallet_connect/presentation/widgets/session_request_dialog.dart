
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
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Signature Request',
        style: AppTypography.titleLarge.copyWith(color: Colors.white),
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                params,
                style: AppTypography.bodySmall.copyWith(fontFamily: 'RobotoMono', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          child: Text('Reject', style: AppTypography.buttonText.copyWith(color: AppColors.error)),
        ),
        ElevatedButton(
          onPressed: onApprove,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: Text('Approve', style: AppTypography.buttonText.copyWith(color: AppColors.background)),
        ),
      ],
    );
  }
}
