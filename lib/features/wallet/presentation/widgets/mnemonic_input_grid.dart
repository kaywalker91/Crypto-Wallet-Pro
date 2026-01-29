import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glassmorphism.dart';

/// Grid input for mnemonic words (12 or 24 words)
class MnemonicInputGrid extends StatefulWidget {
  final int wordCount;
  final List<String> words;
  final Function(List<String>) onWordsChanged;
  final VoidCallback? onPaste;
  final bool showPasteButton;

  const MnemonicInputGrid({
    super.key,
    this.wordCount = 12,
    required this.words,
    required this.onWordsChanged,
    this.onPaste,
    this.showPasteButton = true,
  });

  @override
  State<MnemonicInputGrid> createState() => _MnemonicInputGridState();
}

class _MnemonicInputGridState extends State<MnemonicInputGrid> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = List.generate(
      widget.wordCount,
      (index) => TextEditingController(
        text: index < widget.words.length ? widget.words[index] : '',
      ),
    );

    _focusNodes = List.generate(
      widget.wordCount,
      (index) => FocusNode(),
    );
  }

  @override
  void didUpdateWidget(MnemonicInputGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wordCount != widget.wordCount) {
      _disposeControllers();
      _initControllers();
    } else {
      // Update controller text if words changed externally
      for (int i = 0; i < widget.wordCount; i++) {
        final newText = i < widget.words.length ? widget.words[i] : '';
        if (_controllers[i].text != newText) {
          _controllers[i].text = newText;
        }
      }
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _onWordChanged(int index, String value) {
    // Check for pasted multi-word content
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length > 1) {
      _handlePastedWords(index, words);
      return;
    }

    final currentWords = List<String>.from(widget.words);
    // Ensure list has enough capacity
    while (currentWords.length <= index) {
      currentWords.add('');
    }
    currentWords[index] = value.trim().toLowerCase();
    widget.onWordsChanged(currentWords);

    // Auto-advance to next field on space or complete word
    if (value.endsWith(' ') && index < widget.wordCount - 1) {
      _controllers[index].text = value.trim();
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _handlePastedWords(int startIndex, List<String> words) {
    final currentWords = List<String>.filled(widget.wordCount, '');

    // Fill in existing words
    for (int i = 0; i < widget.words.length && i < widget.wordCount; i++) {
      currentWords[i] = widget.words[i];
    }

    // Fill in pasted words starting from startIndex
    for (int i = 0; i < words.length && startIndex + i < widget.wordCount; i++) {
      currentWords[startIndex + i] = words[i].trim().toLowerCase();
    }

    // Update all controllers
    for (int i = 0; i < widget.wordCount; i++) {
      _controllers[i].text = currentWords[i];
    }

    widget.onWordsChanged(currentWords);

    // Focus the field after the last pasted word
    final nextFocusIndex = startIndex + words.length;
    if (nextFocusIndex < widget.wordCount) {
      _focusNodes[nextFocusIndex].requestFocus();
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      final words = clipboardData!.text!.trim().split(RegExp(r'\s+'));
      if (words.isNotEmpty) {
        _handlePastedWords(0, words);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pasted ${words.length} words'),
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
    widget.onPaste?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with paste button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.key_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recovery Phrase',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (widget.showPasteButton)
                _PasteButton(onPressed: _pasteFromClipboard),
            ],
          ),
          const SizedBox(height: 16),

          // Word input grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.wordCount, (index) {
              return _MnemonicInputField(
                index: index,
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                onChanged: (value) => _onWordChanged(index, value),
                onSubmitted: (_) {
                  if (index < widget.wordCount - 1) {
                    _focusNodes[index + 1].requestFocus();
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Single mnemonic input field
class _MnemonicInputField extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final Function(String)? onSubmitted;

  const _MnemonicInputField({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 80) / 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Index number
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Input field
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'word',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                textInputAction:
                    index < 11 ? TextInputAction.next : TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paste button widget
class _PasteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PasteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.paste_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Paste',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Information banner for import wallet
class ImportWalletInfo extends StatelessWidget {
  const ImportWalletInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recovery Phrase',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter your 12-word recovery phrase in the correct order to restore your wallet.',
                  style: AppTypography.bodySmall.copyWith(
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
}
