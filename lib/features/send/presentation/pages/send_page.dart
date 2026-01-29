
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/gas_estimate.dart';
import '../providers/send_provider.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../features/dashboard/domain/entities/token.dart';

class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});

  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Token? _selectedToken;

  @override
  void initState() {
    super.initState();
    // Default to ETH
    _selectedToken = MockTokens.eth;
  }

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
            token: _selectedToken?.symbol == 'ETH' ? null : _selectedToken,
          );
    }
  }

  Future<void> _onSend() async {
    final success = await ref.read(sendProvider.notifier).send(
          recipientAddress: _addressController.text.trim(),
          amountEth: _amountController.text.trim(),
          token: _selectedToken?.symbol == 'ETH' ? null : _selectedToken,
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Text(
              'Transaction Sent',
              style: AppTypography.textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your transaction has been broadcast successfully.',
              style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Hash',
              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 4),
            Text(
              txHash ?? '-',
              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Token Selection
              Text('Asset', style: AppTypography.textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildTokenSelector(),
              const SizedBox(height: 24),

              // Address Input
              Text('Recipient Address', style: AppTypography.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                textInputAction: TextInputAction.next,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: '0x...',
                  helperText: 'Only Ethereum addresses are supported.',
                  suffixIcon: Icon(Icons.qr_code_scanner),
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

              const SizedBox(height: 24),

              // Amount Input
              Text('Amount (ETH)', style: AppTypography.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '0.0',
                  helperText: 'Enter the amount to send.',
                  suffixText: _selectedToken?.symbol ?? 'ETH',
                  suffixStyle: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => ref.read(sendProvider.notifier).selectPriority(priority),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            priority.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${feeEth.toStringAsFixed(6)} ETH',
                          style: TextStyle(
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  Widget _buildTokenSelector() {
    final dashboardState = ref.watch(dashboardProvider);
    final allTokens = [MockTokens.eth, ...dashboardState.tokens];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Token>(
          value: _selectedToken != null && allTokens.any((t) => t.symbol == _selectedToken!.symbol) 
              ? allTokens.firstWhere((t) => t.symbol == _selectedToken!.symbol) 
              : allTokens.first,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          items: allTokens.map((token) {
            return DropdownMenuItem<Token>(
              value: token,
              child: Row(
                children: [
                  CircleAvatar(
                   backgroundColor: token.color.withValues(alpha: 0.2),
                   radius: 12,
                   child: Text(token.symbol[0], style: TextStyle(color: token.color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    token.symbol,
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Show balance if available (simple check)
                  Text(
                    token.symbol == 'ETH' 
                        ? (dashboardState.walletBalance?.balanceEth ?? '') 
                        : '${token.balance} ${token.symbol}', 
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (Token? newValue) {
            setState(() {
              _selectedToken = newValue;
            });
          },
        ),
      ),
    );
  }
}
