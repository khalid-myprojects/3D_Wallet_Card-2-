import 'package:flutter/material.dart';
import 'dart:math' as math;

class CardMetallicPainter extends CustomPainter {
  final List<Color> colors;
  final List<Color> shineColors;
  final double tiltX;
  final double tiltY;
  final double metalness;
  final Animation<double> shimmerAnim;

  CardMetallicPainter({
    required this.colors,
    required this.shineColors,
    required this.tiltX,
    required this.tiltY,
    required this.metalness,
    required this.shimmerAnim,
  }) : super(repaint: shimmerAnim);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    // Base gradient - angled based on tilt
    final baseAngle = math.pi / 4 + tiltX * 0.3;
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(
          -1 + tiltY * 0.5,
          -1 + tiltX * 0.5,
        ),
        end: Alignment(
          1 + tiltY * 0.3,
          1 + tiltX * 0.3,
        ),
        colors: colors,
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rRect, basePaint);

    // Metallic sheen layer
    if (metalness > 0.5) {
      final sheenX = (tiltY + 1) / 2;
      final sheenY = (tiltX + 1) / 2;

      final sheenPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(sheenX * 2 - 1, sheenY * 2 - 1),
          radius: 1.2,
          colors: [
            shineColors[0],
            Colors.transparent,
          ],
        ).createShader(rect);

      canvas.drawRRect(rRect, sheenPaint);
    }

    // Animated shimmer strip
    final shimmerOffset = shimmerAnim.value * (size.width * 2) - size.width * 0.5;
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.06 * metalness),
          Colors.white.withOpacity(0.12 * metalness),
          Colors.white.withOpacity(0.06 * metalness),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        transform: GradientRotation(math.pi / 6),
      ).createShader(Rect.fromLTWH(shimmerOffset, 0, size.width * 0.6, size.height));

    canvas.drawRRect(rRect, shimmerPaint);

    // Edge highlight
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.15),
        ],
      ).createShader(rect);

    canvas.drawRRect(rRect, edgePaint);

    // Inner shadow top
    final innerShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.4),
        const Radius.circular(20),
      ),
      innerShadowPaint,
    );
  }

  @override
  bool shouldRepaint(CardMetallicPainter oldDelegate) =>
      oldDelegate.tiltX != tiltX ||
      oldDelegate.tiltY != tiltY ||
      oldDelegate.shimmerAnim.value != shimmerAnim.value;
}

class ChipPainter extends CustomPainter {
  final Color baseColor;
  final Color lineColor;

  ChipPainter({required this.baseColor, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Chip base
    paint.color = baseColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      paint,
    );

    // Chip internal lines
    paint
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Horizontal lines
    for (double y = size.height * 0.25; y <= size.height * 0.75; y += size.height * 0.25) {
      canvas.drawLine(Offset(size.width * 0.15, y), Offset(size.width * 0.85, y), paint);
    }
    // Vertical center
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.9),
      paint,
    );
    // Center box
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.25, size.width * 0.5, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(ChipPainter oldDelegate) => false;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final particle in particles) {
      paint.color = particle.color.withOpacity(
        particle.opacity * (1 - (progress - particle.startTime).abs().clamp(0, 1)),
      );
      final x = particle.x * size.width;
      final y = (particle.y - progress * particle.speed * 0.3) * size.height;
      if (y < 0 || y > size.height) continue;
      canvas.drawCircle(Offset(x, y), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) => old.progress != progress;
}

class Particle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double opacity;
  final Color color;
  final double startTime;

  Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.color,
    required this.startTime,
  });
}
