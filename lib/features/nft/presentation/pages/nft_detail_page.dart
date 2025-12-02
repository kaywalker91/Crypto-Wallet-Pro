import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/nft.dart';
import '../widgets/nft_attribute_chip.dart';

/// NFT detail page with Hero animation and full NFT info
class NftDetailPage extends StatelessWidget {
  final Nft nft;

  const NftDetailPage({
    super.key,
    required this.nft,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Sliver app bar with Hero image
          _buildSliverAppBar(context),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Token type and quantity badges
                  _buildBadges(),
                  const SizedBox(height: 16),
                  // Collection name
                  _buildCollectionName(),
                  const SizedBox(height: 8),
                  // NFT name
                  _buildNftName(),
                  // Description
                  if (nft.description != null && nft.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDescription(),
                  ],
                  const SizedBox(height: 24),
                  // Attributes
                  NftAttributesGrid(attributes: nft.attributes),
                  const SizedBox(height: 24),
                  // Contract info
                  _buildContractInfo(context),
                  const SizedBox(height: 24),
                  // Action buttons
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.width,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: _buildBackButton(context),
      actions: [
        _buildMenuButton(context),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'nft_${nft.contractAddress}_${nft.tokenId}',
          child: Container(
            decoration: BoxDecoration(
              color: nft.backgroundColor != null
                  ? Color(
                      int.parse(
                            nft.backgroundColor!.replaceFirst('#', ''),
                            radix: 16,
                          ) |
                          0xFF000000,
                    )
                  : AppColors.surfaceLight,
            ),
            child: nft.imageUrl.isNotEmpty
                ? Image.network(
                    nft.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128), // 0.5 * 255
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128), // 0.5 * 255
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showOptionsSheet(context),
        ),
      ),
    );
  }

  Widget _buildBadges() {
    return Row(
      children: [
        // Token type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: nft.isErc1155
                ? AppColors.secondary.withAlpha(51) // 0.2 * 255
                : AppColors.primary.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: nft.isErc1155 ? AppColors.secondary : AppColors.primary,
            ),
          ),
          child: Text(
            nft.isErc1155 ? 'ERC-1155' : 'ERC-721',
            style: TextStyle(
              color: nft.isErc1155 ? AppColors.secondary : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Quantity badge for ERC-1155
        if (nft.isErc1155 && nft.quantity > 1) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.layers_rounded,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Owned: ${nft.quantity}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCollectionName() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to collection page
      },
      child: Row(
        children: [
          // Collection icon/avatar placeholder
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(51), // 0.2 * 255
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.collections_outlined,
              color: AppColors.primary,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nft.collectionName.isNotEmpty
                  ? nft.collectionName
                  : 'Unknown Collection',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.primary,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildNftName() {
    return Text(
      nft.name.isNotEmpty ? nft.name : '#${nft.tokenId}',
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nft.description!,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildContractInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Contract Address',
            _shortenAddress(nft.contractAddress),
            fullValue: nft.contractAddress,
            canCopy: true,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            'Token ID',
            nft.tokenId.length > 10
                ? '${nft.tokenId.substring(0, 10)}...'
                : nft.tokenId,
            fullValue: nft.tokenId,
            canCopy: true,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            'Token Standard',
            nft.isErc1155 ? 'ERC-1155' : 'ERC-721',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            'Blockchain',
            'Ethereum',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    String? fullValue,
    bool canCopy = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: canCopy
              ? () {
                  Clipboard.setData(ClipboardData(text: fullValue ?? value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied'),
                      backgroundColor: AppColors.surface,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: canCopy ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.copy,
                  color: AppColors.primary,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action: View on OpenSea (if external URL exists)
        if (nft.externalUrl != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Launch URL
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('View on OpenSea'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Secondary actions row
        Row(
          children: [
            // Send NFT button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to send NFT
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Share button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Share NFT
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Options
              _buildOptionTile(
                context,
                icon: Icons.refresh,
                title: 'Refresh Metadata',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Refresh metadata
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.visibility_off_outlined,
                title: 'Hide NFT',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Hide NFT
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.report_outlined,
                title: 'Report',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Report
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  String _shortenAddress(String address) {
    if (address.length <= 13) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textTertiary,
              size: 64,
            ),
            SizedBox(height: 12),
            Text(
              'Image not available',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
