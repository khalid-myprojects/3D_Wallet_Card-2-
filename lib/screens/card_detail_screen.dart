import 'package:flutter/material.dart' hide CardThemeData;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_model.dart';
import '../widgets/card_3d_widget.dart';
import 'dart:math' as math;
import 'dart:ui';

class CardDetailScreen extends StatefulWidget {
  final CardModel card;
  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen>
    with TickerProviderStateMixin {
  int _currentPanel = 0;
  late PageController _panelController;
  late AnimationController _bgController;
  late AnimationController _floatController;
  late AnimationController _entranceController;
  late Animation<double> _bgAnim;
  late Animation<double> _floatY;
  late Animation<double> _panelSlide;
  late Animation<double> _panelFade;

  final List<Map<String, dynamic>> _panels = [
    {'title': 'Card Info',   'icon': Icons.credit_card_rounded},
    {'title': 'Issuer',      'icon': Icons.account_balance_rounded},
    {'title': 'Limits',      'icon': Icons.trending_up_rounded},
    {'title': 'Security',    'icon': Icons.shield_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _panelController = PageController();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
    _floatY = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _panelSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _panelFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    _bgController.dispose();
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _switchPanel(int i) {
    HapticFeedback.selectionClick();
    setState(() => _currentPanel = i);
    _panelController.animateToPage(
      i,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = cardThemes[widget.card.cardType]!;
    final size = MediaQuery.of(context).size;
    final accent = theme.primaryColors[1];

    return Scaffold(
      backgroundColor: const Color(0xFF07080C),
      body: Stack(
        children: [
          // ── ANIMATED AMBIENT BACKGROUND ──────────────────
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    math.cos(_bgAnim.value * math.pi) * 0.4,
                    -0.5 + math.sin(_bgAnim.value * math.pi) * 0.2,
                  ),
                  radius: 1.4,
                  colors: [
                    accent.withOpacity(0.18),
                    const Color(0xFF07080C),
                  ],
                ),
              ),
            ),
          ),

          // Second soft orb bottom
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => Positioned(
              bottom: -80,
              left: size.width * 0.1,
              right: size.width * 0.1,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.10),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BACK BUTTON ───────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _IOSBackButton(onTap: () => Navigator.of(context).pop()),
                  // Card type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withOpacity(0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      theme.label,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── FLOATING CARD ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: size.height * 0.46,
            child: AnimatedBuilder(
              animation: _floatY,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _floatY.value),
                child: Center(
                  child: Card3DWidget(
                    card: widget.card,
                    width: size.width * 0.86,
                    height: size.width * 0.86 * 0.60,
                    interactive: true,
                    autoFloat: false,
                  ),
                ),
              ),
            ),
          ),

