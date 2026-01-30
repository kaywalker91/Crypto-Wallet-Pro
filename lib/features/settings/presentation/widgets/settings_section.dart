import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';

/// A section container for grouping related settings
/// Features improved visual design with optional section icon
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final Color? iconColor;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with optional icon
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppColors.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      icon,
                      size: 12,
                      color: iconColor ?? AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: icon != null
                        ? (iconColor ?? AppColors.primary).withValues(alpha: 0.9)
                        : AppColors.textTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Section content container
          GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 16,
            child: Column(
              children: _buildChildrenWithDividers(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers() {
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      // Skip empty widgets (like SizedBox.shrink())
      if (children[i] is SizedBox && (children[i] as SizedBox).width == 0 && (children[i] as SizedBox).height == 0) {
        continue;
      }
      result.add(children[i]);
      if (i < children.length - 1) {
        // Check if next item is also not empty
        final nextIndex = i + 1;
        if (nextIndex < children.length) {
          final next = children[nextIndex];
          if (next is! SizedBox || (next.width != 0 || next.height != 0)) {
            result.add(
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.cardBorder,
                indent: 56,
              ),
            );
          }
        }
      }
    }
    return result;
  }
}
