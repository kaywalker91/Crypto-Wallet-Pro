
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SessionProposalDialog extends StatelessWidget {
  final SessionProposalEvent proposal;
  final Function(List<String> accounts) onApprove;
  final VoidCallback onReject;
  final List<String> availableAccounts; // Local wallet addresses

  const SessionProposalDialog({
    super.key,
    required this.proposal,
    required this.onApprove,
    required this.onReject,
    required this.availableAccounts,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = proposal.params.proposer.metadata;

    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          if (metadata.icons.isNotEmpty)
            CircleAvatar(
              backgroundImage: NetworkImage(metadata.icons.first),
              radius: 30,
            ),
          const SizedBox(height: 16),
          Text(
            metadata.name,
            style: AppTypography.titleLarge.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            metadata.url,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Wants to connect to your wallet',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Simple account selection (auto-select first for now)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    availableAccounts.isNotEmpty ? availableAccounts.first : 'No Account',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          child: Text('Reject', style: AppTypography.buttonText.copyWith(color: AppColors.error)),
        ),
        ElevatedButton(
          onPressed: () => onApprove(availableAccounts), // Approve with all accounts (simplified)
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: Text('Approve', style: AppTypography.buttonText.copyWith(color: AppColors.background)),
        ),
      ],
    );
  }
}
