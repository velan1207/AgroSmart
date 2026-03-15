import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Branded app logo used across splash, setup, loading, and app bar.
class AppLogo extends StatelessWidget {
  final double? size;
  final double borderRadius;

  const AppLogo({
    super.key,
    this.size = 96,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Soft inner ring for depth.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..color = Colors.white.withOpacity(0.24);
    canvas.drawCircle(center, size.width * 0.34, ringPaint);

    // Water droplet base.
    final dropPath = Path();
    final dropTop = Offset(size.width * 0.5, size.height * 0.2);
    final dropBottom = Offset(size.width * 0.5, size.height * 0.77);
    dropPath.moveTo(dropTop.dx, dropTop.dy);
    dropPath.cubicTo(
      size.width * 0.78,
      size.height * 0.34,
      size.width * 0.72,
      size.height * 0.66,
      dropBottom.dx,
      dropBottom.dy,
    );
    dropPath.cubicTo(
      size.width * 0.28,
      size.height * 0.66,
      size.width * 0.22,
      size.height * 0.34,
      dropTop.dx,
      dropTop.dy,
    );
    dropPath.close();

    final dropPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE8F5E9),
          Color(0xFFC8E6C9),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(dropPath, dropPaint);

    // Stem.
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1B5E20);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.45),
      Offset(size.width * 0.5, size.height * 0.67),
      stemPaint,
    );

    // Leaves.
    final leafPaint = Paint()..color = const Color(0xFF2E7D32);
    final leftLeaf = Path()
      ..moveTo(size.width * 0.5, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.46,
        size.width * 0.35,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.62,
        size.width * 0.5,
        size.height * 0.57,
      )
      ..close();
    final rightLeaf = Path()
      ..moveTo(size.width * 0.5, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.46,
        size.width * 0.65,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.56,
        size.height * 0.62,
        size.width * 0.5,
        size.height * 0.57,
      )
      ..close();
    canvas.drawPath(leftLeaf, leafPaint);
    canvas.drawPath(rightLeaf, leafPaint);

    // Small signal arcs (smart monitoring accent).
    final signalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02
      ..color = Colors.white.withOpacity(0.8)
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final radius = size.width * (0.1 + i * 0.05);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.35), radius: radius),
        -math.pi * 0.95,
        math.pi * 0.9,
        false,
        signalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}