          // ── BOTTOM PANEL ──────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.48,
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _panelSlide.value),
                child: Opacity(opacity: _panelFade.value, child: child),
              ),
              child: Column(
                children: [
                  // ── SEGMENTED CONTROL (iOS style) ─────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _IOSSegmentedControl(
                      panels: _panels,
                      selectedIndex: _currentPanel,
                      accent: accent,
                      onTap: _switchPanel,
                    ),
                  ),

                  // ── SCROLLABLE PANEL CONTENT ──────────────
                  Expanded(
                    child: PageView(
                      controller: _panelController,
                      onPageChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _currentPanel = i);
                      },
                      children: [
                        _buildCardInfoPanel(theme, accent),
                        _buildIssuerPanel(theme, accent),
                        _buildLimitsPanel(theme, accent),
                        _buildSecurityPanel(theme, accent),
                      ],
                    ),
                  ),

                  // ── PAGE DOTS ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32, top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_panels.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPanel ? 24 : 5,
                          height: 3,
                          decoration: BoxDecoration(
                            color: i == _currentPanel
                                ? Colors.white
                                : Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PANEL BUILDERS ─────────────────────────────────────────

  Widget _buildCardInfoPanel(CardThemeData theme, Color accent) {
    final card = widget.card;
    return _PanelSheet(
      accent: accent,
      rows: [
        _RowData('Card Number', card.formattedNumber, Icons.numbers_rounded),
        _RowData('Card Holder', card.displayHolder, Icons.person_rounded),
        _RowData('Expiry Date', card.displayExpiry, Icons.calendar_month_rounded),
        _RowData('Card Type',   theme.label,         Icons.style_rounded),
        _RowData('Network',     'MASTERCARD',         Icons.credit_score_rounded),
      ],
    );
  }

  Widget _buildIssuerPanel(CardThemeData theme, Color accent) {
    return _PanelSheet(
      accent: accent,
      rows: [
        _RowData('Issuing Bank', widget.card.displayBank, Icons.account_balance_rounded),
        _RowData('Country',      'INTERNATIONAL',          Icons.language_rounded),
        _RowData('Currency',     'MULTI-CURRENCY',         Icons.currency_exchange_rounded),
        _RowData('Card Tier',    theme.label,              Icons.workspace_premium_rounded),
        _RowData('Support',      '+1 800 NEXUS',           Icons.headset_mic_rounded),
      ],
    );
  }

  Widget _buildLimitsPanel(CardThemeData theme, Color accent) {
    return _PanelSheet(
      accent: accent,
      rows: [
        _RowData('Daily Limit',    '\$25,000',      Icons.today_rounded),
        _RowData('Monthly Limit',  '\$100,000',     Icons.date_range_rounded),
        _RowData('ATM Limit',      '\$5,000 / day', Icons.atm_rounded),
        _RowData('Online Limit',   '\$15,000',      Icons.shopping_bag_rounded),
        _RowData('International',  'ENABLED',       Icons.flight_rounded),
      ],
    );
  }

  Widget _buildSecurityPanel(CardThemeData theme, Color accent) {
    return _PanelSheet(
      accent: accent,
      rows: [
        _RowData('3D Secure',      'ENABLED',   Icons.verified_user_rounded),
        _RowData('Contactless',    'ACTIVE',    Icons.contactless_rounded),
        _RowData('Biometric Auth', 'REQUIRED',  Icons.fingerprint_rounded),
        _RowData('Fraud Alert',    'ACTIVE',    Icons.notifications_active_rounded),
        _RowData('CVV Lock',       'ENABLED',   Icons.lock_rounded),
      ],
    );
  }
}

// ── ROW DATA MODEL ────────────────────────────────────────────

class _RowData {
  final String label;
  final String value;
  final IconData icon;
  const _RowData(this.label, this.value, this.icon);
}

// ── GLASS PANEL SHEET ─────────────────────────────────────────

class _PanelSheet extends StatelessWidget {
  final List<_RowData> rows;
  final Color accent;

  const _PanelSheet({required this.rows, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.13),
                width: 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(rows.length * 2 - 1, (i) {
                if (i.isOdd) return _divider();
                final row = rows[i ~/ 2];
                return _InfoRow(data: row, accent: accent);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
    height: 0.5,
    margin: const EdgeInsets.symmetric(horizontal: 18),
    color: Colors.white.withOpacity(0.10),
  );
}

// ── SINGLE INFO ROW ───────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final _RowData data;
  final Color accent;

  const _InfoRow({required this.data, required this.accent});

  bool get _isStatusValue =>
      data.value == 'ENABLED' ||
          data.value == 'ACTIVE' ||
          data.value == 'REQUIRED';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: accent.withOpacity(0.85), size: 18),
          ),
          const SizedBox(width: 14),

          // Label
          Expanded(
            child: Text(
              data.label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.65),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Value
          _isStatusValue
              ? _StatusBadge(label: data.value, accent: accent)
              : Text(
            data.value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── STATUS BADGE ──────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _StatusBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isGreen = label == 'ENABLED' || label == 'ACTIVE';
    final color = isGreen ? const Color(0xFF30D158) : const Color(0xFFFFD60A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── iOS SEGMENTED CONTROL ─────────────────────────────────────

class _IOSSegmentedControl extends StatelessWidget {
  final List<Map<String, dynamic>> panels;
  final int selectedIndex;
  final Color accent;
  final ValueChanged<int> onTap;

  const _IOSSegmentedControl({
    required this.panels,
    required this.selectedIndex,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 0.8,
            ),
          ),
          child: Row(
            children: List.generate(panels.length, (i) {
              final isActive = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isActive
                          ? Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 0.6,
                      )
                          : null,
                      boxShadow: isActive
                          ? [
                        BoxShadow(
                          color: accent.withOpacity(0.20),
                          blurRadius: 12,
                          spreadRadius: -2,
                        )
                      ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          panels[i]['icon'] as IconData,
                          size: 17,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.40),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          panels[i]['title'] as String,
                          style: GoogleFonts.inter(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.40),
                            fontSize: 10,
                            fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── iOS BACK BUTTON ───────────────────────────────────────────

class _IOSBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _IOSBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}