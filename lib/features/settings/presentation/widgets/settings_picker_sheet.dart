import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';

/// A reusable bottom sheet for selecting from a list of options
/// Used for auto-lock duration, currency, and other pickers in settings
class SettingsPickerSheet<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<T> options;
  final T currentValue;
  final String Function(T option) getDisplayName;
  final Widget Function(T option)? getLeading;
  final ValueChanged<T> onSelected;

  const SettingsPickerSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.currentValue,
    required this.getDisplayName,
    this.getLeading,
    required this.onSelected,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required List<T> options,
    required T currentValue,
    required String Function(T option) getDisplayName,
    Widget Function(T option)? getLeading,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sheetMaxWidth),
          child: SettingsPickerSheet<T>(
            title: title,
            subtitle: subtitle,
            options: options,
            currentValue: currentValue,
            getDisplayName: getDisplayName,
            getLeading: getLeading,
            onSelected: (value) => Navigator.pop(context, value),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title section
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Options list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 20),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == currentValue;
                    return _OptionTile<T>(
                      option: option,
                      displayName: getDisplayName(option),
                      leading: getLeading?.call(option),
                      isSelected: isSelected,
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  final T option;
  final String displayName;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.displayName,
    this.leading,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  displayName,
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
