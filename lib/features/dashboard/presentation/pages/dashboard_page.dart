
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/providers/network_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/action_buttons_row.dart';
import '../widgets/balance_card.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/token_list_tile.dart';

import '../../../../features/wallet_connect/presentation/providers/wallet_connect_provider.dart';

/// Main dashboard page showing wallet balance and tokens
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Initialize WalletConnect service when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletConnectProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.history),
            onPressed: () => context.push(Routes.history),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push(Routes.qrScanner),
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
                onReceive: () => context.push(Routes.receive),
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
                    color: AppColors.error.withValues(alpha: 0.1),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
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
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sheetMaxWidth),
          child: _NetworkSelectionSheet(
            currentNetwork: ref.read(selectedNetworkProvider),
            onSelected: (network) {
              ref.read(selectedNetworkProvider.notifier).setNetwork(network);
              ref.read(dashboardProvider.notifier).refresh();
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}

class _NetworkSelectionSheet extends StatelessWidget {
  final NetworkType currentNetwork;
  final ValueChanged<NetworkType> onSelected;

  const _NetworkSelectionSheet({
    required this.currentNetwork,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

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
                    Text('Select Network', style: AppTypography.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Pick the chain for balances and activity.',
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
                  children: NetworkType.values
                      .map((network) => _NetworkOption(
                            network: network,
                            isSelected: network == currentNetwork,
                            onTap: () => onSelected(network),
                          ))
                      .toList(),
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
                          'Changing networks may refresh balances.',
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
                child: const Icon(Icons.language, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
            ],
          ),
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
