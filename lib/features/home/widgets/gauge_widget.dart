import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class GaugeWidget extends StatelessWidget {
  final double value;
  final double size;

  const GaugeWidget({
    super.key,
    required this.value,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.55,
      child: CustomPaint(
        painter: _GaugePainter(value: value.clamp(0.0, 1.0)),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  const _GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.95;
    final radius = size.width * 0.44;
    const strokeWidth = 14.0;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Fondo gris del arco completo
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    // Segmentos de color
    final segments = [
      _Segment(AppColors.gaugeGood,    0.0, 0.45),
      _Segment(AppColors.gaugeWarning, 0.45, 0.72),
      _Segment(AppColors.gaugeDanger,  0.72, 1.0),
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect,
        math.pi + math.pi * seg.start,
        math.pi * (seg.end - seg.start),
        false,
        paint,
      );
    }

    // Aguja
    final angle = math.pi + math.pi * value;
    final needleLen = radius * 0.72;
    final needleEnd = Offset(
      cx + math.cos(angle) * needleLen,
      cy + math.sin(angle) * needleLen,
    );

    canvas.drawLine(
      Offset(cx, cy),
      needleEnd,
      Paint()
        ..color = const Color(0xFF2D3748)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Pivote
    canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()..color = const Color(0xFF2D3748),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}

class _Segment {
  final Color color;
  final double start;
  final double end;
  const _Segment(this.color, this.start, this.end);
}