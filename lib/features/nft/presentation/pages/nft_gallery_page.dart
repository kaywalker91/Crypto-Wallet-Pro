import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../domain/entities/nft.dart';
import '../providers/nft_provider.dart';
import '../widgets/nft_empty_state.dart';
import '../widgets/nft_grid_item.dart';
import '../widgets/nft_loading_shimmer.dart';
import 'nft_detail_page.dart';

/// NFT Gallery page with grid view, filtering, and pull-to-refresh
class NftGalleryPage extends ConsumerWidget {
  const NftGalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nftState = ref.watch(nftProvider);
    final counts = ref.watch(nftCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            // Filter tabs
            _buildFilterTabs(context, ref, counts),
            // Content
            Expanded(
              child: _buildContent(context, ref, nftState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NFT Gallery',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Your digital collectibles',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          // Grid/List toggle button (for future use)
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.grid_view_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                // TODO: Toggle grid/list view
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(
    BuildContext context,
    WidgetRef ref,
    ({int total, int erc721, int erc1155}) counts,
  ) {
    final currentFilter = ref.watch(nftFilterProvider);

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
            isSelected: currentFilter == NftFilter.all,
            onTap: () => ref.read(nftProvider.notifier).setFilter(NftFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'ERC-721',
            count: counts.erc721,
            isSelected: currentFilter == NftFilter.erc721,
            color: AppColors.primary,
            onTap: () =>
                ref.read(nftProvider.notifier).setFilter(NftFilter.erc721),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'ERC-1155',
            count: counts.erc1155,
            isSelected: currentFilter == NftFilter.erc1155,
            color: AppColors.secondary,
            onTap: () =>
                ref.read(nftProvider.notifier).setFilter(NftFilter.erc1155),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, NftState state) {
    // Loading state
    if (state.isLoading) {
      return const NftLoadingShimmer();
    }

    // Error state
    if (state.error != null) {
      return NftErrorState(
        error: state.error,
        onRetry: () => ref.read(nftProvider.notifier).refresh(),
      );
    }

    // Empty state
    final filteredNfts = state.filteredNfts;
    if (filteredNfts.isEmpty) {
      return NftEmptyState(
        isFiltered: state.filter != NftFilter.all,
        actionLabel: state.filter != NftFilter.all ? 'Show All NFTs' : null,
        onAction: state.filter != NftFilter.all
            ? () => ref.read(nftProvider.notifier).setFilter(NftFilter.all)
            : null,
      );
    }

    // NFT Grid
    return RefreshIndicator(
      onRefresh: () => ref.read(nftProvider.notifier).refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: filteredNfts.length,
        itemBuilder: (context, index) {
          final nft = filteredNfts[index];
          return NftGridItem(
            nft: nft,
            onTap: () => _onNftTap(context, ref, nft),
          );
        },
      ),
    );
  }

  void _onNftTap(BuildContext context, WidgetRef ref, Nft nft) {
    ref.read(nftProvider.notifier).selectNft(nft);
    Navigator.push(
      context,
      HeroPageRoute(
        page: NftDetailPage(nft: nft),
      ),
    );
  }
}

/// Filter chip widget for NFT type filtering
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
              ? chipColor.withAlpha(51) // 0.2 * 255 = 51
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
                    ? chipColor.withAlpha(77) // 0.3 * 255 = 77
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
