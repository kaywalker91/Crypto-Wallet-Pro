import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/session_request.dart';

/// Bottom sheet for approving/rejecting signature and transaction requests
class SignRequestSheet extends StatelessWidget {
  final SessionRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isLoading;

  const SignRequestSheet({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
    this.isLoading = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required SessionRequest request,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SignRequestSheet(
        request: request,
        onApprove: () => Navigator.pop(context, true),
        onReject: () => Navigator.pop(context, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Request type icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _getTypeColor().withAlpha(26),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getTypeColor().withAlpha(77),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      color: _getTypeColor(),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    request.typeLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // dApp info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (request.dapp.iconUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildDappIcon(request.dapp.iconUrl!, 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        request.dapp.name,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.timeSinceRequest,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Request details
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequestDetails(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Warning and buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Warning for transactions
                  if (request.type == RequestType.sendTransaction)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withAlpha(77),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This action will execute a blockchain transaction. Review carefully before approving.',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Buttons
                  Row(
                    children: [
                      // Reject button
                      Expanded(
                        child: GradientOutlinedButton(
                          onPressed: isLoading ? null : onReject,
                          text: 'Reject',
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Approve button
                      Expanded(
                        child: GradientButton(
                          onPressed: isLoading ? null : onApprove,
                          text: request.type == RequestType.sendTransaction
                              ? 'Send'
                              : 'Sign',
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (request.type) {
      case RequestType.sendTransaction:
        return Icons.send_rounded;
      case RequestType.signMessage:
        return Icons.draw_rounded;
      case RequestType.signTypedData:
        return Icons.description_rounded;
      case RequestType.signTransaction:
        return Icons.key_rounded;
    }
  }

  Color _getTypeColor() {
    switch (request.type) {
      case RequestType.sendTransaction:
        return AppColors.primary;
      case RequestType.signMessage:
        return AppColors.secondary;
      case RequestType.signTypedData:
        return AppColors.success;
      case RequestType.signTransaction:
        return AppColors.warning;
    }
  }

  Widget _buildRequestDetails() {
    switch (request.type) {
      case RequestType.sendTransaction:
        return _buildTransactionDetails();
      case RequestType.signMessage:
        return _buildMessageDetails();
      case RequestType.signTypedData:
        return _buildTypedDataDetails();
      case RequestType.signTransaction:
        return _buildTransactionDetails();
    }
  }

  Widget _buildTransactionDetails() {
    final params = request.params;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('From', _truncateAddress(params['from'] ?? '')),
          const Divider(color: AppColors.cardBorder, height: 24),
          _buildDetailRow('To', _truncateAddress(params['to'] ?? '')),
          if (params['value'] != null) ...[
            const Divider(color: AppColors.cardBorder, height: 24),
            _buildDetailRow('Value', _parseValue(params['value'])),
          ],
          if (params['gas'] != null) ...[
            const Divider(color: AppColors.cardBorder, height: 24),
            _buildDetailRow('Gas Limit', _parseHex(params['gas'])),
          ],
          if (params['data'] != null &&
              params['data'] != '0x' &&
              (params['data'] as String).length > 2) ...[
            const Divider(color: AppColors.cardBorder, height: 24),
            const Text(
              'Data',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _truncateData(params['data']),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageDetails() {
    final message = request.params['message'] ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Message',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.toString(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypedDataDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Typed Data',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              request.params.toString(),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildDappIcon(String iconUrl, double size) {
    if (iconUrl.startsWith('http')) {
      return Image.network(
        iconUrl,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } else {
      return Image.asset(
        iconUrl,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
  }

  String _truncateAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _truncateData(String data) {
    if (data.length <= 66) return data;
    return '${data.substring(0, 34)}...${data.substring(data.length - 32)}';
  }

  String _parseHex(String hex) {
    try {
      final value = int.parse(hex.replaceFirst('0x', ''), radix: 16);
      return value.toString();
    } catch (_) {
      return hex;
    }
  }

  String _parseValue(String value) {
    try {
      final wei = BigInt.parse(value.replaceFirst('0x', ''), radix: 16);
      if (wei == BigInt.zero) return '0 ETH';

      final weiPerEth = BigInt.from(10).pow(18);
      final integerPart = wei ~/ weiPerEth;
      final fractionalPart = wei % weiPerEth;

      // Format fractional part with 6 decimal places
      final fractionalStr = fractionalPart.toString().padLeft(18, '0').substring(0, 6);

      // Remove trailing zeros
      final trimmedFractional = fractionalStr.replaceAll(RegExp(r'0+$'), '');

      if (trimmedFractional.isEmpty) {
        return '$integerPart ETH';
      }
      return '$integerPart.$trimmedFractional ETH';
    } catch (_) {
      return value;
    }
  }
}
