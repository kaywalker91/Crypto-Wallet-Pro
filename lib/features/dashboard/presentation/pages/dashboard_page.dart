
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/network_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/action_buttons_row.dart';
import '../widgets/balance_card.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/token_list_tile.dart';

/// Main dashboard page showing wallet balance and tokens
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final selectedNetwork = ref.watch(selectedNetworkProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _NetworkSelector(
            network: selectedNetwork,
            onTap: () {
              _showNetworkSelectionBottomSheet(context, ref);
            },
          ),
        ),
        leadingWidth: 140,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: Open QR scanner
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance card
              BalanceCard(
                balance: dashboardState.walletBalance,
                isLoading: dashboardState.isLoading,
                onCopyAddress: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Address copied to clipboard'),
                      backgroundColor: AppColors.surface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Action buttons
              ActionButtonsRow(
                onSend: () => context.push(Routes.send),
                // TODO: Implement other actions
              ),

              const SizedBox(height: 32),

              // Assets header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assets',
                    style: AppTypography.textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all assets
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Error message
              if (dashboardState.error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dashboardState.error!,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Token list
              if (dashboardState.isLoading)
                const _TokenListSkeleton()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dashboardState.tokens.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final token = dashboardState.tokens[index];
                    return TokenListTile(
                      token: token,
                      onTap: () {
                        // TODO: Navigate to token details
                      },
                    );
                  },
                ),

              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  void _showNetworkSelectionBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Network', style: AppTypography.textTheme.titleLarge),
            const SizedBox(height: 24),
            _NetworkOption(
              name: 'Ethereum Mainnet',
              isSelected: ref.read(selectedNetworkProvider) == NetworkType.mainnet,
              onTap: () {
                ref.read(selectedNetworkProvider.notifier).setNetwork(NetworkType.mainnet);
                ref.read(dashboardProvider.notifier).refresh();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            _NetworkOption(
              name: 'Sepolia Testnet',
              isSelected: ref.read(selectedNetworkProvider) == NetworkType.sepolia,
              onTap: () {
                ref.read(selectedNetworkProvider.notifier).setNetwork(NetworkType.sepolia);
                ref.read(dashboardProvider.notifier).refresh();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkOption extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _NetworkOption({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: name.contains('Sepolia') ? AppColors.warning : AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Network selector chip
class _NetworkSelector extends StatelessWidget {
  final NetworkType network;
  final VoidCallback? onTap;

  const _NetworkSelector({
    required this.network,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSepolia = network == NetworkType.sepolia;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSepolia ? AppColors.warning : AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isSepolia ? 'Sepolia' : 'Mainnet',
              style: AppTypography.textTheme.labelMedium,
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading for token list
class _TokenListSkeleton extends StatelessWidget {
  const _TokenListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(12),
            ),
        ),
      ),
    );
  }
}
