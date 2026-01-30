import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final Duration duration;
  final int fractionalDigits;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
    this.duration = const Duration(milliseconds: 800),
    this.fractionalDigits = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<num>(
      tween: Tween<num>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, animatedValue, child) {
        final formatter = NumberFormat.currency(
          symbol: prefix ?? '',
          decimalDigits: fractionalDigits,
          customPattern: '${prefix ?? ''}#,##0.${'#' * fractionalDigits}${suffix ?? ''}',
        );
        return Text(
          formatter.format(animatedValue),
          style: style,
        );
      },
    );
  }
}
