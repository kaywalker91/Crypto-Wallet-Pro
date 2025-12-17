import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/nft.dart';

/// NFT grid item widget for gallery display
/// Shows NFT image, name, collection, and token type badge
class NftGridItem extends StatelessWidget {
  final Nft nft;
  final VoidCallback? onTap;

  const NftGridItem({
    super.key,
    required this.nft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NFT Image with Hero animation support
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Hero(
                    tag: 'nft_${nft.contractAddress}_${nft.tokenId}',
                    child: Container(
                      color: AppColors.surfaceLight,
                      child: nft.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: nft.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _buildLoadingPlaceholder(),
                              errorWidget: (context, url, error) => _buildErrorPlaceholder(),
                              fadeInDuration: const Duration(milliseconds: 300),
                            )
                          : _buildErrorPlaceholder(),
                    ),
                  ),
                  // Token type badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildTokenTypeBadge(),
                  ),
                  // ERC-1155 quantity badge
                  if (nft.type == NftType.erc1155 && (nft.balance ?? 1) > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _buildQuantityBadge(),
                    ),
                ],
              ),
            ),
            // NFT Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collection name
                  Text(
                    nft.collectionName.isNotEmpty
                        ? nft.collectionName
                        : 'Unknown Collection',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // NFT name
                  Text(
                    nft.title.isNotEmpty ? nft.title : '#${nft.tokenId}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenTypeBadge() {
    final isErc1155 = nft.type == NftType.erc1155;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isErc1155
            ? AppColors.secondary.withAlpha(230)
            : AppColors.primary.withAlpha(230),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isErc1155 ? 'ERC-1155' : 'ERC-721',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuantityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(179),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.layers_rounded,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            'x${nft.balance ?? 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textTertiary,
          size: 32,
        ),
      ),
    );
  }
}
