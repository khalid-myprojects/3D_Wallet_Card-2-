import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardProvider extends ChangeNotifier {
  final List<CardModel> _cards = [];
  int _selectedIndex = 0;

  // Live form state for card being created
  CardModel _draftCard = CardModel(
    id: 'draft',
    cardType: CardType.black,
  );

  List<CardModel> get cards => _cards;
  int get selectedIndex => _selectedIndex;
  CardModel get draftCard => _draftCard;
  CardModel? get selectedCard =>
      _cards.isNotEmpty ? _cards[_selectedIndex] : null;

  void updateDraftNumber(String value) {
    _draftCard = _draftCard.copyWith(cardNumber: value);
    notifyListeners();
  }

  void updateDraftHolder(String value) {
    _draftCard = _draftCard.copyWith(cardHolder: value);
    notifyListeners();
  }

  void updateDraftExpiry(String value) {
    _draftCard = _draftCard.copyWith(expiryDate: value);
    notifyListeners();
  }

  void updateDraftCvv(String value) {
    _draftCard = _draftCard.copyWith(cvv: value);
    notifyListeners();
  }

  void updateDraftBank(String value) {
    _draftCard = _draftCard.copyWith(bankName: value);
    notifyListeners();
  }

  void updateDraftType(CardType type) {
    _draftCard = _draftCard.copyWith(cardType: type);
    notifyListeners();
  }

  void addCard() {
    final newCard = CardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardNumber: _draftCard.cardNumber,
      cardHolder: _draftCard.cardHolder,
      expiryDate: _draftCard.expiryDate,
      cvv: _draftCard.cvv,
      bankName: _draftCard.bankName,
      cardType: _draftCard.cardType,
    );
    _cards.add(newCard);
    _selectedIndex = _cards.length - 1;

    // Reset draft
    _draftCard = CardModel(id: 'draft', cardType: CardType.black);
    notifyListeners();
  }

  void selectCard(int index) {
    if (index >= 0 && index < _cards.length) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void removeCard(String id) {
    _cards.removeWhere((c) => c.id == id);
    if (_selectedIndex >= _cards.length && _selectedIndex > 0) {
      _selectedIndex = _cards.length - 1;
    }
    notifyListeners();
  }
}
