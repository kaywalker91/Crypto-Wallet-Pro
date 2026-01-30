import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';

import '../widgets/settings_header.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_picker_sheet.dart';

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
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Enhanced Header
            const SliverToBoxAdapter(
              child: SettingsHeader(),
            ),

            // Network Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'Network',
                icon: Icons.language,
                iconColor: AppColors.ethColor,
                children: [
                  SettingsValueTile(
                    icon: Icons.hub_rounded,
                    iconColor: AppColors.ethColor,
                    title: 'Blockchain Network',
                    value: settings.selectedNetwork.displayName,
                    onTap: () => _showNetworkSelector(context, ref, settings),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Wallet Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'Wallet Management',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.primary,
                children: [
                  SettingsTile(
                    icon: Icons.key_rounded,
                    iconColor: AppColors.secondary,
                    title: 'Recovery Phrase',
                    subtitle: 'View your 12-word seed phrase',
                    onTap: () => _showRecoveryPhraseWarning(context),
                  ),
                  SettingsTile(
                    icon: Icons.link_rounded,
                    iconColor: AppColors.info,
                    title: 'Connected Apps',
                    subtitle: 'Manage WalletConnect sessions',
                    onTap: () {
                      _showComingSoon(context, 'Connected Apps');
                    },
                  ),
                  SettingsTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete Wallet',
                    subtitle: 'Remove wallet from this device',
                    isDestructive: true,
                    onTap: () => _showDeleteWalletConfirmation(context, ref),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Security Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'Security',
                icon: Icons.security_rounded,
                iconColor: AppColors.success,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final hasPin = ref.watch(hasPinProvider).maybeWhen(
                            data: (value) => value,
                            orElse: () => false,
                          );
                      if (hasPin) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
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
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Security Alert: PIN is not set.\nSecure your wallet now.',
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                ),
                                child: const Text('Setup'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SettingsToggleTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.success,
                    title: 'Biometric Login',
                    subtitle: 'Use Face ID or fingerprint',
                    value: settings.biometricEnabled,
                    isLoading: settingsState.isLoading,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .toggleBiometric(value);
                    },
                  ),
                  SettingsToggleTile(
                    icon: Icons.lock_rounded,
                    iconColor: AppColors.info,
                    title: 'PIN Lock',
                    subtitle: 'Require PIN for access',
                    value: settings.pinEnabled,
                    isLoading: settingsState.isLoading,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).togglePin(value);
                    },
                  ),
                  if (settings.pinEnabled)
                    SettingsValueTile(
                      icon: Icons.password_rounded,
                      iconColor: AppColors.primary,
                      title: 'Change PIN',
                      value: 'Manage',
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

            // Preferences Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'Preferences',
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFFEAB308),
                children: [
                  SettingsValueTile(
                    icon: Icons.attach_money_rounded,
                    iconColor: AppColors.success,
                    title: 'Currency',
                    value:
                        '${settings.displayCurrency.code} (${settings.displayCurrency.symbol})',
                    onTap: () => _showCurrencyPicker(context, ref, settings),
                  ),
                  SettingsValueTile(
                      icon: Icons.translate_rounded,
                      iconColor: Colors.purpleAccent,
                      title: 'Language',
                      value: 'English',
                      onTap: () {
                        _showComingSoon(context, 'Language Selection');
                      }),
                  SettingsToggleTile(
                    icon: Icons.notifications_none_rounded,
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

            // Support Section (New)
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'Support',
                icon: Icons.help_outline_rounded,
                iconColor: Colors.tealAccent,
                children: [
                  SettingsTile(
                    icon: Icons.question_answer_outlined,
                    iconColor: Colors.tealAccent,
                    title: 'Help Center',
                    onTap: () => _showComingSoon(context, 'Help Center'),
                  ),
                  SettingsTile(
                    icon: Icons.rate_review_outlined,
                    iconColor: Colors.amberAccent,
                    title: 'Rate App',
                    onTap: () => _showComingSoon(context, 'Rate App'),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // About Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'About',
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textTertiary,
                children: [
                  SettingsTile(
                    icon: Icons.info_rounded,
                    iconColor: AppColors.primary,
                    title: 'About Crypto Wallet Pro',
                    onTap: () => context.push(Routes.about),
                  ),
                  SettingsTile(
                    icon: Icons.policy_outlined,
                    iconColor: AppColors.textTertiary,
                    title: 'Terms & Privacy',
                    onTap: () {
                      _showComingSoon(context, 'Terms & Privacy');
                    },
                  ),
                  SettingsTile(
                    icon: Icons.code_rounded,
                    iconColor: AppColors.textTertiary,
                    title: 'Open Source Licenses',
                    onTap: () => context.push(Routes.licenses),
                  ),
                ],
              ),
            ),

            // Footer
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Crypto Wallet Pro',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'v1.0.0 (Build 100)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
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
    final selectedNetwork = await SettingsPickerSheet.show<NetworkType>(
      context: context,
      title: 'Select Network',
      options: NetworkType.values,
      currentValue: settings.selectedNetwork,
      getDisplayName: (network) => network.displayName,
    );

    if (selectedNetwork != null) {
      ref.read(settingsProvider.notifier).updateNetwork(selectedNetwork);
    }
  }

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final selectedCurrency = await SettingsPickerSheet.show<CurrencyType>(
      context: context,
      title: 'Select Currency',
      options: CurrencyType.values,
      currentValue: settings.displayCurrency,
      getDisplayName: (currency) => '${currency.code} (${currency.symbol})',
    );

    if (selectedCurrency != null) {
      ref.read(settingsProvider.notifier).updateCurrency(selectedCurrency);
    }
  }

  void _showAutoLockPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final selectedDuration = await SettingsPickerSheet.show<AutoLockDuration>(
      context: context,
      title: 'Auto-Lock Timer',
      options: AutoLockDuration.values,
      currentValue: settings.autoLockDuration,
      getDisplayName: (duration) => duration.displayName,
    );

    if (selectedDuration != null) {
      ref
          .read(settingsProvider.notifier)
          .updateAutoLockDuration(selectedDuration);
    }
  }

  void _showRecoveryPhraseWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('View Recovery Phrase',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Your recovery phrase is the ONLY way to recover your funds. Never share it with anyone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to recovery phrase display (with PIN check)
              _showComingSoon(context, 'View Recovery Phrase');
            },
            child:
                const Text('View', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteWalletConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Wallet?',
            style: TextStyle(color: AppColors.error)),
        content: const Text(
          'This action cannot be undone. You will lose access to your funds if you don\'t have your recovery phrase saved.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(walletProvider.notifier).deleteWallet();
              context.go(Routes.onboarding);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppColors.cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
