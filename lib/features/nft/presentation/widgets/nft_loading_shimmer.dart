import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shimmer loading effect for NFT grid items
class NftLoadingShimmer extends StatefulWidget {
  final int itemCount;
  final int crossAxisCount;

  const NftLoadingShimmer({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  State<NftLoadingShimmer> createState() => _NftLoadingShimmerState();
}

class _NftLoadingShimmerState extends State<NftLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return _ShimmerItem(animationValue: _animation.value);
          },
        );
      },
    );
  }
}

class _ShimmerItem extends StatelessWidget {
  final double animationValue;

  const _ShimmerItem({required this.animationValue});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Image placeholder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(animationValue - 1, 0),
                  end: Alignment(animationValue + 1, 0),
                  colors: const [
                    AppColors.surfaceLight,
                    AppColors.surface,
                    AppColors.surfaceLight,
                  ],
                ),
              ),
            ),
          ),
          // Info placeholder
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collection name placeholder
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment(animationValue - 1, 0),
                      end: Alignment(animationValue + 1, 0),
                      colors: const [
                        AppColors.surfaceLight,
                        AppColors.surface,
                        AppColors.surfaceLight,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // NFT name placeholder
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment(animationValue - 1, 0),
                      end: Alignment(animationValue + 1, 0),
                      colors: const [
                        AppColors.surfaceLight,
                        AppColors.surface,
                        AppColors.surfaceLight,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
