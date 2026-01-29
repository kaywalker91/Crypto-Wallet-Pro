import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/network_selector_sheet.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

/// Main settings page with all setting categories
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.settings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    // App version badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Network Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'Network',
                children: [
                  SettingsValueTile(
                    icon: Icons.language,
                    iconColor: AppColors.ethColor,
                    title: 'Blockchain Network',
                    value: settings.selectedNetwork.displayName,
                    onTap: () => _showNetworkSelector(context, ref, settings),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Security Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'Security',
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final hasPin = ref.watch(hasPinProvider).maybeWhen(
                            data: (value) => value,
                            orElse: () => false,
                          );
                      if (hasPin) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'PIN이 설정되어 있지 않습니다. 생체인증 실패 시 접근을 막으려면 PIN을 설정하세요.',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(Routes.pinSetup),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryLight,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              child: const Text('설정'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SettingsToggleTile(
                    icon: Icons.fingerprint,
                    iconColor: AppColors.success,
                    title: 'Biometric Authentication',
                    subtitle: 'Use Face ID or fingerprint',
                    value: settings.biometricEnabled,
                    isLoading: settingsState.isLoading,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleBiometric(value);
                    },
                  ),
                  SettingsToggleTile(
                    icon: Icons.pin,
                    iconColor: AppColors.info,
                    title: 'PIN Lock',
                    subtitle: '6-digit PIN code',
                    value: settings.pinEnabled,
                    isLoading: settingsState.isLoading,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).togglePin(value);
                    },
                  ),
                  SettingsValueTile(
                    icon: Icons.lock,
                    iconColor: AppColors.primary,
                    title: 'Set / Reset PIN',
                    value: 'Open setup',
                    onTap: () => context.push(Routes.pinSetup),
                  ),
                  SettingsValueTile(
                    icon: Icons.timer_outlined,
                    iconColor: AppColors.warning,
                    title: 'Auto-Lock',
                    value: settings.autoLockDuration.displayName,
                    onTap: () => _showAutoLockPicker(context, ref, settings),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Wallet Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'Wallet',
                children: [
                  SettingsTile(
                    icon: Icons.key,
                    iconColor: AppColors.secondary,
                    title: 'Recovery Phrase',
                    subtitle: 'View your 12-word seed phrase',
                    onTap: () => _showRecoveryPhraseWarning(context),
                  ),
                  SettingsTile(
                    icon: Icons.link,
                    iconColor: AppColors.primary,
                    title: 'Connected Apps',
                    subtitle: 'Manage WalletConnect sessions',
                    onTap: () {
                      // TODO: Navigate to connected apps page
                      _showComingSoon(context, 'Connected Apps');
                    },
                  ),
                  SettingsTile(
                    icon: Icons.delete_outline,
                    title: 'Delete Wallet',
                    subtitle: 'Remove wallet from this device',
                    isDestructive: true,
                    onTap: () => _showDeleteWalletConfirmation(context, ref),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Preferences Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'Preferences',
                children: [
                  SettingsValueTile(
                    icon: Icons.attach_money,
                    iconColor: AppColors.success,
                    title: 'Currency',
                    value: settings.displayCurrency.code,
                    onTap: () => _showCurrencyPicker(context, ref, settings),
                  ),
                  SettingsToggleTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.warning,
                    title: 'Notifications',
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .toggleNotifications(value);
                    },
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // About Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'About',
                children: [
                  SettingsTile(
                    icon: Icons.info_outline,
                    iconColor: AppColors.info,
                    title: 'About Crypto Wallet Pro',
                    onTap: () {
                      _showComingSoon(context, 'About');
                    },
                  ),
                  SettingsTile(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.textTertiary,
                    title: 'Terms of Service',
                    onTap: () {
                      _showComingSoon(context, 'Terms of Service');
                    },
                  ),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppColors.textTertiary,
                    title: 'Privacy Policy',
                    onTap: () {
                      _showComingSoon(context, 'Privacy Policy');
                    },
                  ),
                  SettingsTile(
                    icon: Icons.code,
                    iconColor: AppColors.textTertiary,
                    title: 'Open Source Licenses',
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Crypto Wallet Pro',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Footer
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      Text(
                        'Crypto Wallet Pro',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Made with ❤️ for learning',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNetworkSelector(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final selectedNetwork = await NetworkSelectorSheet.show(
      context,
      currentNetwork: settings.selectedNetwork,
    );

    if (selectedNetwork != null &&
        selectedNetwork != settings.selectedNetwork) {
      ref.read(settingsProvider.notifier).updateNetwork(selectedNetwork);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${selectedNetwork.displayName}'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showAutoLockPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sheetMaxWidth),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.horizontalPadding,
                      16,
                      context.horizontalPadding,
                      8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Auto-Lock Timer',
                          style: AppTypography.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: AutoLockDuration.values.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.cardBorder),
                      itemBuilder: (context, index) {
                        final duration = AutoLockDuration.values[index];
                        final isSelected = duration == settings.autoLockDuration;
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.horizontalPadding,
                          ),
                          title: Text(
                            duration.displayName,
                            style: AppTypography.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          selected: isSelected,
                          selectedTileColor: AppColors.surfaceLight,
                          onTap: () {
                            ref
                                .read(settingsProvider.notifier)
                                .updateAutoLockDuration(duration);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sheetMaxWidth),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.horizontalPadding,
                      16,
                      context.horizontalPadding,
                      8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Display Currency',
                          style: AppTypography.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: CurrencyType.values.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.cardBorder),
                      itemBuilder: (context, index) {
                        final currency = CurrencyType.values[index];
                        final isSelected = currency == settings.displayCurrency;
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.horizontalPadding,
                          ),
                          leading: Text(
                            currency.symbol,
                            style: AppTypography.textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          title: Text(
                            currency.code,
                            style: AppTypography.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          selected: isSelected,
                          selectedTileColor: AppColors.surfaceLight,
                          onTap: () {
                            ref
                                .read(settingsProvider.notifier)
                                .updateCurrency(currency);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRecoveryPhraseWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning, size: 28),
            SizedBox(width: 12),
            Text(
              'Security Warning',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Your recovery phrase is the only way to restore your wallet. Never share it with anyone.\n\nMake sure no one is watching your screen.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to recovery phrase page
              _showComingSoon(context, 'Recovery Phrase');
            },
            child: const Text('View Phrase'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteWallet(BuildContext context, WidgetRef ref) async {
    await ref.read(walletProvider.notifier).deleteWallet();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final error = ref.read(walletViewProvider).error;
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Wallet deleted from this device'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    context.go(Routes.onboarding);
  }

  void _showDeleteWalletConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text(
              'Delete Wallet',
              style: TextStyle(color: AppColors.error),
            ),
          ],
        ),
        content: const Text(
          'This action cannot be undone. Your wallet will be permanently removed from this device.\n\nMake sure you have backed up your recovery phrase before proceeding.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleDeleteWallet(context, ref);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return AppColors.surfaceLight;
                }
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.error.withValues(alpha: 0.9);
                }
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.error.withValues(alpha: 0.8);
                }
                return AppColors.error;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return AppColors.textDisabled;
                }
                return Colors.white;
              }),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withValues(alpha: 0.16);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return Colors.white.withValues(alpha: 0.1);
                }
                return null;
              }),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
