import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class ConfidenceRing extends StatelessWidget {
  final int confidence;
  final double size;
  final bool showLabel;

  const ConfidenceRing({
    super.key,
    required this.confidence,
    this.size = 80,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = confidence >= 70
        ? AppColors.bullish
        : confidence >= 50
            ? AppColors.goldPrimary
            : AppColors.bearish;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(confidence / 100, color),
          ),
          if (showLabel)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$confidence%',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'conf.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: size * 0.13,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const stroke = 5.0;

    final bg = Paint()
      ..color = AppColors.border
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
