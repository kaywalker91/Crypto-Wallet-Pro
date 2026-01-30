import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../external_wallet/domain/entities/metamask_connection_status.dart';
import '../../../external_wallet/presentation/providers/metamask_provider.dart';
import '../../domain/entities/wallet_session.dart';
import '../providers/wallet_connect_provider.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/session_empty_state.dart';
import '../widgets/session_list_item.dart';
import '../widgets/session_loading_shimmer.dart';
import '../widgets/sign_request_sheet.dart';
import 'qr_scanner_page.dart';
import 'session_detail_page.dart';

/// Simplified WalletConnect sessions page
class WalletConnectPage extends ConsumerWidget {
  const WalletConnectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletConnectProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildContent(context, ref, state),
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

    final metaMaskState = ref.watch(metaMaskNotifierProvider);
    final sessions = state.sessions;

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
              16,
              context.horizontalPadding,
              32,
            ),
            children: [
              // Header
              _buildHeader(context, ref, state),

              const SizedBox(height: 20),

              // Quick Actions Row
              _buildQuickActions(context, ref, metaMaskState),

              const SizedBox(height: 24),

              // Sessions Section
              _buildSessionsSection(context, ref, sessions, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, WalletConnectState state) {
    return Row(
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
                  GestureDetector(
                    onTap: () => _showPendingRequests(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${state.pendingRequestCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'dApp connections & wallets',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, MetaMaskState metaMaskState) {
    final isConnected = metaMaskState.status == MetaMaskConnectionStatus.connected;
    final address = metaMaskState.connection?.abbreviatedAddress;

    return Column(
      children: [
        // Scan QR Action Card
        QuickActionCard(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan QR Code',
          subtitle: 'Connect to a dApp',
          iconColor: AppColors.primary,
          onTap: () => _openQrScanner(context, ref),
        ),

        const SizedBox(height: 12),

        // MetaMask Action Card
        MetaMaskActionCard(
          isConnected: isConnected,
          connectedAddress: address,
          onTap: () {
            if (!isConnected) {
              ref.read(metaMaskNotifierProvider.notifier).connect(chainId: 1);
            }
          },
          onDisconnect: isConnected
              ? () => ref.read(metaMaskNotifierProvider.notifier).disconnect()
              : null,
        ),
      ],
    );
  }

  Widget _buildSessionsSection(
    BuildContext context,
    WidgetRef ref,
    List<WalletSession> sessions,
    WalletConnectState state,
  ) {
    // Section header with count
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Sessions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (sessions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sessions.length}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Sessions list or empty state
        if (sessions.isEmpty)
          const SessionEmptyState()
        else
          ...sessions.map((session) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SessionListItem(
                  session: session,
                  onTap: () => _onSessionTap(context, ref, session),
                ),
              )),
      ],
    );
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
