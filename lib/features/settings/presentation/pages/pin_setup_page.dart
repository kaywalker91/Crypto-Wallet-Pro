import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

/// PIN Setup page with Glassmorphic design
class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  String? _error;
  bool _saving = false;
  bool _pinObscured = true;
  bool _confirmObscured = true;

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 4) {
      setState(() => _error = '4자리 이상 PIN을 입력하세요.');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'PIN이 일치하지 않습니다.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(pinServiceProvider).savePin(pin);
      await ref.read(walletProvider.notifier).markAuthenticated();
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'PIN 저장에 실패했습니다. 다시 시도하세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _pinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(context),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      _buildHeaderCard(),
                      const SizedBox(height: 24),
                      // PIN input section
                      _buildPinInputSection(),
                      const SizedBox(height: 16),
                      // Error message
                      if (_error != null) _buildErrorMessage(),
                    ],
                  ),
                ),
              ),
              // Save button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'PIN 설정',
            style: AppTypography.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return GlassmorphicAccentCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PIN 보안 설정',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '생체인증 실패 시 사용할 PIN을 설정하세요.',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinInputSection() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _PinInputField(
            controller: _pinController,
            focusNode: _pinFocusNode,
            label: 'PIN 입력',
            hint: '4자리 이상 입력',
            obscured: _pinObscured,
            onToggleVisibility: () => setState(() => _pinObscured = !_pinObscured),
            onSubmitted: (_) => _confirmFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),
          _PinInputField(
            controller: _confirmController,
            focusNode: _confirmFocusNode,
            label: 'PIN 확인',
            hint: 'PIN을 다시 입력',
            obscured: _confirmObscured,
            onToggleVisibility: () => setState(() => _confirmObscured = !_confirmObscured),
            onSubmitted: (_) => _savePin(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: GradientButton(
        text: '저장',
        onPressed: _saving ? null : _savePin,
        isLoading: _saving,
        width: double.infinity,
        icon: Icons.lock_rounded,
      ),
    );
  }
}

class _PinInputField extends StatelessWidget {
  const _PinInputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.obscured,
    required this.onToggleVisibility,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final bool obscured;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          obscureText: obscured,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 14,
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: AppColors.surfaceLight.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
