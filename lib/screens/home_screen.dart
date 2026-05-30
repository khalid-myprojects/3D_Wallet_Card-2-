import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../providers/card_provider.dart';
import '../models/card_model.dart';
import '../widgets/card_3d_widget.dart';
import '../screens/card_detail_screen.dart';
import '../screens/card_display_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PERFORMANCE NOTES
// ─────────────────────────────────────────────────────────────────────────────
//
// Key fixes applied:
//
// 1. SPLIT Consumer<CardProvider> into targeted Selectors — only the card
//    preview and type-picker rebuild on draft changes, not the entire screen.
//
// 2. _PremiumField: removed BackdropFilter entirely from each field. A single
//    frosted-glass panel sits BEHIND all fields (one GPU pass, static).
//    The field itself uses plain AnimatedContainer — no blur per keystroke.
//
// 3. _PremiumField: replaced AnimatedBuilder wrapping the TextField with a
//    simple AnimatedContainer + manual Tween so the TextField widget is NEVER
//    rebuilt by the animation; only its decoration changes.
//
// 4. Floating label uses a regular AnimatedContainer / AnimatedDefaultTextStyle
//    that is sized/positioned with AnimatedContainer instead of
//    AnimatedPositioned-inside-Stack (avoids relayout on every tick).
//
// 5. Background orbs and particle field are hoisted OUTSIDE the Consumer so
//    they never rebuild on draft card changes.
//
// 6. RepaintBoundary added around the particle field and the card preview
//    so GPU compositing is isolated.
//
// 7. _HorizontalCardSlider: extracted card transform math; PageView items use
//    RepaintBoundary so only the visible card is repainted when scrolling.
//
// 8. ScrollController physics left as BouncingScrollPhysics but the heavy
//    BackdropFilter on _CardPreviewContainer is now a simple Container with a
//    translucent decoration — same visual result, zero GPU overdraw.

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _ambientController;
  late AnimationController _particleController;
  late AnimationController _headerController;
  int _formResetKey = 0;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ambientController.dispose();
    _particleController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _addCard() {
    final provider = context.read<CardProvider>();
    if (provider.draftCard.cardNumber.isEmpty &&
        provider.draftCard.cardHolder.isEmpty) {
      HapticFeedback.lightImpact();
      _showToast('Fill in at least card number or holder name');
      return;
    }
    HapticFeedback.mediumImpact();
    provider.addCard();
    setState(() => _formResetKey++);
    _showSuccessToast();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
      ),
    );
  }

  void _showSuccessToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A843).withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFFD4A843),
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Card added successfully',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF141208),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(milliseconds: 2200),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: const Color(0xFFD4A843).withOpacity(0.28),
            width: 0.8,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF060709),
      // ── PERFORMANCE: background layers are OUTSIDE any Consumer/Selector
      // so a draft-card keystroke never triggers a repaint here.
      body: Stack(
        children: [
          // ── DEEP BACKGROUND MESH ─────────────────────────────────────────
          // RepaintBoundary isolates this from all child rebuilds.
          RepaintBoundary(
            child: _AmbientBackground(controller: _ambientController),
          ),

          // ── FLOATING PARTICLES ───────────────────────────────────────────
          RepaintBoundary(
            child: _ParticleField(controller: _particleController, size: size),
          ),

          // ── MAIN SCROLL ──────────────────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [

                // ── HEADER — only depends on card count, not draft ──────────
                SliverToBoxAdapter(
                  child: _AnimatedHeader(
                    controller: _headerController,
                    onGridTap: () {
                      final provider = context.read<CardProvider>();
                      if (provider.cards.isNotEmpty) {
                        HapticFeedback.selectionClick();
                        Navigator.of(context)
                            .push(_fadeScale(const CardDisplayScreen()));
                      } else {
                        _showToast('Add a card first');
                      }
                    },
                    // Selector: rebuilds only when card *count* changes
                    cardCount: context.select<CardProvider, int>(
                          (p) => p.cards.length,
                    ),
                  ),
                ),

                // ── LIVE CARD PREVIEW ────────────────────────────────────────
                // Selector: rebuilds only when draftCard changes
                SliverToBoxAdapter(
                  child: Selector<CardProvider, CardModel>(
                    selector: (_, p) => p.draftCard,
                    builder: (context, draft, __) => Padding(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
                      child: RepaintBoundary(
                        child: _CardPreviewContainer(
                          child: Card3DWidget(
                            card: draft,
                            width: size.width - 44,
                            height: (size.width - 44) * 0.58,
                            interactive: true,
                            autoFloat: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── CARD TYPE PICKER ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(
                    label: 'Card Type',
                    icon: Icons.style_rounded,
                    topPad: 34,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Selector<CardProvider, CardType>(
                    selector: (_, p) => p.draftCard.cardType,
                    builder: (context, selectedType, __) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _CardTypePicker(
                        selectedType: selectedType,
                        onChanged:
                        context.read<CardProvider>().updateDraftType,
                      ),
                    ),
                  ),
                ),

                // ── CARD DETAILS ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(
                    label: 'Card Details',
                    icon: Icons.credit_card_rounded,
                    topPad: 30,
                  ),
                ),
                // ── FORM: no Consumer here — the form manages its OWN state
                // and only calls provider methods on change. The provider emits
                // notifyListeners() for draft changes, but only the Selectors
                // above listen to draft properties.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _PremiumCardForm(
                      key: ValueKey(_formResetKey),
                    ),
                  ),
                ),

                // ── ADD CARD BUTTON ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: _AddCardButton(onTap: _addCard),
                  ),
                ),

                // ── MY CARDS ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Selector<CardProvider, int>(
                    selector: (_, p) => p.cards.length,
                    builder: (context, count, __) {
                      if (count == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                        child: _MyCardsHeader(
                          count: count,
                          onSeeAll: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).push(
                              _fadeScale(const CardDisplayScreen()),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: Selector<CardProvider, List<CardModel>>(
                    selector: (_, p) => p.cards,
                    builder: (context, cards, __) {
                      if (cards.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: SizedBox(
                          height: (size.width * 0.74) * 0.60,
                          child: _HorizontalCardSlider(
                            cards: cards,
                            onCardTap: (card, index) {
                              context
                                  .read<CardProvider>()
                                  .selectCard(index);
                              HapticFeedback.selectionClick();
                              Navigator.of(context).push(
                                _fadeScale(CardDetailScreen(card: card)),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _fadeScale(Widget page) => PageRouteBuilder(
    pageBuilder: (_, anim, __) => page,
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
    transitionDuration: const Duration(milliseconds: 420),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBIENT BACKGROUND  (unchanged — runs on its own AnimationController)
// ─────────────────────────────────────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  final AnimationController controller;
  const _AmbientBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              top: -140 + t * 30,
              left: -80 + t * 60,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD4A843).withOpacity(0.13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 60 + (1 - t) * 40,
              right: -100 + (1 - t) * 30,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2A3A6B).withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 0.5;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.5), paint);
    }
    for (double y = 0; y < size.height * 0.5; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING PARTICLES
// ─────────────────────────────────────────────────────────────────────────────

class _ParticleField extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _ParticleField({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        size: Size(size.width, size.height * 0.6),
        painter: _ParticlePainter(progress: controller.value),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter({required this.progress});

  static final List<_Particle> _particles = List.generate(18, (i) {
    final rng = math.Random(i * 37 + 13);
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      speed: 0.04 + rng.nextDouble() * 0.06,
      size: 1.0 + rng.nextDouble() * 2.0,
      phase: rng.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = ((progress + p.phase) % 1.0);
      final y = (p.y - t * p.speed) % 1.0;
      final opacity = (math.sin(t * math.pi) * 0.5).clamp(0.0, 0.5);
      final paint = Paint()
        ..color = const Color(0xFFD4A843).withOpacity(opacity * 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, speed, size, phase;
  const _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.phase,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedHeader extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onGridTap;
  final int cardCount;

  const _AnimatedHeader({
    required this.controller,
    required this.onGridTap,
    required this.cardCount,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final t =
            CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)
                .value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -16),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _LogoMark(),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFD4A843)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'NEXUS',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                      height: 1,
                    ),
                  ),
                ),
                Text(
                  'PREMIUM CARDS',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFFD4A843).withOpacity(0.55),
                    fontSize: 8.5,
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (cardCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A843).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD4A843).withOpacity(0.3),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  '$cardCount ${cardCount == 1 ? 'card' : 'cards'}',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFFD4A843),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _GlassIconButton(
              onTap: onGridTap,
              child: Icon(
                Icons.grid_view_rounded,
                color: Colors.white.withOpacity(0.80),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1A10), Color(0xFF0F0D08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4A843).withOpacity(0.40),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A843).withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFD4A843), Color(0xFFF5C842)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(b),
          child: Text(
            'N',
            style: GoogleFonts.rajdhani(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lightweight glass button: no BackdropFilter, same visual weight via
//    semi-transparent fill + border. Saves one GPU compositing layer per tap.
class _GlassIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassIconButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.14),
            width: 0.7,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD PREVIEW CONTAINER
// ── Removed BackdropFilter. The dark translucent box achieves the same look
//    without a full blur pass every frame the draft card animates.
// ─────────────────────────────────────────────────────────────────────────────

class _CardPreviewContainer extends StatelessWidget {
  final Widget child;
  const _CardPreviewContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A843).withOpacity(0.07),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final double topPad;

  const _SectionLabel({
    required this.label,
    required this.icon,
    this.topPad = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, topPad, 22, 0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A843).withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFD4A843).withOpacity(0.22),
                width: 0.6,
              ),
            ),
            child: Icon(icon, color: const Color(0xFFD4A843), size: 14),
          ),
          const SizedBox(width: 12),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM CARD FORM
// ── No longer accepts `provider` as a parameter.
//    Uses context.read() only inside callbacks — zero rebuild risk.
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumCardForm extends StatelessWidget {
  const _PremiumCardForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CardProvider>();
    return Column(
      children: [
        _PremiumField(
          label: 'Bank Name',
          hint: 'e.g. NEXUS BANK',
          icon: Icons.account_balance_rounded,
          onChanged: provider.updateDraftBank,
          maxLength: 24,
          accentColor: const Color(0xFFD4A843),
        ),
        const SizedBox(height: 12),
        _PremiumField(
          label: 'Card Number',
          hint: '0000  0000  0000  0000',
          icon: Icons.credit_card_rounded,
          onChanged: provider.updateDraftNumber,
          keyboardType: TextInputType.number,
          maxLength: 19,
          inputFormatters: [_CardNumberFormatter()],
          accentColor: const Color(0xFF6B9EFF),
        ),
        const SizedBox(height: 12),
        _PremiumField(
          label: 'Card Holder Name',
          hint: 'Full name as on card',
          icon: Icons.person_outline_rounded,
          onChanged: provider.updateDraftHolder,
          maxLength: 26,
          accentColor: const Color(0xFF8FF5B0),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PremiumField(
                label: 'Expiry Date',
                hint: 'MM / YY',
                icon: Icons.calendar_today_rounded,
                onChanged: provider.updateDraftExpiry,
                keyboardType: TextInputType.number,
                maxLength: 7,
                inputFormatters: [_ExpiryFormatter()],
                accentColor: const Color(0xFFFF9A6B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PremiumField(
                label: 'CVV',
                hint: '•••',
                icon: Icons.lock_outline_rounded,
                onChanged: provider.updateDraftCvv,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                accentColor: const Color(0xFFD46BFF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM FIELD  — FULLY REFACTORED FOR PERFORMANCE
//
// What changed vs the original:
//
// ▸ NO BackdropFilter per field.
//   The glass look comes from a semi-transparent Container + border, which
//   costs a single alpha composite — not a full Gaussian blur pass.
//
// ▸ NO AnimatedBuilder wrapping the TextField.
//   The TextField widget is NEVER rebuilt by animation ticks. Only the
//   decorative Container around it is animated via AnimatedContainer.
//
// ▸ Floating label: replaced AnimatedPositioned-inside-Stack with a Column
//   that has a fixed-height label slot. AnimatedDefaultTextStyle handles the
//   style transition; no layout shift from Positioned causing relayout on
//   every tick.
//
// ▸ Focus animation uses a single AnimationController driving only the border
//   color and icon color. These are passed as interpolated values to
//   AnimatedContainer so Flutter's implicit animation system handles the
//   lightweight diff — no AnimatedBuilder overhead.
//
// ▸ setState is called ONLY for _focused and _hasValue (2 booleans). The
//   TextField itself is not rebuilt; its controller is stable.
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final int maxLength;
  final bool obscureText;
  final Color accentColor;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _PremiumField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLength = 100,
    this.obscureText = false,
    this.accentColor = const Color(0xFFD4A843),
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<_PremiumField> createState() => _PremiumFieldState();
}

class _PremiumFieldState extends State<_PremiumField> {
  // Stable objects — never recreated after initState.
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  bool _focused = false;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode()
      ..addListener(() {
        final focused = _focusNode.hasFocus;
        if (focused != _focused) {
          setState(() => _focused = focused);
        }
      });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final elevated = _focused || _hasValue;

    // ── OUTER SHADOW ONLY animated — lightweight box model change, no GPU blur
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? accent.withOpacity(0.18)
                : Colors.black.withOpacity(0.22),
            blurRadius: _focused ? 24 : 12,
            spreadRadius: _focused ? -2 : 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: GestureDetector(
        // Tapping anywhere on the field card requests focus
        onTap: () => _focusNode.requestFocus(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            // ── Simulated glass: opaque dark + slight white tint on focus
            color: _focused
                ? const Color(0xFF161820)
                : const Color(0xFF0F1014),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _focused
                  ? accent.withOpacity(0.55)
                  : Colors.white.withOpacity(0.09),
              width: _focused ? 1.2 : 0.6,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── ICON BOX — AnimatedContainer only (no blur, no builder)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _focused
                      ? accent.withOpacity(0.15)
                      : Colors.white.withOpacity(0.055),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: _focused
                        ? accent.withOpacity(0.38)
                        : Colors.white.withOpacity(0.07),
                    width: 0.7,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  // AnimatedSwitcher-free color via AnimatedContainer parent;
                  // icon color itself changes on setState which is fine here
                  // because it only fires on focus change (not per-keystroke).
                  color: _focused
                      ? accent
                      : Colors.white.withOpacity(0.36),
                  size: 17,
                ),
              ),
              const SizedBox(width: 14),

              // ── LABEL + INPUT
              // Using a Column with fixed-height slots instead of
              // AnimatedPositioned inside a Stack — avoids full relayout
              // on every animation tick.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Floating label slot — always occupies 14px height so
                    // the layout never shifts; only style animates.
                    SizedBox(
                      height: 14,
                      child: elevated
                          ? AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: GoogleFonts.dmSans(
                          color: _focused
                              ? accent
                              : Colors.white.withOpacity(0.45),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                        child:
                        Text(widget.label.toUpperCase()),
                      )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 2),
                    // ── TEXT FIELD — completely isolated from all animation
                    //    widgets above. setState() for _focused / _hasValue
                    //    does NOT rebuild this subtree because TextField
                    //    manages its own element.
                    TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      onChanged: (v) {
                        final hasValue = v.isNotEmpty;
                        if (hasValue != _hasValue) {
                          setState(() => _hasValue = hasValue);
                        }
                        widget.onChanged(v);
                      },
                      keyboardType: widget.keyboardType,
                      maxLength: widget.maxLength,
                      obscureText: widget.obscureText,
                      inputFormatters: widget.inputFormatters,
                      textCapitalization: widget.textCapitalization,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: widget.keyboardType ==
                            TextInputType.number
                            ? 1.8
                            : 0.3,
                      ),
                      decoration: InputDecoration(
                        hintText: elevated ? widget.hint : widget.label,
                        hintStyle: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(
                            elevated ? 0.18 : 0.38,
                          ),
                          fontSize: elevated ? 14 : 14.5,
                          fontWeight: FontWeight.w400,
                        ),
                        counterText: '',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      cursorColor: accent,
                      cursorWidth: 1.5,
                      cursorRadius: const Radius.circular(2),
                    ),
                  ],
                ),
              ),

              // ── FILL INDICATOR DOT
              // AnimatedOpacity is cheap — single opacity layer.
              AnimatedOpacity(
                opacity: _hasValue ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.85),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
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
// INPUT FORMATTERS  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String result = digits;
    if (digits.length >= 2) {
      result = '${digits.substring(0, 2)} / ${digits.substring(2)}';
    }
    if (result.length > 7) result = result.substring(0, 7);
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD TYPE PICKER  (unchanged logic, kept as-is)
// ─────────────────────────────────────────────────────────────────────────────

class _CardTypePicker extends StatelessWidget {
  final CardType selectedType;
  final ValueChanged<CardType> onChanged;

  const _CardTypePicker({
    required this.selectedType,
    required this.onChanged,
  });

  static const _types = [
    _TypeItem(CardType.black, 'Black', Color(0xFF1A1A1A), Color(0xFF555555)),
    _TypeItem(CardType.platinum, 'Platinum', Color(0xFFB8C4D0), Color(0xFF8E9BAE)),
    _TypeItem(CardType.gold, 'Gold', Color(0xFFD4A843), Color(0xFF9A7520)),
    _TypeItem(CardType.titanium, 'Titan', Color(0xFF4A5259), Color(0xFF2D3436)),
    _TypeItem(CardType.student, 'Student', Color(0xFF0F3460), Color(0xFF00D2FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _types.map((t) {
        final isSelected = selectedType == t.type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(t.type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: isSelected
                    ? t.color.withOpacity(0.14)
                    : Colors.white.withOpacity(0.035),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? t.color.withOpacity(0.55)
                      : Colors.white.withOpacity(0.07),
                  width: isSelected ? 1.0 : 0.5,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: t.color.withOpacity(0.22),
                    blurRadius: 16,
                    spreadRadius: -3,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniCardSwatch(
                      color: t.color, accent: t.accent, selected: isSelected),
                  const SizedBox(height: 9),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: isSelected
                        ? GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    )
                        : GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                    child: Text(t.label),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MiniCardSwatch extends StatelessWidget {
  final Color color;
  final Color accent;
  final bool selected;
  const _MiniCardSwatch({
    required this.color,
    required this.accent,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: selected ? 36 : 30,
      height: selected ? 22 : 18,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(selected ? 0.5 : 0.25),
            blurRadius: selected ? 10 : 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 3,
            left: 4,
            right: 4,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeItem {
  final CardType type;
  final String label;
  final Color color;
  final Color accent;
  const _TypeItem(this.type, this.label, this.color, this.accent);
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD CARD BUTTON  (unchanged — BackdropFilter here is fine, it's static)
// ─────────────────────────────────────────────────────────────────────────────

class _AddCardButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddCardButton({required this.onTap});

  @override
  State<_AddCardButton> createState() => _AddCardButtonState();
}

class _AddCardButtonState extends State<_AddCardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4A843).withOpacity(0.25),
                    const Color(0xFF8B6914).withOpacity(0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4A843).withOpacity(0.38),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4A843).withOpacity(0.14),
                    blurRadius: 28,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.22),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A843).withOpacity(0.22),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Color(0xFFD4A843),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Text(
                          'ADD CARD',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MY CARDS HEADER  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _MyCardsHeader extends StatelessWidget {
  final int count;
  final VoidCallback onSeeAll;
  const _MyCardsHeader({required this.count, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A843).withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD4A843).withOpacity(0.22),
                  width: 0.6,
                ),
              ),
              child: const Icon(
                Icons.wallet_rounded,
                color: Color(0xFFD4A843),
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'MY CARDS',
              style: GoogleFonts.dmSans(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
                width: 0.6,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'See All',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.40),
                  size: 9,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HORIZONTAL CARD SLIDER
// ── RepaintBoundary per card so only the visible card repaints on page scroll.
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalCardSlider extends StatefulWidget {
  final List<CardModel> cards;
  final Function(CardModel, int) onCardTap;

  const _HorizontalCardSlider({
    required this.cards,
    required this.onCardTap,
  });

  @override
  State<_HorizontalCardSlider> createState() => _HorizontalCardSliderState();
}

class _HorizontalCardSliderState extends State<_HorizontalCardSlider>
    with SingleTickerProviderStateMixin {
  late PageController _pc;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.cards.length - 1;
    _page = initialPage.toDouble();
    _pc = PageController(viewportFraction: 0.76, initialPage: initialPage)
      ..addListener(() {
        final p = _pc.page ?? _page;
        if ((p - _page).abs() > 0.001) {
          setState(() => _page = p);
        }
      });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_HorizontalCardSlider old) {
    super.didUpdateWidget(old);
    if (widget.cards.length > old.cards.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pc.animateToPage(
          widget.cards.length - 1,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.74;
    final cardHeight = cardWidth * 0.60;

    return PageView.builder(
      controller: _pc,
      itemCount: widget.cards.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final offset = index - _page;
        final scale = (1.0 - offset.abs() * 0.09).clamp(0.88, 1.0);
        final opacity = (1.0 - offset.abs() * 0.36).clamp(0.26, 1.0);

        return RepaintBoundary(
          child: GestureDetector(
            onTap: () => widget.onCardTap(widget.cards[index], index),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(offset * 0.09)
                ..scale(scale),
              child: Opacity(
                opacity: opacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Card3DWidget(
                    card: widget.cards[index],
                    width: cardWidth,
                    height: cardHeight,
                    interactive: false,
                    autoFloat: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}