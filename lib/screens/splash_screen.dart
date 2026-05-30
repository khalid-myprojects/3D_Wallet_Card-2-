import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../painters/card_painter.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── CONTROLLERS ────────────────────────────────────────────────
  late AnimationController _orbController;       // ambient orb drift
  late AnimationController _entryController;     // main entrance sequence
  late AnimationController _pulseController;     // logo ring pulse
  late AnimationController _shimmerController;   // text shimmer sweep
  late AnimationController _exitController;      // exit transition

  // ── ENTRY ANIMATIONS ────────────────────────────────────────────
  late Animation<double> _bgFade;
  late Animation<double> _logoReveal;        // logo scale + fade
  late Animation<double> _logoY;             // logo slide up
  late Animation<double> _ringExpand;        // ring radius expansion
  late Animation<double> _ringFade;          // ring opacity
  late Animation<double> _wordmarkFade;      // NEXUS wordmark
  late Animation<double> _wordmarkScale;     // NEXUS scale
  late Animation<double> _subtitleFade;      // PREMIUM CARDS
  late Animation<double> _subtitleSlide;     // subtitle slide in
  late Animation<double> _taglineFade;       // bottom tagline
  late Animation<double> _dotsProgress;      // loading dots

  // ── EXIT ─────────────────────────────────────────────────────────
  late Animation<double> _exitFade;
  late Animation<double> _exitScale;

  // ── SHIMMER ──────────────────────────────────────────────────────
  late Animation<double> _shimmerSweep;

  // ── PARTICLES ────────────────────────────────────────────────────
  late List<_SplashParticle> _particles;

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _setupControllers();
    _setupAnimations();
    _startSequence();
  }

  void _generateParticles() {
    final rng = math.Random(42);
    _particles = List.generate(55, (i) => _SplashParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: rng.nextDouble() * 1.8 + 0.4,
      speed: rng.nextDouble() * 0.35 + 0.08,
      opacity: rng.nextDouble() * 0.55 + 0.08,
      phase: rng.nextDouble(),
      color: [
        Colors.white,
        const Color(0xFFD4A843),
        const Color(0xFFE8C96A),
        const Color(0xFF9BB8D4),
      ][rng.nextInt(4)],
    ));
  }

  void _setupControllers() {
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  void _setupAnimations() {
    // BG fade in immediately
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.0, 0.25, curve: Curves.easeOut)),
    );

    // Logo drops in from slight offset, scales up
    _logoReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.05, 0.40, curve: Curves.easeOutBack)),
    );
    _logoY = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.05, 0.38, curve: Curves.easeOutCubic)),
    );

    // Ring expands outward from logo
    _ringExpand = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.25, 0.55, curve: Curves.easeOut)),
    );
    _ringFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.25, 0.50, curve: Curves.easeOut)),
    );

    // NEXUS big wordmark
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.42, 0.65, curve: Curves.easeOut)),
    );
    _wordmarkScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.42, 0.70, curve: Curves.easeOutCubic)),
    );

    // Subtitle slides in from below
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.58, 0.78, curve: Curves.easeOut)),
    );
    _subtitleSlide = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.58, 0.78, curve: Curves.easeOutCubic)),
    );

    // Tagline + dots
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.72, 0.92, curve: Curves.easeOut)),
    );
    _dotsProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.80, 1.0, curve: Curves.easeOut)),
    );

    // Shimmer sweep across NEXUS text
    _shimmerSweep = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    // Exit
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  void _startSequence() {
    _entryController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _exitController.forward().then((_) {
            if (mounted) widget.onComplete();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _orbController, _entryController,
        _pulseController, _shimmerController, _exitController,
      ]),
      builder: (context, _) {
        return Opacity(
          opacity: _exitFade.value,
          child: Transform.scale(
            scale: _exitScale.value,
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF040506),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── LAYER 1: DEEP BACKGROUND ORBS ──────────
                  _buildBackgroundOrbs(size),

                  // ── LAYER 2: PARTICLE FIELD ─────────────────
                  Opacity(
                    opacity: _bgFade.value,
                    child: CustomPaint(
                      size: size,
                      painter: _SplashParticlePainter(
                        particles: _particles,
                        progress: _orbController.value,
                      ),
                    ),
                  ),

                  // ── LAYER 3: SCAN LINES ─────────────────────
                  Opacity(
                    opacity: 0.025 * _bgFade.value,
                    child: CustomPaint(
                      size: size,
                      painter: _ScanLinePainter(),
                    ),
                  ),

                  // ── LAYER 4: DECORATIVE RINGS ───────────────
                  _buildDecorativeRings(size),

                  // ── LAYER 5: MAIN CONTENT ───────────────────
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo mark
                      Transform.translate(
                        offset: Offset(0, _logoY.value),
                        child: Opacity(
                          opacity: _logoReveal.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _logoReveal.value.clamp(0.0, 1.0),
                            child: _buildLogoMark(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // NEXUS wordmark with shimmer
                      Opacity(
                        opacity: _wordmarkFade.value,
                        child: Transform.scale(
                          scale: _wordmarkScale.value,
                          child: _buildWordmark(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // PREMIUM CARDS subtitle
                      Transform.translate(
                        offset: Offset(0, _subtitleSlide.value),
                        child: Opacity(
                          opacity: _subtitleFade.value,
                          child: _buildSubtitle(),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Loading indicator
                      Opacity(
                        opacity: _taglineFade.value,
                        child: _buildLoadingDots(),
                      ),
                    ],
                  ),

                  // ── LAYER 6: CORNER ACCENTS ─────────────────
                  _buildCornerAccents(size),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── BACKGROUND ORBS ────────────────────────────────────────────

  Widget _buildBackgroundOrbs(Size size) {
    final t = _orbController.value;
    return Stack(
      children: [
        // Primary warm center orb
        Positioned(
          top: size.height * 0.25 + t * 30,
          left: size.width * 0.15 + t * 20,
          child: Container(
            width: size.width * 0.80,
            height: size.width * 0.80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD4A843).withOpacity(0.09 * _bgFade.value),
                  const Color(0xFF8B6914).withOpacity(0.05 * _bgFade.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Secondary cool orb
        Positioned(
          bottom: size.height * 0.1 + (1 - t) * 20,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 0.65,
            height: size.width * 0.65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1A3A6B).withOpacity(0.08 * _bgFade.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Small accent top-right
        Positioned(
          top: size.height * 0.05,
          right: size.width * 0.1,
          child: Container(
            width: size.width * 0.30,
            height: size.width * 0.30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD4A843).withOpacity(0.05 * _bgFade.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── DECORATIVE RINGS ────────────────────────────────────────────

  Widget _buildDecorativeRings(Size size) {
    final ringBase = size.width * 0.48;
    final pulse = _pulseController.value;

    return Opacity(
      opacity: _ringFade.value * 0.85,
      child: Transform.scale(
        scale: _ringExpand.value,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring
            Container(
              width: ringBase * (1.0 + pulse * 0.06),
              height: ringBase * (1.0 + pulse * 0.06),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4A843)
                      .withOpacity(0.12 + pulse * 0.06),
                  width: 0.6,
                ),
              ),
            ),
            // Mid ring — static
            Container(
              width: ringBase * 0.76,
              height: ringBase * 0.76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4A843).withOpacity(0.18),
                  width: 0.5,
                ),
              ),
            ),
            // Inner faint ring
            Container(
              width: ringBase * 0.56,
              height: ringBase * 0.56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 0.4,
                ),
              ),
            ),
            // Four tick marks at cardinal points
            SizedBox(
              width: ringBase * 0.76,
              height: ringBase * 0.76,
              child: CustomPaint(
                painter: _TickMarkPainter(
                  color: const Color(0xFFD4A843).withOpacity(0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOGO MARK ───────────────────────────────────────────────────

  Widget _buildLogoMark() {
    final pulse = _pulseController.value;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow halo behind logo
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFD4A843).withOpacity(0.16 + pulse * 0.06),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Logo box
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF201A0E), Color(0xFF0C0A06)],
            ),
            border: Border.all(
              color: const Color(0xFFD4A843)
                  .withOpacity(0.45 + pulse * 0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A843)
                    .withOpacity(0.22 + pulse * 0.10),
                blurRadius: 36,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFF5D06A), Color(0xFFD4A843), Color(0xFFB8860B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'N',
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        // Inner shine highlight on logo box top edge
        Positioned(
          top: 7,
          left: 18,
          right: 18,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── WORDMARK ────────────────────────────────────────────────────

  Widget _buildWordmark() {
    return ClipRect(
      child: CustomPaint(
        painter: _ShimmerTextPainter(
          text: 'NEXUS',
          shimmerPosition: _shimmerSweep.value,
          baseStyle: GoogleFonts.rajdhani(
            color: Colors.white,
            fontSize: 58,
            fontWeight: FontWeight.w700,
            letterSpacing: 16,
            height: 1.0,
          ),
        ),
        child: Text(
          'NEXUS',
          style: GoogleFonts.rajdhani(
            color: Colors.transparent,
            fontSize: 58,
            fontWeight: FontWeight.w700,
            letterSpacing: 16,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // ── SUBTITLE ────────────────────────────────────────────────────

  Widget _buildSubtitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 0.6,
          color: const Color(0xFFD4A843).withOpacity(0.55),
        ),
        const SizedBox(width: 12),
        Text(
          'PREMIUM CARDS',
          style: GoogleFonts.dmSans(
            color: const Color(0xFFD4A843).withOpacity(0.80),
            fontSize: 13,
            letterSpacing: 5,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 28,
          height: 0.6,
          color: const Color(0xFFD4A843).withOpacity(0.55),
        ),
      ],
    );
  }

  // ── LOADING DOTS ────────────────────────────────────────────────

  Widget _buildLoadingDots() {
    return SizedBox(
      width: 48,
      height: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (i) {
          final delay = i / 3.0;
          final raw = (_dotsProgress.value - delay) * 3.0;
          final pulse = _pulseController.value;
          // Each dot pulses with staggered timing
          final dotOpacity = (0.25 + (i == (pulse * 3).floor() % 3 ? 0.75 : 0.0))
              .clamp(0.25, 1.0);
          return Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4A843).withOpacity(dotOpacity),
              boxShadow: dotOpacity > 0.7
                  ? [
                BoxShadow(
                  color: const Color(0xFFD4A843).withOpacity(0.5),
                  blurRadius: 6,
                )
              ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  // ── CORNER ACCENTS ──────────────────────────────────────────────

  Widget _buildCornerAccents(Size size) {
    final opacity = _taglineFade.value * 0.6;
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: _CornerAccentPainter(
            color: const Color(0xFFD4A843).withOpacity(0.30),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER TEXT PAINTER
// Paints a shimmer sweep over the NEXUS text
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerTextPainter extends CustomPainter {
  final String text;
  final double shimmerPosition; // -1.0 → 2.0
  final TextStyle baseStyle;

  _ShimmerTextPainter({
    required this.text,
    required this.shimmerPosition,
    required this.baseStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw base text in white
    final basePainter = TextPainter(
      text: TextSpan(text: text, style: baseStyle.copyWith(color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    basePainter.paint(canvas, Offset(
      (size.width - basePainter.width) / 2,
      (size.height - basePainter.height) / 2,
    ));

    // Draw shimmer overlay using a gradient mask
    final shimmerWidth = size.width * 0.45;
    final shimmerX = shimmerPosition * size.width;

    final shimmerGradient = LinearGradient(
      colors: [
        Colors.transparent,
        const Color(0xFFFFE088).withOpacity(0.55),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(
      shimmerX - shimmerWidth / 2,
      0,
      shimmerWidth,
      size.height,
    ));

    final shimmerPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: baseStyle.copyWith(
          foreground: Paint()..shader = shimmerGradient,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shimmerPainter.paint(canvas, Offset(
      (size.width - shimmerPainter.width) / 2,
      (size.height - shimmerPainter.height) / 2,
    ));
  }

  @override
  bool shouldRepaint(_ShimmerTextPainter old) =>
      old.shimmerPosition != shimmerPosition;
}

// ─────────────────────────────────────────────────────────────────────────────
// TICK MARK PAINTER — 4 small ticks at N/S/E/W of a circle
// ─────────────────────────────────────────────────────────────────────────────

class _TickMarkPainter extends CustomPainter {
  final Color color;
  _TickMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx;
    const tickLen = 8.0;

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final cos = math.cos(angle);
      final sin = math.sin(angle);
      canvas.drawLine(
        Offset(cx + cos * (r - tickLen), cy + sin * (r - tickLen)),
        Offset(cx + cos * r, cy + sin * r),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickMarkPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CORNER ACCENT PAINTER — L-shaped brackets at all 4 corners
// ─────────────────────────────────────────────────────────────────────────────

class _CornerAccentPainter extends CustomPainter {
  final Color color;
  _CornerAccentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const margin = 22.0;
    const len = 22.0;

    // Top-left
    canvas.drawPath(Path()
      ..moveTo(margin, margin + len)
      ..lineTo(margin, margin)
      ..lineTo(margin + len, margin), paint);
    // Top-right
    canvas.drawPath(Path()
      ..moveTo(size.width - margin - len, margin)
      ..lineTo(size.width - margin, margin)
      ..lineTo(size.width - margin, margin + len), paint);
    // Bottom-left
    canvas.drawPath(Path()
      ..moveTo(margin, size.height - margin - len)
      ..lineTo(margin, size.height - margin)
      ..lineTo(margin + len, size.height - margin), paint);
    // Bottom-right
    canvas.drawPath(Path()
      ..moveTo(size.width - margin - len, size.height - margin)
      ..lineTo(size.width - margin, size.height - margin)
      ..lineTo(size.width - margin, size.height - margin - len), paint);
  }

  @override
  bool shouldRepaint(_CornerAccentPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCAN LINE PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// PARTICLE PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SplashParticle {
  final double x, y, radius, speed, opacity, phase;
  final Color color;
  const _SplashParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
    required this.color,
  });
}

class _SplashParticlePainter extends CustomPainter {
  final List<_SplashParticle> particles;
  final double progress;

  _SplashParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress + p.phase) % 1.0);
      final y = (p.y - t * p.speed) % 1.0;
      final alpha = (math.sin(t * math.pi) * p.opacity).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.radius,
        Paint()
          ..color = p.color.withOpacity(alpha)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashParticlePainter old) => old.progress != progress;
}