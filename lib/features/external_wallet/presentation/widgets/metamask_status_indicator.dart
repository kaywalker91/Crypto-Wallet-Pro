import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/metamask_connection_status.dart';
import '../providers/metamask_provider.dart';

/// A compact status indicator for MetaMask connection
class MetaMaskStatusIndicator extends ConsumerWidget {
  /// Whether to show the wallet address when connected
  final bool showAddress;

  /// Whether to show the chain ID when connected
  final bool showChainId;

  /// Optional size for the indicator
  final double size;

  const MetaMaskStatusIndicator({
    super.key,
    this.showAddress = true,
    this.showChainId = false,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metaMaskNotifierProvider);
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusDot(state.status),
        const SizedBox(width: 8),
        _buildStatusText(context, state, theme),
      ],
    );
  }

  Widget _buildStatusDot(MetaMaskConnectionStatus status) {
    Color color;
    bool isAnimating = false;

    switch (status) {
      case MetaMaskConnectionStatus.disconnected:
        color = Colors.grey;
        break;
      case MetaMaskConnectionStatus.connecting:
        color = Colors.orange;
        isAnimating = true;
        break;
      case MetaMaskConnectionStatus.connected:
        color = Colors.green;
        break;
      case MetaMaskConnectionStatus.error:
        color = Colors.red;
        break;
    }

    if (isAnimating) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(BuildContext context, MetaMaskState state, ThemeData theme) {
    switch (state.status) {
      case MetaMaskConnectionStatus.disconnected:
        return Text(
          'Not Connected',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        );

      case MetaMaskConnectionStatus.connecting:
        return Text(
          'Connecting...',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
        );

      case MetaMaskConnectionStatus.connected:
        final connection = state.connection;
        if (connection == null) {
          return Text(
            'Connected',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
          );
        }

        final parts = <String>[];
        if (showAddress) {
          parts.add(connection.abbreviatedAddress);
        }
        if (showChainId) {
          parts.add(_chainName(connection.chainId));
        }

        return Text(
          parts.isEmpty ? 'Connected' : parts.join(' | '),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
        );

      case MetaMaskConnectionStatus.error:
        return Text(
          state.errorMessage ?? 'Error',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  String _chainName(int chainId) {
    switch (chainId) {
      case 1:
        return 'Ethereum';
      case 5:
        return 'Goerli';
      case 11155111:
        return 'Sepolia';
      case 137:
        return 'Polygon';
      case 42161:
        return 'Arbitrum';
      case 10:
        return 'Optimism';
      case 8453:
        return 'Base';
      case 56:
        return 'BNB Chain';
      default:
        return 'Chain $chainId';
    }
  }
}

/// A card widget showing full MetaMask connection details
class MetaMaskConnectionCard extends ConsumerWidget {
  /// Callback when disconnect is pressed
  final VoidCallback? onDisconnect;

  const MetaMaskConnectionCard({
    super.key,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metaMaskNotifierProvider);
    final theme = Theme.of(context);

    if (state.status != MetaMaskConnectionStatus.connected || state.connection == null) {
      return const SizedBox.shrink();
    }

    final connection = state.connection!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.walletName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        connection.abbreviatedAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const MetaMaskStatusIndicator(showAddress: false),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  context,
                  label: 'Network',
                  value: _chainName(connection.chainId),
                  icon: Icons.language,
                ),
                TextButton.icon(
                  onPressed: () {
                    if (onDisconnect != null) {
                      onDisconnect!();
                    } else {
                      ref.read(metaMaskNotifierProvider.notifier).disconnect();
                    }
                  },
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('Disconnect'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _chainName(int chainId) {
    switch (chainId) {
      case 1:
        return 'Ethereum';
      case 5:
        return 'Goerli';
      case 11155111:
        return 'Sepolia';
      case 137:
        return 'Polygon';
      case 42161:
        return 'Arbitrum';
      case 10:
        return 'Optimism';
      case 8453:
        return 'Base';
      case 56:
        return 'BNB Chain';
      default:
        return 'Chain $chainId';
    }
  }
}
