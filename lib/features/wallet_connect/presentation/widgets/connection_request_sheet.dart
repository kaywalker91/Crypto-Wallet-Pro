import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/dapp_info.dart';

/// Bottom sheet for approving/rejecting new WalletConnect session connections
class ConnectionRequestSheet extends StatelessWidget {
  final DappInfo dapp;
  final String chainName;
  final List<String> methods;
  final List<String> events;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isLoading;

  const ConnectionRequestSheet({
    super.key,
    required this.dapp,
    required this.chainName,
    this.methods = const [],
    this.events = const [],
    this.onApprove,
    this.onReject,
    this.isLoading = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DappInfo dapp,
    required String chainName,
    List<String> methods = const [],
    List<String> events = const [],
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sheetMaxWidth),
          child: ConnectionRequestSheet(
            dapp: dapp,
            chainName: chainName,
            methods: methods,
            events: events,
            onApprove: () => Navigator.pop(context, true),
            onReject: () => Navigator.pop(context, false),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // dApp Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: dapp.iconUrl != null
                    ? _buildDappIcon(dapp.iconUrl!)
                    : _buildIconPlaceholder(),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Connection Request',
                style: AppTypography.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              // dApp name
              Text(
                dapp.name,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              // dApp URL
              Text(
                dapp.url,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              // Connection details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chain
                    _buildInfoRow(
                      Icons.language_rounded,
                      'Network',
                      chainName,
                    ),
                    if (methods.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Permissions',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: methods.map(_buildPermissionChip).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Only connect to trusted websites. Review the permissions before approving.',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  // Reject button
                  Expanded(
                    child: GradientOutlinedButton(
                      onPressed: isLoading ? null : onReject,
                      text: 'Reject',
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Approve button
                  Expanded(
                    child: GradientButton(
                      onPressed: isLoading ? null : onApprove,
                      text: 'Connect',
                      isLoading: isLoading,
                    ),
                  ),
                ],
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
          dapp.name.isNotEmpty ? dapp.name[0].toUpperCase() : '?',
          style: AppTypography.textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textTertiary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionChip(String method) {
    IconData icon;
    String label;

    if (method.contains('sendTransaction')) {
      icon = Icons.send_rounded;
      label = 'Send Transactions';
    } else if (method.contains('sign')) {
      icon = Icons.draw_rounded;
      label = 'Sign Messages';
    } else {
      icon = Icons.check_circle_outline;
      label = method;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
