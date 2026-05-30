import 'package:flutter/material.dart';

enum CardType { gold, platinum, black, student, titanium }

class CardModel {
  final String id;
  String cardNumber;
  String cardHolder;
  String expiryDate;
  String cvv;
  String bankName;
  CardType cardType;

  CardModel({
    required this.id,
    this.cardNumber = '',
    this.cardHolder = '',
    this.expiryDate = '',
    this.cvv = '',
    this.bankName = '',
    this.cardType = CardType.black,
  });

  CardModel copyWith({
    String? id,
    String? cardNumber,
    String? cardHolder,
    String? expiryDate,
    String? cvv,
    String? bankName,
    CardType? cardType,
  }) {
    return CardModel(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      bankName: bankName ?? this.bankName,
      cardType: cardType ?? this.cardType,
    );
  }

  String get formattedNumber {
    final raw = cardNumber.replaceAll(' ', '');
    if (raw.isEmpty) return '**** **** **** ****';
    final padded = raw.padRight(16, '*');
    final groups = <String>[];
    for (int i = 0; i < 16; i += 4) {
      groups.add(padded.substring(i, i + 4 > padded.length ? padded.length : i + 4));
    }
    return groups.join('  ');
  }

  String get displayHolder => cardHolder.isEmpty ? 'CARD HOLDER' : cardHolder.toUpperCase();
  String get displayExpiry => expiryDate.isEmpty ? 'MM/YY' : expiryDate;
  String get displayBank => bankName.isEmpty ? 'NEXUS BANK' : bankName.toUpperCase();
}

class CardThemeData {
  final List<Color> primaryColors;
  final List<Color> shineColors;
  final Color textColor;
  final Color subtleColor;
  final String label;
  final double metalness;

  const CardThemeData({
    required this.primaryColors,
    required this.shineColors,
    required this.textColor,
    required this.subtleColor,
    required this.label,
    required this.metalness,
  });
}

final Map<CardType, CardThemeData> cardThemes = {
  CardType.black: CardThemeData(
    primaryColors: [
      const Color(0xFF0A0A0A),
      const Color(0xFF1A1A1A),
      const Color(0xFF111111),
      const Color(0xFF0D0D0D),
    ],
    shineColors: [
      Colors.white.withOpacity(0.08),
      Colors.white.withOpacity(0.02),
    ],
    textColor: const Color(0xFFE8E8E8),
    subtleColor: const Color(0xFF555555),
    label: 'BLACK',
    metalness: 0.9,
  ),
  CardType.platinum: CardThemeData(
    primaryColors: [
      const Color(0xFF8E9BAE),
      const Color(0xFFB8C4D0),
      const Color(0xFF9BA8B8),
      const Color(0xFF7A8898),
    ],
    shineColors: [
      Colors.white.withOpacity(0.35),
      Colors.white.withOpacity(0.05),
    ],
    textColor: const Color(0xFF1A1A2E),
    subtleColor: const Color(0xFF4A5568),
    label: 'PLATINUM',
    metalness: 1.0,
  ),
  CardType.gold: CardThemeData(
    primaryColors: [
      const Color(0xFF8B6914),
      const Color(0xFFD4A843),
      const Color(0xFFC49A2E),
      const Color(0xFF9A7520),
    ],
    shineColors: [
      Colors.white.withOpacity(0.4),
      const Color(0xFFFFD700).withOpacity(0.2),
    ],
    textColor: const Color(0xFF1A0F00),
    subtleColor: const Color(0xFF6B4F00),
    label: 'GOLD',
    metalness: 0.95,
  ),
  CardType.titanium: CardThemeData(
    primaryColors: [
      const Color(0xFF2D3436),
      const Color(0xFF3D4448),
      const Color(0xFF4A5259),
      const Color(0xFF232729),
    ],
    shineColors: [
      Colors.white.withOpacity(0.15),
      Colors.white.withOpacity(0.03),
    ],
    textColor: const Color(0xFFDFE6E9),
    subtleColor: const Color(0xFF636E72),
    label: 'TITANIUM',
    metalness: 0.85,
  ),
  CardType.student: CardThemeData(
    primaryColors: [
      const Color(0xFF1A1A2E),
      const Color(0xFF16213E),
      const Color(0xFF0F3460),
      const Color(0xFF1A1A2E),
    ],
    shineColors: [
      const Color(0xFF00D2FF).withOpacity(0.2),
      Colors.white.withOpacity(0.05),
    ],
    textColor: const Color(0xFFE0F7FA),
    subtleColor: const Color(0xFF4FC3F7),
    label: 'STUDENT',
    metalness: 0.5,
  ),
};
