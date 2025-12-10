
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/gas_estimate.dart';
import '../providers/send_provider.dart';

class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});

  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onEstimate() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(sendProvider.notifier).estimateGas(
            recipientAddress: _addressController.text.trim(),
            amountEth: _amountController.text.trim(),
          );
    }
  }

  Future<void> _onSend() async {
    final success = await ref.read(sendProvider.notifier).send(
          recipientAddress: _addressController.text.trim(),
          amountEth: _amountController.text.trim(),
        );

    if (success && mounted) {
      final txHash = ref.read(sendProvider).txHash;
      _showSuccessDialog(txHash);
    }
  }

  void _showSuccessDialog(String? txHash) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Transaction Sent', style: TextStyle(color: AppColors.success)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your transaction has been broadcast successfully.', style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text('Hash: ${txHash ?? ""}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.pop(); // Go back to dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sendState = ref.watch(sendProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Send ETH'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Input
              Text('Recipient Address', style: AppTypography.textTheme.titleMedium),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '0x...',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    suffixIcon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    if (!value.startsWith('0x') || value.length != 42) {
                      return 'Invalid Ethereum address';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Amount Input
              Text('Amount (ETH)', style: AppTypography.textTheme.titleMedium),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '0.0',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    suffixText: 'ETH',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid amount';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Gas Estimation Section
              if (sendState.isLoading && sendState.gasEstimates == null)
                const Center(child: CircularProgressIndicator())
              else if (sendState.gasEstimates != null)
                _buildGasSelection(sendState),

              if (sendState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    sendState.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),

              const SizedBox(height: 32),

              // Action Button
              if (sendState.gasEstimates == null)
                GradientButton(
                  text: 'Estimate Gas',
                  width: double.infinity,
                  onPressed: sendState.isLoading ? null : _onEstimate,
                )
              else
                GradientButton(
                  text: sendState.isLoading ? 'Sending...' : 'Send Now',
                  width: double.infinity,
                  onPressed: sendState.isLoading ? null : _onSend,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGasSelection(SendState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transaction Speed', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: GasPriority.values.map((priority) {
            final estimate = state.gasEstimates![priority];
            final isSelected = state.selectedPriority == priority;
            final feeEth = (estimate!.estimatedFeeInWei / BigInt.from(10).pow(18));
            
            return Expanded(
              child: GestureDetector(
                onTap: () => ref.read(sendProvider.notifier).selectPriority(priority),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        priority.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${feeEth.toStringAsFixed(6)} ETH',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
