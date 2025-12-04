import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
      backgroundColor: Colors.transparent,
      builder: (context) => NetworkSelectorSheet(
        currentNetwork: currentNetwork,
        onNetworkSelected: (network) {
          Navigator.pop(context, network);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            // Title
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select Network',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Network options
            ...NetworkType.values.map((network) => _NetworkOption(
                  network: network,
                  isSelected: network == currentNetwork,
                  onTap: () => onNetworkSelected(network),
                )),
            const SizedBox(height: 16),
          ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        Text(
                          network.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!isMainnet) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TESTNET',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chain ID: ${network.chainId}',
                      style: const TextStyle(
                        fontSize: 13,
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
