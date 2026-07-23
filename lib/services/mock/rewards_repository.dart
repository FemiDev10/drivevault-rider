import 'package:flutter/material.dart';

/// ============================================================
/// MOCK LAYER — payment methods + offers/promos. All local.
/// ============================================================

// ---------- Payment ----------

enum PayKind { applePay, addCard, bankTransfer, card }

class SavedCard {
  final String last4;
  final String brand; // 'visa' | 'mastercard'
  const SavedCard({required this.last4, required this.brand});
}

class PaymentMethod {
  final String id;
  final PayKind kind;
  final String label;
  final IconData icon;
  const PaymentMethod({required this.id, required this.kind, required this.label, required this.icon});
}

class PaymentStore extends ChangeNotifier {
  PaymentStore._();
  static final instance = PaymentStore._();

  final List<SavedCard> cards = [];
  String selectedId = 'bank'; // default Bank Transfer

  static const applePay = PaymentMethod(id: 'apple', kind: PayKind.applePay, label: 'Apple Pay', icon: Icons.apple);
  static const bank = PaymentMethod(id: 'bank', kind: PayKind.bankTransfer, label: 'Bank Transfer', icon: Icons.account_balance_wallet_outlined);

  String get selectedLabel {
    if (selectedId.startsWith('card:')) {
      final last4 = selectedId.substring(5);
      return '•••• $last4';
    }
    if (selectedId == 'apple') return 'Apple Pay';
    return 'Bank Transfer';
  }

  void select(String id) {
    selectedId = id;
    notifyListeners();
  }

  SavedCard addCard(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits.padLeft(4, '0');
    final brand = digits.startsWith('4') ? 'visa' : 'mastercard';
    final card = SavedCard(last4: last4, brand: brand);
    cards.add(card);
    selectedId = 'card:$last4';
    notifyListeners();
    return card;
  }

  void removeCard(SavedCard c) {
    cards.remove(c);
    if (selectedId == 'card:${c.last4}') selectedId = 'bank';
    notifyListeners();
  }
}

// ---------- Offers / promos ----------

class Offer {
  final String code;
  final String title; // e.g. "₦500 off your first ride"
  final String detail; // e.g. "Expires in 7 days"
  final Color badgeBg;
  final Color badgeFg;
  final IconData icon;
  final int savings; // naira saved when applied

  const Offer({
    required this.code,
    required this.title,
    required this.detail,
    required this.badgeBg,
    required this.badgeFg,
    required this.icon,
    required this.savings,
  });
}

class OffersStore extends ChangeNotifier {
  OffersStore._();
  static final instance = OffersStore._();

  final List<Offer> applied = [
    const Offer(
      code: 'SAVE20',
      title: '20% off your next 3 rides',
      detail: '',
      badgeBg: Color(0xFFE5F3EC),
      badgeFg: Color(0xFF00853F),
      icon: Icons.percent,
      savings: 500,
    ),
  ];

  final List<Offer> available = [
    const Offer(
      code: 'FIRSTRIDE500',
      title: '₦500 off your first ride',
      detail: 'Expires in 7 days',
      badgeBg: Color(0x1A4A1CBF),
      badgeFg: Color(0xFF4A1CBF),
      icon: Icons.local_taxi_outlined,
      savings: 500,
    ),
    const Offer(
      code: 'WEEKEND50',
      title: '50% off on weekend rides',
      detail: 'Valid Sat-Sun • Max ₦1,000 discount',
      badgeBg: Color(0xFFDBEAFE),
      badgeFg: Color(0xFF2563EB),
      icon: Icons.weekend_outlined,
      savings: 1000,
    ),
    const Offer(
      code: 'LAGOS100',
      title: '₦500 off your first ride',
      detail: 'Min spend ₦500 • 4 uses left',
      badgeBg: Color(0x1AF79D20),
      badgeFg: Color(0xFFF79D20),
      icon: Icons.location_city,
      savings: 500,
    ),
  ];

  bool get hasApplied => applied.isNotEmpty;

  Offer? get primary => applied.isEmpty ? null : applied.first;

  int get totalSavings => applied.fold(0, (s, o) => s + o.savings);

  void apply(Offer o) {
    available.remove(o);
    applied.add(o);
    notifyListeners();
  }

  void remove(Offer o) {
    applied.remove(o);
    // Well-known catalogue offers return to the available list; ad-hoc promo codes just drop.
    if (!o.code.startsWith('PROMO')) available.insert(0, o);
    notifyListeners();
  }

  /// Returns null on success, or an error message on failure.
  /// Any code that isn't a known promo is treated as invalid.
  String? redeem(String code) {
    final c = code.trim().toUpperCase();
    const valid = {'SAVE20', 'XXXX032942', 'FIRSTRIDE500', 'WEEKEND50', 'LAGOS100', 'DRIVE20'};
    if (c.isEmpty) return 'Enter a promo code';
    if (!valid.contains(c)) return 'Hmmm, that isn’t a valid code';
    if (applied.any((o) => o.code == c)) return 'That code is already applied';
    applied.add(Offer(
      code: c,
      title: '20% off applied',
      detail: '',
      badgeBg: const Color(0xFFE5F3EC),
      badgeFg: const Color(0xFF00853F),
      icon: Icons.percent,
      savings: 500,
    ));
    available.removeWhere((o) => o.code == c);
    notifyListeners();
    return null;
  }
}
