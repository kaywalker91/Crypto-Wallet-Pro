import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom app logo widget
/// Combines Ethereum diamond with wallet concept
class AppLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool animated;

  const AppLogo({
    super.key,
    this.size = 120,
    this.showGlow = true,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(),
    );

    if (showGlow) {
      logo = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyanGlow,
              blurRadius: size * 0.3,
              spreadRadius: size * 0.05,
            ),
            BoxShadow(
              color: AppColors.neonPurpleGlow,
              blurRadius: size * 0.4,
              spreadRadius: size * 0.02,
            ),
          ],
        ),
        child: logo,
      );
    }

    if (animated) {
      return _AnimatedLogo(child: logo);
    }

    return logo;
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Gradient for the main shape
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw outer hexagon (wallet shape)
    final outerPath = _createHexagonPath(center, radius * 0.9);
    canvas.drawPath(outerPath, gradientPaint);

    // Inner background
    final innerPaint = Paint()..color = AppColors.background.withOpacity(0.8);
    final innerPath = _createHexagonPath(center, radius * 0.75);
    canvas.drawPath(innerPath, innerPaint);

    // Ethereum diamond shape in center
    _drawEthereumDiamond(canvas, center, radius * 0.5);

    // Subtle border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(outerPath, borderPaint);
  }

  Path _createHexagonPath(Offset center, double radius) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius * 0.866, center.dy - radius * 0.5);
    path.lineTo(center.dx + radius * 0.866, center.dy + radius * 0.5);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius * 0.866, center.dy + radius * 0.5);
    path.lineTo(center.dx - radius * 0.866, center.dy - radius * 0.5);
    path.close();

    return path;
  }

  void _drawEthereumDiamond(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(
        Rect.fromCenter(center: center, width: size, height: size * 1.6),
      );

    // Top half of diamond
    final topPath = Path()
      ..moveTo(center.dx, center.dy - size * 0.8)
      ..lineTo(center.dx + size * 0.5, center.dy)
      ..lineTo(center.dx, center.dy + size * 0.1)
      ..lineTo(center.dx - size * 0.5, center.dy)
      ..close();

    // Bottom half of diamond
    final bottomPath = Path()
      ..moveTo(center.dx, center.dy + size * 0.1)
      ..lineTo(center.dx + size * 0.5, center.dy)
      ..lineTo(center.dx, center.dy + size * 0.8)
      ..lineTo(center.dx - size * 0.5, center.dy)
      ..close();

    canvas.drawPath(topPath, paint);
    canvas.drawPath(
      bottomPath,
      paint..color = AppColors.primary.withOpacity(0.7),
    );

    // Center line
    final linePaint = Paint()
      ..color = AppColors.background.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - size * 0.5, center.dy),
      Offset(center.dx + size * 0.5, center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated version with pulse effect
class _AnimatedLogo extends StatefulWidget {
  final Widget child;

  const _AnimatedLogo({required this.child});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
