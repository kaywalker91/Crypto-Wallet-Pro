import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A single settings item tile with improved visual design
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isDestructive;
  final bool useGradientIcon;

  const SettingsTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.isDestructive = false,
    this.useGradientIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isDestructive
        ? AppColors.error
        : iconColor ?? AppColors.primary;
    final effectiveTitleColor = isDestructive
        ? AppColors.error
        : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: effectiveIconColor.withValues(alpha: 0.1),
        highlightColor: effectiveIconColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon container with optional gradient
              _IconContainer(
                icon: icon,
                color: effectiveIconColor,
                useGradient: useGradientIcon,
                isDestructive: isDestructive,
              ),
              const SizedBox(width: 14),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: effectiveTitleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing widget or chevron
              if (trailing != null)
                trailing!
              else if (showChevron && onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon container with gradient or solid background
class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool useGradient;
  final bool isDestructive;

  const _IconContainer({
    required this.icon,
    required this.color,
    required this.useGradient,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: useGradient && !isDestructive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withValues(alpha: 0.7),
                ],
              )
            : null,
        color: useGradient ? null : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        boxShadow: useGradient && !isDestructive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 20,
        color: useGradient ? Colors.white : color,
      ),
    );
  }
}


/// A settings tile with a toggle switch
class SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isLoading;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      showChevron: false,
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.textTertiary;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary.withValues(alpha: 0.4);
                }
                return AppColors.cardBorder;
              }),
            ),
      onTap: onChanged != null && !isLoading
          ? () => onChanged!(!value)
          : null,
    );
  }
}

/// A settings tile showing a selected value with chip-style display
class SettingsValueTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const SettingsValueTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      showChevron: false,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chip-style value display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.cardBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
