import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumInputField extends StatefulWidget {
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final int maxLength;
  final String? prefixText;
  final bool obscureText;

  const PremiumInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLength = 100,
    this.prefixText,
    this.obscureText = false,
  });

  @override
  State<PremiumInputField> createState() => _PremiumInputFieldState();
}

class _PremiumInputFieldState extends State<PremiumInputField>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  late AnimationController _focusController;
  late Animation<double> _lineAnim;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _lineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.rajdhani(
            color: _isFocused
                ? Colors.white.withOpacity(0.7)
                : Colors.white.withOpacity(0.35),
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) {
            setState(() => _isFocused = focused);
            if (focused) {
              _focusController.forward();
            } else {
              _focusController.reverse();
            }
          },
          child: TextField(
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            obscureText: widget.obscureText,
            style: GoogleFonts.shareTech(
              color: Colors.white,
              fontSize: 15,
              letterSpacing: 1.5,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.shareTech(
                color: Colors.white.withOpacity(0.2),
                fontSize: 15,
                letterSpacing: 1.5,
              ),
              counterText: '',
              prefixText: widget.prefixText,
              prefixStyle: GoogleFonts.shareTech(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.35),
                  width: 1,
                ),
              ),
            ),
            cursorColor: Colors.white.withOpacity(0.8),
            cursorWidth: 1.5,
          ),
        ),
      ],
    );
  }
}

class CardTypeSelector extends StatelessWidget {
  final dynamic selectedType;
  final ValueChanged<dynamic> onChanged;

  const CardTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      {'type': 'CardType.black', 'label': 'BLACK', 'color': const Color(0xFF1A1A1A)},
      {'type': 'CardType.platinum', 'label': 'PLAT', 'color': const Color(0xFFB8C4D0)},
      {'type': 'CardType.gold', 'label': 'GOLD', 'color': const Color(0xFFD4A843)},
      {'type': 'CardType.titanium', 'label': 'TITAN', 'color': const Color(0xFF3D4448)},
      {'type': 'CardType.student', 'label': 'STUD', 'color': const Color(0xFF0F3460)},
    ];

    return Row(
      children: types.map((t) {
        final isSelected = selectedType.toString() == t['type'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t['type']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (t['color'] as Color).withOpacity(0.3)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? (t['color'] as Color).withOpacity(0.8)
                      : Colors.white.withOpacity(0.08),
                  width: isSelected ? 1 : 0.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 18,
                    height: 12,
                    decoration: BoxDecoration(
                      color: t['color'] as Color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    t['label'] as String,
                    style: GoogleFonts.rajdhani(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
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
