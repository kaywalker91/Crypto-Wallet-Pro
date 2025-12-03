import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shimmer loading effect for session list items
class SessionLoadingShimmer extends StatefulWidget {
  final int itemCount;

  const SessionLoadingShimmer({
    super.key,
    this.itemCount = 4,
  });

  @override
  State<SessionLoadingShimmer> createState() => _SessionLoadingShimmerState();
}

class _SessionLoadingShimmerState extends State<SessionLoadingShimmer>
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
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 16),
          // Info placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name placeholder
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 16,
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
                    ),
                    const SizedBox(width: 16),
                    // Status placeholder
                    Container(
                      width: 50,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
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
                const SizedBox(height: 8),
                // Subtitle placeholder
                Container(
                  height: 12,
                  width: 150,
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
                const SizedBox(height: 12),
                // Methods placeholder
                Row(
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 60,
                      height: 20,
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
