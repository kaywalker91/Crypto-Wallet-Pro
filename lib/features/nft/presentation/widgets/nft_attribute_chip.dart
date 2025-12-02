import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/nft_attribute.dart';

/// NFT attribute chip widget for displaying trait info with rarity
class NftAttributeChip extends StatelessWidget {
  final NftAttribute attribute;
  final bool showRarity;

  const NftAttributeChip({
    super.key,
    required this.attribute,
    this.showRarity = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trait type label
          Text(
            attribute.traitType.toUpperCase(),
            style: TextStyle(
              color: _getAccentColor(),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          // Trait value
          Text(
            attribute.value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Rarity indicator
          if (showRarity && attribute.rarity != null) ...[
            const SizedBox(height: 8),
            _buildRarityIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildRarityIndicator() {
    final rarity = attribute.rarity!;

    return Row(
      children: [
        // Rarity bar
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (100 - rarity) / 100, // Inverse: lower % = rarer
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getRarityGradient(rarity),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Percentage text
        Text(
          '${rarity.toStringAsFixed(1)}%',
          style: TextStyle(
            color: _getRarityColor(rarity),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getBorderColor() {
    if (attribute.rarity == null) return AppColors.cardBorder;
    return _getRarityColor(attribute.rarity!).withAlpha(77); // 0.3 * 255
  }

  Color _getAccentColor() {
    if (attribute.rarity == null) return AppColors.textTertiary;
    return _getRarityColor(attribute.rarity!);
  }

  Color _getRarityColor(double rarity) {
    if (rarity <= 1) return AppColors.secondary; // Legendary (purple)
    if (rarity <= 5) return AppColors.secondaryLight; // Epic (pink)
    if (rarity <= 15) return AppColors.primary; // Rare (cyan)
    if (rarity <= 30) return AppColors.success; // Uncommon (green)
    return AppColors.textTertiary; // Common
  }

  List<Color> _getRarityGradient(double rarity) {
    if (rarity <= 1) {
      return [AppColors.secondary, AppColors.secondaryLight];
    }
    if (rarity <= 5) {
      return [AppColors.secondaryLight, AppColors.secondary];
    }
    if (rarity <= 15) {
      return [AppColors.primary, AppColors.primaryLight];
    }
    if (rarity <= 30) {
      return [AppColors.success, AppColors.primary];
    }
    return [AppColors.textTertiary, AppColors.textSecondary];
  }
}

/// Grid of NFT attributes
class NftAttributesGrid extends StatelessWidget {
  final List<NftAttribute> attributes;
  final int crossAxisCount;
  final bool showRarity;

  const NftAttributesGrid({
    super.key,
    required this.attributes,
    this.crossAxisCount = 2,
    this.showRarity = true,
  });

  @override
  Widget build(BuildContext context) {
    if (attributes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Properties',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Attributes grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: attributes.length,
          itemBuilder: (context, index) {
            return NftAttributeChip(
              attribute: attributes[index],
              showRarity: showRarity,
            );
          },
        ),
      ],
    );
  }
}
