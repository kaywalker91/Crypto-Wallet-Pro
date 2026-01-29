import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/app_settings.dart';

/// Bottom sheet for selecting network
class NetworkSelectorSheet extends StatelessWidget {
  final NetworkType currentNetwork;
  final ValueChanged<NetworkType> onNetworkSelected;

  const NetworkSelectorSheet({
    super.key,
    required this.currentNetwork,
    required this.onNetworkSelected,
  });

  static Future<NetworkType?> show(
    BuildContext context, {
    required NetworkType currentNetwork,
  }) {
    return showModalBottomSheet<NetworkType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sheetMaxWidth),
          child: NetworkSelectorSheet(
            currentNetwork: currentNetwork,
            onNetworkSelected: (network) {
              Navigator.pop(context, network);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Network',
                      style: AppTypography.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the chain for balances and transactions.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 12),
                  children: [
                    ...NetworkType.values.map((network) => _NetworkOption(
                          network: network,
                          isSelected: network == currentNetwork,
                          onTap: () => onNetworkSelected(network),
                        )),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Switching networks may refresh balances and activity.',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkOption extends StatelessWidget {
  final NetworkType network;
  final bool isSelected;
  final VoidCallback onTap;

  const _NetworkOption({
    required this.network,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMainnet = network == NetworkType.mainnet;
    final badgeColor = isMainnet ? AppColors.success : AppColors.warning;
    final badgeLabel = isMainnet ? 'MAINNET' : 'TESTNET';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Network icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isMainnet
                      ? const LinearGradient(
                          colors: [Color(0xFF627EEA), Color(0xFF3C3C3D)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF9B8DFF), Color(0xFF6B5CE7)],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Network info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            network.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chain ID: ${network.chainId}',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Selected indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
