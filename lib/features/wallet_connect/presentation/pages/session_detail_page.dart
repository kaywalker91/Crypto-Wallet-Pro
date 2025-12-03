import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/wallet_session.dart';
import '../providers/wallet_connect_provider.dart';

/// Session detail page with dApp info and actions
class SessionDetailPage extends ConsumerWidget {
  final WalletSession session;

  const SessionDetailPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Sliver app bar with Hero image
          _buildSliverAppBar(context),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  _buildStatusBadge(),
                  const SizedBox(height: 16),
                  // dApp name
                  _buildDappName(),
                  const SizedBox(height: 8),
                  // dApp URL
                  _buildDappUrl(),
                  // Description
                  if (session.dapp.description != null &&
                      session.dapp.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDescription(),
                  ],
                  const SizedBox(height: 24),
                  // Connection info
                  _buildConnectionInfo(context),
                  const SizedBox(height: 24),
                  // Methods section
                  if (session.methods.isNotEmpty) ...[
                    _buildMethodsSection(),
                    const SizedBox(height: 24),
                  ],
                  // Action buttons
                  _buildActionButtons(context, ref),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: _buildBackButton(context),
      actions: [
        _buildMenuButton(context),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withAlpha(51),
                AppColors.secondary.withAlpha(51),
              ],
            ),
          ),
          child: Center(
            child: Hero(
              tag: 'session_${session.id}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: session.dapp.iconUrl != null
                    ? _buildDappIcon(session.dapp.iconUrl!)
                    : _buildIconPlaceholder(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showOptionsSheet(context),
        ),
      ),
    );
  }

  Widget _buildDappIcon(String iconUrl) {
    if (iconUrl.startsWith('http')) {
      return Image.network(
        iconUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildIconPlaceholder();
        },
      );
    } else {
      return Image.asset(
        iconUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildIconPlaceholder();
        },
      );
    }
  }

  Widget _buildIconPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          session.dapp.name.isNotEmpty ? session.dapp.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (session.status) {
      case SessionStatus.active:
        backgroundColor = AppColors.success.withAlpha(26);
        textColor = AppColors.success;
        label = 'Active Connection';
        icon = Icons.check_circle_outline;
        break;
      case SessionStatus.expired:
        backgroundColor = AppColors.error.withAlpha(26);
        textColor = AppColors.error;
        label = 'Expired';
        icon = Icons.cancel_outlined;
        break;
      case SessionStatus.pending:
        backgroundColor = AppColors.warning.withAlpha(26);
        textColor = AppColors.warning;
        label = 'Pending Approval';
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDappName() {
    return Text(
      session.dapp.name,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDappUrl() {
    return GestureDetector(
      onTap: () {
        // TODO: Launch URL
      },
      child: Row(
        children: [
          const Icon(
            Icons.language_rounded,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            session.dapp.url,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.open_in_new,
            color: AppColors.primary,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          session.dapp.description!,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connection Details',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            Icons.link_rounded,
            'Network',
            session.chainName,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            Icons.access_time_rounded,
            'Connected',
            _formatDate(session.connectedAt),
          ),
          if (session.expiresAt != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.timer_outlined,
              'Expires',
              _formatDate(session.expiresAt!),
            ),
          ],
          if (session.walletAddress != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.account_balance_wallet_outlined,
              'Wallet',
              _shortenAddress(session.walletAddress!),
              canCopy: true,
              fullValue: session.walletAddress,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool canCopy = false,
    String? fullValue,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: canCopy
              ? () {
                  Clipboard.setData(ClipboardData(text: fullValue ?? value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied'),
                      backgroundColor: AppColors.surface,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: canCopy ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.copy,
                  color: AppColors.primary,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permissions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: session.methods.map(_buildMethodChip).toList(),
        ),
      ],
    );
  }

  Widget _buildMethodChip(String method) {
    IconData icon;
    String label;

    if (method.contains('sendTransaction')) {
      icon = Icons.send_rounded;
      label = 'Send Transactions';
    } else if (method.contains('signTypedData')) {
      icon = Icons.description_rounded;
      label = 'Sign Typed Data';
    } else if (method.contains('sign')) {
      icon = Icons.draw_rounded;
      label = 'Sign Messages';
    } else {
      icon = Icons.check_circle_outline;
      // Simplify method name
      label = method.startsWith('eth_') ? method.substring(4) : method;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    if (session.status == SessionStatus.pending) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GradientOutlinedButton(
                  onPressed: () {
                    ref.read(walletConnectProvider.notifier).rejectSession(session.id);
                    Navigator.pop(context);
                  },
                  text: 'Reject',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GradientButton(
                  onPressed: () {
                    ref.read(walletConnectProvider.notifier).approveSession(session.id);
                    Navigator.pop(context);
                  },
                  text: 'Approve',
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showDisconnectConfirmation(context, ref),
        icon: const Icon(Icons.link_off_rounded),
        label: const Text('Disconnect'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showDisconnectConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Disconnect Session?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to disconnect from ${session.dapp.name}? You will need to scan a new QR code to reconnect.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(walletConnectProvider.notifier).disconnectSession(session.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: AppColors.textSecondary),
                title: const Text(
                  'Refresh Session',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Refresh session
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new, color: AppColors.textSecondary),
                title: const Text(
                  'Open dApp',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Launch URL
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortenAddress(String address) {
    if (address.length <= 13) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative) {
      // Future date (expires)
      final remaining = date.difference(now);
      if (remaining.inDays > 0) {
        return 'in ${remaining.inDays}d';
      } else if (remaining.inHours > 0) {
        return 'in ${remaining.inHours}h';
      }
      return 'soon';
    } else {
      // Past date (connected)
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      }
      return 'Just now';
    }
  }
}
