import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../providers/card_provider.dart';
import '../widgets/card_3d_widget.dart';
import '../screens/card_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class CardDisplayScreen extends StatefulWidget {
  const CardDisplayScreen({super.key});

  @override
  State<CardDisplayScreen> createState() => _CardDisplayScreenState();
}

class _CardDisplayScreenState extends State<CardDisplayScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0;

  // Animation controllers
  late AnimationController _orbController;      // slow drifting orbs
  late AnimationController _particleController; // floating particles
  late AnimationController _entryController;    // screen entrance
  late AnimationController _cardFloatController; // card bob + tilt

  // Entry animations
  late Animation<double> _headerFade;
  late Animation<double> _headerSlide;
  late Animation<double> _cardEntryFade;
  late Animation<double> _cardEntryScale;
  late Animation<double> _dotsEntryFade;
  late Animation<double> _infoEntryFade;

  // Card float
  late Animation<double> _floatY;
  late Animation<double> _floatTilt;

  late List<_BgParticle> _particles;

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _setupControllers();
    _setupAnimations();
    _entryController.forward();
  }

  void _generateParticles() {
    final rng = math.Random(99);
    _particles = List.generate(40, (i) => _BgParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: rng.nextDouble() * 1.6 + 0.3,
      speed: rng.nextDouble() * 0.30 + 0.06,
      opacity: rng.nextDouble() * 0.45 + 0.05,
      phase: rng.nextDouble(),
      color: [
        Colors.white,
        const Color(0xFFD4A843),
        const Color(0xFF9BB8D4),
      ][rng.nextInt(3)],
    ));
  }

  void _setupControllers() {
    _pageController = PageController(viewportFraction: 0.82)
      ..addListener(() => setState(() => _currentPage = _pageController.page ?? 0));

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  void _setupAnimations() {
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.0, 0.55, curve: Curves.easeOut)),
    );
    _headerSlide = Tween<double>(begin: -18.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic)),
    );
    _cardEntryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.2, 0.75, curve: Curves.easeOut)),
    );
    _cardEntryScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.2, 0.80, curve: Curves.easeOutCubic)),
    );
    _dotsEntryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
    );
    _infoEntryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.60, 1.0, curve: Curves.easeOut)),
    );

    // Gentle float: card bobs up/down 8px, slight tilt
    _floatY = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _cardFloatController, curve: Curves.easeInOut),
    );
    _floatTilt = Tween<double>(begin: -0.018, end: 0.018).animate(
      CurvedAnimation(parent: _cardFloatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _orbController.dispose();
    _particleController.dispose();
    _entryController.dispose();
    _cardFloatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();
    final cards = provider.cards;
    final size = MediaQuery.of(context).size;
    final currentIndex = _currentPage.round().clamp(0, cards.isEmpty ? 0 : cards.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF040507),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _orbController, _particleController,
          _entryController, _cardFloatController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // ── LAYER 1: AMBIENT ORBS ─────────────────────
              _AmbientOrbs(
                controller: _orbController,
                size: size,
                accentColor: cards.isNotEmpty
                    ? _cardAccentColor(cards[currentIndex].cardType)
                    : const Color(0xFFD4A843),
              ),

              // ── LAYER 2: PARTICLES ────────────────────────
              CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              ),

              // ── LAYER 3: GRID ─────────────────────────────
              Opacity(
                opacity: 0.022,
                child: CustomPaint(
                  size: size,
                  painter: _GridPainter(),
                ),
              ),

              // ── LAYER 4: VIGNETTE ─────────────────────────
              _Vignette(),

              // ── LAYER 5: UI ───────────────────────────────
              SafeArea(
                child: Column(
                  children: [

                    // ── HEADER ────────────────────────────────
                    Transform.translate(
                      offset: Offset(0, _headerSlide.value),
                      child: Opacity(
                        opacity: _headerFade.value,
                        child: _Header(
                          cardCount: cards.length,
                          currentIndex: currentIndex,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ── CARD STACK ────────────────────────────
                    if (cards.isEmpty)
                      _EmptyState()
                    else
                      Opacity(
                        opacity: _cardEntryFade.value,
                        child: Transform.scale(
                          scale: _cardEntryScale.value,
                          child: _CardStack(
                            cards: cards,
                            size: size,
                            currentPage: _currentPage,
                            pageController: _pageController,
                            floatY: _floatY.value,
                            floatTilt: _floatTilt.value,
                            onCardTap: (index) {
                              provider.selectCard(index);
                              HapticFeedback.selectionClick();
                              Navigator.of(context).push(PageRouteBuilder(
                                pageBuilder: (_, anim, __) =>
                                    CardDetailScreen(card: cards[index]),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(
                                      opacity: anim,
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.93, end: 1.0)
                                            .animate(CurvedAnimation(
                                            parent: anim,
                                            curve: Curves.easeOutCubic)),
                                        child: child,
                                      ),
                                    ),
                                transitionDuration:
                                const Duration(milliseconds: 420),
                              ));
                            },
                          ),
                        ),
                      ),

                    const Spacer(),

                    // ── CARD INFO CHIP ────────────────────────
                    if (cards.isNotEmpty)
                      Opacity(
                        opacity: _infoEntryFade.value,
                        child: _CardInfoChip(
                          card: cards[currentIndex],
                          index: currentIndex,
                          total: cards.length,
                        ),
                      ),

                    const SizedBox(height: 18),

                    // ── PAGE DOTS ─────────────────────────────
                    if (cards.isNotEmpty)
                      Opacity(
                        opacity: _dotsEntryFade.value,
                        child: _PageDots(
                          count: cards.length,
                          currentPage: _currentPage,
                          accentColor: cards.isNotEmpty
                              ? _cardAccentColor(cards[currentIndex].cardType)
                              : const Color(0xFFD4A843),
                        ),
                      ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _cardAccentColor(dynamic cardType) {
    // Map card types to accent colors matching the card type picker
    final map = {
      'black': const Color(0xFF888888),
      'platinum': const Color(0xFFB8C4D0),
      'gold': const Color(0xFFD4A843),
      'titanium': const Color(0xFF6A7580),
      'student': const Color(0xFF00D2FF),
    };
    return map[cardType?.toString().split('.').last] ?? const Color(0xFFD4A843);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBIENT ORBS
// ─────────────────────────────────────────────────────────────────────────────

class _AmbientOrbs extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  final Color accentColor;
  const _AmbientOrbs({
    required this.controller,
    required this.size,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = controller.value;
    return Stack(
      children: [
        // Primary large orb — top center, drifts left/right
        Positioned(
          top: -size.height * 0.12 + t * 40,
          left: size.width * 0.05 + t * 50,
          child: _OrbBlob(
            width: size.width * 0.85,
            height: size.width * 0.85,
            color: accentColor.withOpacity(0.10),
          ),
        ),
        // Secondary orb — bottom right
        Positioned(
          bottom: -size.height * 0.08 + (1 - t) * 30,
          right: -size.width * 0.15 + (1 - t) * 20,
          child: _OrbBlob(
            width: size.width * 0.65,
            height: size.width * 0.65,
            color: const Color(0xFF1A2B5A).withOpacity(0.14),
          ),
        ),
        // Small accent orb — top right
        Positioned(
          top: size.height * 0.06 + t * 20,
          right: size.width * 0.0 + t * 10,
          child: _OrbBlob(
            width: size.width * 0.42,
            height: size.width * 0.42,
            color: accentColor.withOpacity(0.06),
          ),
        ),
      ],
    );
  }
}

class _OrbBlob extends StatelessWidget {
  final double width, height;
  final Color color;
  const _OrbBlob({required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIGNETTE — darkens edges for cinematic depth
// ─────────────────────────────────────────────────────────────────────────────

class _Vignette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.55),
              ],
              stops: const [0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRID PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// PARTICLE PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _BgParticle {
  final double x, y, radius, speed, opacity, phase;
  final Color color;
  const _BgParticle({
    required this.x, required this.y, required this.radius,
    required this.speed, required this.opacity, required this.phase,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_BgParticle> particles;
  final double progress;
  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress + p.phase) % 1.0);
      final y = (p.y - t * p.speed) % 1.0;
      final alpha = (math.sin(t * math.pi) * p.opacity).clamp(0.0, 0.8);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.radius,
        Paint()..color = p.color.withOpacity(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int cardCount;
  final int currentIndex;
  final VoidCallback onBack;

  const _Header({
    required this.cardCount,
    required this.currentIndex,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onBack();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 0.7,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white.withOpacity(0.75),
                    size: 15,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Title block
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'MY WALLET',
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${currentIndex + 1}  OF  $cardCount',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFFD4A843).withOpacity(0.65),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Placeholder to balance back button
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD STACK — PageView with 3D perspective + independent float animation
// ─────────────────────────────────────────────────────────────────────────────

class _CardStack extends StatelessWidget {
  final List<dynamic> cards;
  final Size size;
  final double currentPage;
  final PageController pageController;
  final double floatY;
  final double floatTilt;
  final ValueChanged<int> onCardTap;

  const _CardStack({
    required this.cards,
    required this.size,
    required this.currentPage,
    required this.pageController,
    required this.floatY,
    required this.floatTilt,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = size.width * 0.82;
    final cardHeight = cardWidth * 0.60;

    return SizedBox(
      // Extra height to accommodate the float travel range
      height: cardHeight + 40,
      child: PageView.builder(
        controller: pageController,
        itemCount: cards.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final offset = index - currentPage;
          final absOffset = offset.abs();

          // Perspective scale: center card is full size
          final scale = (1.0 - absOffset * 0.10).clamp(0.82, 1.0);
          // Opacity: side cards dim
          final opacity = (1.0 - absOffset * 0.38).clamp(0.28, 1.0);
          // Y-axis 3D rotation based on page offset
          final rotY = offset * 0.22;
          // Vertical shift: side cards drop slightly
          final shiftY = absOffset * 18.0;

          // Float applies only to the active (center) card
          final isCenter = absOffset < 0.5;
          final cardFloat = isCenter ? floatY * (1.0 - absOffset * 2) : 0.0;
          final cardTilt = isCenter ? floatTilt * (1.0 - absOffset * 2) : 0.0;

          return GestureDetector(
            onTap: () => onCardTap(index),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)   // perspective
                ..rotateY(rotY)
                ..rotateZ(cardTilt)
                ..translate(0.0, shiftY + cardFloat)
                ..scale(scale),
              child: Opacity(
                opacity: opacity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Drop shadow beneath card (separate from card widget)
                    _CardShadow(
                      width: cardWidth * scale,
                      accentColor: _typeColor(cards[index].cardType),
                      isActive: isCenter,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Card3DWidget(
                        card: cards[index],
                        width: cardWidth,
                        height: cardHeight,
                        interactive: isCenter,
                        autoFloat: false, // we handle float ourselves
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _typeColor(dynamic cardType) {
    final map = {
      'black': const Color(0xFF555555),
      'platinum': const Color(0xFFB8C4D0),
      'gold': const Color(0xFFD4A843),
      'titanium': const Color(0xFF6A7580),
      'student': const Color(0xFF00D2FF),
    };
    return map[cardType?.toString().split('.').last] ?? const Color(0xFFD4A843);
  }
}

// Drop shadow rendered separately so it can be offset independently
class _CardShadow extends StatelessWidget {
  final double width;
  final Color accentColor;
  final bool isActive;

  const _CardShadow({
    required this.width,
    required this.accentColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      child: Container(
        width: width * 0.70,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isActive ? 0.28 : 0.10),
              blurRadius: isActive ? 40 : 20,
              spreadRadius: isActive ? 4 : 0,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD INFO CHIP — shows holder name + masked number
// ─────────────────────────────────────────────────────────────────────────────

class _CardInfoChip extends StatelessWidget {
  final dynamic card;
  final int index;
  final int total;

  const _CardInfoChip({
    required this.card,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // Extract last 4 digits of card number
    final num = (card.cardNumber as String).replaceAll(RegExp(r'\s'), '');
    final last4 = num.length >= 4 ? num.substring(num.length - 4) : '••••';
    final holder = (card.cardHolder as String).isEmpty
        ? 'CARD HOLDER'
        : (card.cardHolder as String).toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Holder name
              Text(
                holder,
                style: GoogleFonts.dmSans(
                  color: Colors.white.withOpacity(0.80),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                width: 0.6,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withOpacity(0.20),
              ),
              // Masked number
              Text(
                '••••  $last4',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFFD4A843).withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE DOTS — pill indicator with accent color
// ─────────────────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final double currentPage;
  final Color accentColor;

  const _PageDots({
    required this.count,
    required this.currentPage,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentPage.round();
        final dist = (i - currentPage).abs();
        final nearness = (1.0 - dist).clamp(0.0, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: isActive ? 28 : (nearness > 0.5 ? 8 : 6),
          height: 4,
          decoration: BoxDecoration(
            color: isActive
                ? accentColor
                : Colors.white.withOpacity(0.18 + nearness * 0.10),
            borderRadius: BorderRadius.circular(3),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: accentColor.withOpacity(0.55),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ]
                : null,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.6,
            ),
          ),
          child: Icon(
            Icons.credit_card_off_rounded,
            color: Colors.white.withOpacity(0.20),
            size: 24,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'NO CARDS YET',
          style: GoogleFonts.rajdhani(
            color: Colors.white.withOpacity(0.20),
            fontSize: 13,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add your first card from the home screen',
          style: GoogleFonts.dmSans(
            color: Colors.white.withOpacity(0.12),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}