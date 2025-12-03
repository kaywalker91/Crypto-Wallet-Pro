import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/page_transitions.dart';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'All',
            count: counts.total,
            isSelected: currentFilter == SessionFilter.all,
            onTap: () => ref.read(walletConnectProvider.notifier).setFilter(SessionFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Active',
            count: counts.active,
            isSelected: currentFilter == SessionFilter.active,
            color: AppColors.success,
            onTap: () => ref.read(walletConnectProvider.notifier).setFilter(SessionFilter.active),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pending',
            count: counts.pending,
            isSelected: currentFilter == SessionFilter.pending,
            color: AppColors.warning,
            onTap: () => ref.read(walletConnectProvider.notifier).setFilter(SessionFilter.pending),
          ),
        ],
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

    // Empty state
    final filteredSessions = state.filteredSessions;
    if (filteredSessions.isEmpty) {
      return SessionEmptyState(
        isFiltered: state.filter != SessionFilter.all,
        actionLabel: state.filter == SessionFilter.all ? 'Scan QR Code' : 'Show All',
        onAction: () {
          if (state.filter == SessionFilter.all) {
            _openQrScanner(context, ref);
          } else {
            ref.read(walletConnectProvider.notifier).setFilter(SessionFilter.all);
          }
        },
      );
    }

    // Sessions list
    return RefreshIndicator(
      onRefresh: () => ref.read(walletConnectProvider.notifier).refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: filteredSessions.length,
        itemBuilder: (context, index) {
          final session = filteredSessions[index];
          return SessionListItem(
            session: session,
            onTap: () => _onSessionTap(context, ref, session),
          );
        },
      ),
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
