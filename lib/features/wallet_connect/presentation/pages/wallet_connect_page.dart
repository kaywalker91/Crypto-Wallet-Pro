import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../../external_wallet/domain/entities/metamask_connection_status.dart';
import '../../../external_wallet/presentation/providers/metamask_provider.dart';
import '../../../external_wallet/presentation/widgets/metamask_connect_button.dart';
import '../../../external_wallet/presentation/widgets/metamask_status_indicator.dart';
import '../../domain/entities/wallet_session.dart';
import '../providers/wallet_connect_provider.dart';
import '../widgets/session_empty_state.dart';
import '../widgets/session_list_item.dart';
import '../widgets/session_loading_shimmer.dart';
import '../widgets/sign_request_sheet.dart';
import 'qr_scanner_page.dart';
import 'session_detail_page.dart';

/// WalletConnect sessions list page
class WalletConnectPage extends ConsumerWidget {
  const WalletConnectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletConnectProvider);
    final counts = ref.watch(sessionCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, ref, state),
            // Filter tabs
            _buildFilterTabs(context, ref, counts),
            // Content
            Expanded(
              child: _buildContent(context, ref, state),
            ),
          ],
        ),
      ),
      // FAB for QR Scanner
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQrScanner(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text(
          'Scan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, WalletConnectState state) {
    return ResponsiveContent(
      padding: EdgeInsets.fromLTRB(context.horizontalPadding, 16, context.horizontalPadding, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Connect',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Pending requests badge
                  if (state.hasPendingRequests) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.pendingRequestCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your dApp connections',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          // Pending requests button
          if (state.hasPendingRequests)
            Container(
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withAlpha(77)),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.secondary,
                ),
                onPressed: () => _showPendingRequests(context, ref),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(
    BuildContext context,
    WidgetRef ref,
    ({int total, int active, int pending}) counts,
  ) {
    final currentFilter = ref.watch(sessionFilterProvider);
    final chips = [
      _FilterChip(
        label: 'All',
        count: counts.total,
        isSelected: currentFilter == SessionFilter.all,
        onTap: () => ref.read(walletConnectProvider.notifier).setFilter(SessionFilter.all),
      ),
      _FilterChip(
        label: 'Active',
        count: counts.active,
        isSelected: currentFilter == SessionFilter.active,
        color: AppColors.success,
        onTap: () => ref.read(walletConnectProvider.notifier).setFilter(SessionFilter.active),
      ),
      _FilterChip(
        label: 'Pending',
        count: counts.pending,
        isSelected: currentFilter == SessionFilter.pending,
        color: AppColors.warning,
        onTap: () => ref.read(walletConnectProvider.notifier).setFilter(SessionFilter.pending),
      ),
    ];

    if (context.isCompact) {
      return ResponsiveContent(
        padding: EdgeInsets.fromLTRB(context.horizontalPadding, 4, context.horizontalPadding, 12),
        child: SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => chips[index],
          ),
        ),
      );
    }

    return ResponsiveContent(
      padding: EdgeInsets.fromLTRB(context.horizontalPadding, 4, context.horizontalPadding, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WalletConnectState state) {
    // Loading state
    if (state.isLoading) {
      return const SessionLoadingShimmer();
    }

    // Error state
    if (state.error != null) {
      return SessionErrorState(
        error: state.error,
        onRetry: () => ref.read(walletConnectProvider.notifier).refresh(),
      );
    }

    final filteredSessions = state.filteredSessions;

    return RefreshIndicator(
      onRefresh: () => ref.read(walletConnectProvider.notifier).refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.maxContentWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              8,
              context.horizontalPadding,
              120,
            ),
            children: [
              // MetaMask Connection Section
              _buildMetaMaskSection(context, ref),

              const SizedBox(height: 16),

              // Divider with label
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'dApp Sessions',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.cardBorder)),
                ],
              ),

              const SizedBox(height: 12),

              // Sessions list or empty state
              if (filteredSessions.isEmpty)
                SessionEmptyState(
                  isFiltered: state.filter != SessionFilter.all,
                  actionLabel: state.filter == SessionFilter.all ? 'Scan QR Code' : 'Show All',
                  onAction: () {
                    if (state.filter == SessionFilter.all) {
                      _openQrScanner(context, ref);
                    } else {
                      ref.read(walletConnectProvider.notifier).setFilter(SessionFilter.all);
                    }
                  },
                )
              else
                ...filteredSessions.map((session) => SessionListItem(
                      session: session,
                      onTap: () => _onSessionTap(context, ref, session),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaMaskSection(BuildContext context, WidgetRef ref) {
    final metaMaskState = ref.watch(metaMaskNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade900.withValues(alpha: 0.3),
            Colors.orange.shade800.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // MetaMask icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MetaMask',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Connect your external wallet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                const MetaMaskStatusIndicator(showAddress: false, size: 10),
              ],
            ),

            const SizedBox(height: 16),

            // Connection content based on state
            if (metaMaskState.status == MetaMaskConnectionStatus.connected &&
                metaMaskState.connection != null)
              _buildConnectedContent(context, ref, metaMaskState)
            else
              _buildDisconnectedContent(context, ref, metaMaskState),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedContent(BuildContext context, WidgetRef ref, MetaMaskState state) {
    final connection = state.connection!;

    return Column(
      children: [
        // Connected wallet info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Chain icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Address and chain
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.abbreviatedAddress,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _chainName(connection.chainId),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Disconnect button
              TextButton(
                onPressed: () => ref.read(metaMaskNotifierProvider.notifier).disconnect(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisconnectedContent(BuildContext context, WidgetRef ref, MetaMaskState state) {
    return Column(
      children: [
        // Error message if any
        if (state.status == MetaMaskConnectionStatus.error && state.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Connect button
        SizedBox(
          width: double.infinity,
          child: MetaMaskConnectButton(
            chainId: 1,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onConnected: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Successfully connected to MetaMask!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            onError: (error) {
              // Error is displayed in the card
            },
          ),
        ),
      ],
    );
  }

  String _chainName(int chainId) {
    switch (chainId) {
      case 1:
        return 'Ethereum Mainnet';
      case 5:
        return 'Goerli Testnet';
      case 11155111:
        return 'Sepolia Testnet';
      case 137:
        return 'Polygon';
      case 42161:
        return 'Arbitrum One';
      case 10:
        return 'Optimism';
      case 8453:
        return 'Base';
      case 56:
        return 'BNB Chain';
      default:
        return 'Chain $chainId';
    }
  }

  void _onSessionTap(BuildContext context, WidgetRef ref, WalletSession session) {
    ref.read(walletConnectProvider.notifier).selectSession(session);
    Navigator.push(
      context,
      HeroPageRoute(
        page: SessionDetailPage(session: session),
      ),
    );
  }

  void _openQrScanner(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerPage(),
      ),
    );
  }

  void _showPendingRequests(BuildContext context, WidgetRef ref) {
    final requests = ref.read(pendingRequestsProvider);
    if (requests.isEmpty) return;

    // Show the first pending request
    SignRequestSheet.show(context, request: requests.first).then((approved) {
      if (approved == true) {
        ref.read(walletConnectProvider.notifier).approveRequest(requests.first.id);
      } else if (approved == false) {
        ref.read(walletConnectProvider.notifier).rejectRequest(requests.first.id);
      }
    });
  }
}

/// Filter chip widget for session filtering
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withAlpha(51)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? chipColor : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? chipColor.withAlpha(77)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? chipColor : AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
