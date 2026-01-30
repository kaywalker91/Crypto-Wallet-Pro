import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/metamask_connection_status.dart';
import '../providers/metamask_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Button widget for connecting to MetaMask
class MetaMaskConnectButton extends ConsumerWidget {
  /// Optional chain ID to connect to (default: 1 for Ethereum Mainnet)
  final int chainId;

  /// Optional custom styling
  final ButtonStyle? style;

  /// Optional callback when connection succeeds
  final VoidCallback? onConnected;

  /// Optional callback when connection fails
  final void Function(String error)? onError;

  const MetaMaskConnectButton({
    super.key,
    this.chainId = 1,
    this.style,
    this.onConnected,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metaMaskNotifierProvider);
    final notifier = ref.read(metaMaskNotifierProvider.notifier);

    // Handle connection/error callbacks
    ref.listen<MetaMaskState>(metaMaskNotifierProvider, (previous, next) {
      if (previous?.status != MetaMaskConnectionStatus.connected &&
          next.status == MetaMaskConnectionStatus.connected) {
        onConnected?.call();
      }
      if (next.status == MetaMaskConnectionStatus.error && next.errorMessage != null) {
        onError?.call(next.errorMessage!);
      }
    });

    return switch (state.status) {
      MetaMaskConnectionStatus.disconnected => _buildDisconnectedButton(context, notifier),
      MetaMaskConnectionStatus.connecting => _buildConnectingButton(context, notifier),
      MetaMaskConnectionStatus.connected => _buildConnectedButton(context, state, notifier),
      MetaMaskConnectionStatus.error => _buildErrorButton(context, state, notifier),
    };
  }

  Widget _buildDisconnectedButton(BuildContext context, MetaMaskNotifier notifier) {
    return ElevatedButton(
      style: style ?? _defaultButtonStyle(context),
      onPressed: () => notifier.connect(chainId: chainId),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _metamaskIcon(),
          const SizedBox(width: 8),
          const Text('Connect MetaMask'),
        ],
      ),
    );
  }

  Widget _buildConnectingButton(BuildContext context, MetaMaskNotifier notifier) {
    return OutlinedButton(
      style: (style ?? _defaultButtonStyle(context)).copyWith(
        side: WidgetStateProperty.all(
          BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      onPressed: () => notifier.cancelConnect(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Cancel'),
        ],
      ),
    );
  }

  Widget _buildConnectedButton(
    BuildContext context,
    MetaMaskState state,
    MetaMaskNotifier notifier,
  ) {
    return ElevatedButton(
      style: (style ?? _defaultButtonStyle(context)).copyWith(
        backgroundColor: WidgetStateProperty.all(Colors.green.shade600),
      ),
      onPressed: () => _showDisconnectDialog(context, notifier),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 20),
          const SizedBox(width: 8),
          Text(state.connection?.abbreviatedAddress ?? 'Connected'),
        ],
      ),
    );
  }

  Widget _buildErrorButton(
    BuildContext context,
    MetaMaskState state,
    MetaMaskNotifier notifier,
  ) {
    return ElevatedButton(
      style: (style ?? _defaultButtonStyle(context)).copyWith(
        backgroundColor: WidgetStateProperty.all(Colors.red.shade600),
      ),
      onPressed: () {
        notifier.clearError();
        notifier.connect(chainId: chainId);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh, size: 20),
          const SizedBox(width: 8),
          const Text('Retry'),
        ],
      ),
    );
  }

  Widget _metamaskIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(2),
      child: Image.asset(
        'assets/icons/metamask.png',
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.account_balance_wallet, size: 20, color: Colors.orange);
        },
      ),
    );
  }

  ButtonStyle _defaultButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showDisconnectDialog(BuildContext context, MetaMaskNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Disconnect MetaMask',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to disconnect from MetaMask?',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.disconnect();
              Navigator.of(context).pop();
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
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
