import 'package:flutter/material.dart' hide CardThemeData;
import 'dart:math' as math;
import '../models/card_model.dart';
import '../painters/card_painter.dart';
import 'package:google_fonts/google_fonts.dart';

class Card3DWidget extends StatefulWidget {
  final CardModel card;
  final double width;
  final double height;
  final bool interactive;
  final bool autoFloat;
  final bool showCvv;

  const Card3DWidget({
    super.key,
    required this.card,
    this.width = 360,
    this.height = 220,
    this.interactive = true,
    this.autoFloat = true,
    this.showCvv = false,
  });

  @override
  State<Card3DWidget> createState() => _Card3DWidgetState();
}

class _Card3DWidgetState extends State<Card3DWidget>
    with TickerProviderStateMixin {
  double _tiltX = 0;
  double _tiltY = 0;
  double _targetTiltX = 0;
  double _targetTiltY = 0;

  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late AnimationController _entranceController;
  late Animation<double> _floatAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _shimmerAnim =
        Tween<double>(begin: 0.0, end: 1.0).animate(_shimmerController);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _floatController.addListener(() {
      if (!_isHovered) {
        setState(() {
          _tiltX = _lerp(_tiltX, _targetTiltX, 0.08);
          _tiltY = _lerp(_tiltY, _targetTiltY, 0.08);
        });
      }
    });
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void dispose() {
    _floatController.dispose();
    _shimmerController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event, BoxConstraints constraints) {
    if (!widget.interactive) return;
    setState(() {
      _isHovered = true;
      _targetTiltY =
          ((event.localPosition.dx / constraints.maxWidth) - 0.5) * 2 * 0.4;
      _targetTiltX =
          -((event.localPosition.dy / constraints.maxHeight) - 0.5) * 2 * 0.3;
      _tiltX = _lerp(_tiltX, _targetTiltX, 0.15);
      _tiltY = _lerp(_tiltY, _targetTiltY, 0.15);
    });
  }

  void _onPointerExit(PointerEvent event) {
    setState(() {
      _isHovered = false;
      _targetTiltX = 0;
      _targetTiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = cardThemes[widget.card.cardType]!;

    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnim, _scaleAnim, _fadeAnim]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Transform.translate(
              offset:
              widget.autoFloat ? Offset(0, _floatAnim.value) : Offset.zero,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return MouseRegion(
                    onHover: (e) => _onPointerMove(e, constraints),
                    onExit: _onPointerExit,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        if (!widget.interactive) return;
                        setState(() {
                          _isHovered = true;
                          _targetTiltY +=
                              details.delta.dx / widget.width * 0.8;
                          _targetTiltX -=
                              details.delta.dy / widget.height * 0.8;
                          _targetTiltY = _targetTiltY.clamp(-0.5, 0.5);
                          _targetTiltX = _targetTiltX.clamp(-0.4, 0.4);
                          _tiltX = _lerp(_tiltX, _targetTiltX, 0.2);
                          _tiltY = _lerp(_tiltY, _targetTiltY, 0.2);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _isHovered = false;
                          _targetTiltX = 0;
                          _targetTiltY = 0;
                        });
                      },
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0015)
                          ..rotateX(_tiltX)
                          ..rotateY(_tiltY),
                        child: _buildCardFace(theme),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFace(CardThemeData theme) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColors.last.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: -5,
            offset: Offset(_tiltY * 20, 20 + _tiltX * 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: -8,
            offset: Offset(_tiltY * 10, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Base metallic paint
            AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: CardMetallicPainter(
                    colors: theme.primaryColors,
                    shineColors: theme.shineColors,
                    tiltX: _tiltX,
                    tiltY: _tiltY,
                    metalness: theme.metalness,
                    shimmerAnim: _shimmerAnim,
                  ),
                );
              },
            ),

            // Holographic overlay for student card
            if (widget.card.cardType == CardType.student)
              _buildHolographicOverlay(),

            // Card content
            // ── FIX: padding reduced from 24 → 16 on all sides so the taller
            //    text has enough vertical room inside the fixed card height.
            //    SizedBox gaps also tightened from 16 → 10 between sections.
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: bank name + network logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.card.displayBank,
                        style: GoogleFonts.rajdhani(
                          color: theme.textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                      _buildNetworkLogo(theme),
                    ],
                  ),

                  const SizedBox(height: 10), // was 16

                  // Chip + contactless
                  Row(
                    children: [
                      _buildChip(theme),
                      const SizedBox(width: 12),
                      _buildContactless(theme),
                    ],
                  ),

                  const Spacer(),

                  // Card number
                  Text(
                    widget.card.formattedNumber,
                    style: GoogleFonts.shareTech(
                      color: theme.textColor,
                      fontSize: 20,
                      letterSpacing: 2.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 10), // was 16

                  // Holder + expiry row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: GoogleFonts.rajdhani(
                              color: theme.subtleColor,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            widget.card.displayHolder,
                            style: GoogleFonts.rajdhani(
                              color: theme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPIRES',
                            style: GoogleFonts.rajdhani(
                              color: theme.subtleColor,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            widget.card.displayExpiry,
                            style: GoogleFonts.rajdhani(
                              color: theme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      // Card type label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.subtleColor.withOpacity(0.4),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          theme.label,
                          style: GoogleFonts.rajdhani(
                            color: theme.subtleColor,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tilt-based specular highlight
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHovered ? 1 : 0.3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      center: Alignment(
                        _tiltY * 2,
                        -_tiltX * 2,
                      ),
                      radius: 0.9,
                      colors: [
                        Colors.white.withOpacity(0.12 * theme.metalness),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolographicOverlay() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_shimmerAnim.value * math.pi * 2),
                math.sin(_shimmerAnim.value * math.pi * 2),
              ),
              end: Alignment(
                -math.cos(_shimmerAnim.value * math.pi * 2),
                -math.sin(_shimmerAnim.value * math.pi * 2),
              ),
              colors: [
                Colors.transparent,
                const Color(0xFF00D2FF).withOpacity(0.06),
                const Color(0xFF7B2FFF).withOpacity(0.04),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(CardThemeData theme) {
    return SizedBox(
      width: 42,
      height: 32,
      child: CustomPaint(
        painter: ChipPainter(
          baseColor: widget.card.cardType == CardType.black
              ? const Color(0xFF2A2A2A)
              : widget.card.cardType == CardType.gold
              ? const Color(0xFFD4A843).withOpacity(0.6)
              : const Color(0xFFB0B8C4).withOpacity(0.7),
          lineColor: theme.textColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildContactless(CardThemeData theme) {
    return Icon(
      Icons.wifi,
      color: theme.textColor.withOpacity(0.6),
      size: 16,
    );
  }

  Widget _buildNetworkLogo(CardThemeData theme) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.7),
          ),
        ),
        Transform.translate(
          offset: const Offset(-10, 0),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}