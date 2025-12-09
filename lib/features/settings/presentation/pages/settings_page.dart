import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
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
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
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
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Auto-Lock Timer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...AutoLockDuration.values.map((duration) => ListTile(
                  title: Text(
                    duration.displayName,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  trailing: duration == settings.autoLockDuration
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .updateAutoLockDuration(duration);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
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
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Display Currency',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...CurrencyType.values.map((currency) => ListTile(
                  leading: Text(
                    currency.symbol,
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: Text(
                    currency.code,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  trailing: currency == settings.displayCurrency
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .updateCurrency(currency);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to recovery phrase page
              _showComingSoon(context, 'Recovery Phrase');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View Phrase'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteWallet(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(walletProvider.notifier).deleteWallet();

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
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleDeleteWallet(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
