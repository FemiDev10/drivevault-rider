import 'package:flutter/foundation.dart';
import 'ride_models.dart';

/// ============================================================
/// MOCK LAYER — all fake, local, offline. Swap for real APIs later.
/// ============================================================

String naira(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '₦${buf.toString()}';
}

int _round(int v, [int step = 20]) => (v / step).round() * step;

/// Places used for recents + typeahead search.
class PlacesRepository {
  PlacesRepository._();
  static final instance = PlacesRepository._();

  static const currentLocation =
      Place(name: 'Current location', subtitle: 'Victoria Island, Lagos', distanceKm: 0);

  final List<Place> recents = const [
    Place(name: 'Eko Hotel & Suites', subtitle: 'Plot 1415 Adetokunbo Ademola, VI', distanceKm: 6.2, icon: PlaceIcon.recent),
    Place(name: 'Murtala Muhammed Airport', subtitle: 'Ikeja, Lagos', distanceKm: 18.5, icon: PlaceIcon.airport),
    Place(name: 'The Palms Shopping Mall', subtitle: 'Bisola Durosinmi, Lekki', distanceKm: 12.3, icon: PlaceIcon.mall),
    Place(name: 'Shoprite Sangotedo', subtitle: 'Monastery Rd, Lekki', distanceKm: 22.0, icon: PlaceIcon.recent),
  ];

  final List<Place> _all = const [
    Place(name: 'Eko Hotel & Suites', subtitle: 'Plot 1415 Adetokunbo Ademola, VI', distanceKm: 6.2, icon: PlaceIcon.pin),
    Place(name: 'Murtala Muhammed Airport', subtitle: 'Ikeja, Lagos', distanceKm: 18.5, icon: PlaceIcon.airport),
    Place(name: 'The Palms Shopping Mall', subtitle: 'Bisola Durosinmi, Lekki', distanceKm: 12.3, icon: PlaceIcon.mall),
    Place(name: 'Shoprite Sangotedo', subtitle: 'Monastery Rd, Lekki', distanceKm: 22.0, icon: PlaceIcon.mall),
    Place(name: 'Iwo Road Motor Park', subtitle: 'Iwo Road Motor Park, Ibadan', distanceKm: 4.1, icon: PlaceIcon.bus),
    Place(name: 'Film House Cinema', subtitle: 'Ventura Mall, Ibadan', distanceKm: 4.1, icon: PlaceIcon.pin),
    Place(name: 'University of Ibadan', subtitle: 'Ibadan', distanceKm: 4.1, icon: PlaceIcon.school),
    Place(name: 'University College Hospital', subtitle: 'Queen Elizabeth Rd, Ibadan', distanceKm: 5.2, icon: PlaceIcon.hospital),
    Place(name: 'Lekki Phase 1', subtitle: 'Lagos', distanceKm: 8.4, icon: PlaceIcon.pin),
    Place(name: 'Ikeja City Mall', subtitle: 'Alausa, Ikeja', distanceKm: 14.0, icon: PlaceIcon.mall),
    Place(name: 'Victoria Island', subtitle: 'Lagos', distanceKm: 5.5, icon: PlaceIcon.pin),
    Place(name: 'Yaba', subtitle: 'Lagos Mainland', distanceKm: 3.2, icon: PlaceIcon.pin),
    Place(name: 'Computer Village', subtitle: 'Ikeja, Lagos', distanceKm: 13.5, icon: PlaceIcon.mall),
    Place(name: 'National Theatre', subtitle: 'Iganmu, Lagos', distanceKm: 9.8, icon: PlaceIcon.pin),
    Place(name: 'Nike Art Gallery', subtitle: 'Lekki, Lagos', distanceKm: 11.2, icon: PlaceIcon.pin),
    Place(name: 'Tafawa Balewa Square', subtitle: 'Lagos Island', distanceKm: 7.6, icon: PlaceIcon.pin),
  ];

  /// Live typeahead. Empty query → recents.
  List<Place> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return recents;
    return _all
        .where((p) => p.name.toLowerCase().contains(q) || p.subtitle.toLowerCase().contains(q))
        .toList();
  }
}

/// In-memory saved shortcuts with add / edit / delete, broadcasting changes.
class ShortcutsStore extends ChangeNotifier {
  ShortcutsStore._();
  static final instance = ShortcutsStore._();

  Shortcut home = const Shortcut(kind: ShortcutKind.home, label: 'Home');
  Shortcut work = const Shortcut(kind: ShortcutKind.work, label: 'Work');
  final List<Shortcut> custom = [];

  void setHome(Place p) {
    home = home.copyWith(place: p);
    notifyListeners();
  }

  void setWork(Place p) {
    work = work.copyWith(place: p);
    notifyListeners();
  }

  void addCustom(String label, Place p) {
    custom.add(Shortcut(kind: ShortcutKind.custom, label: label, place: p));
    notifyListeners();
  }

  void clearHome() {
    home = const Shortcut(kind: ShortcutKind.home, label: 'Home');
    notifyListeners();
  }

  void clearWork() {
    work = const Shortcut(kind: ShortcutKind.work, label: 'Work');
    notifyListeners();
  }

  void removeCustom(Shortcut s) {
    custom.remove(s);
    notifyListeners();
  }
}

/// Dynamic fare engine. Farther → pricier. Rivals are always more expensive.
class PricingService {
  PricingService._();
  static final instance = PricingService._();

  static const tiers = <RideTier>[
    RideTier(id: 'dvgo', name: 'DvGo', seats: 4, blurb: 'Faster Pickup', asset: 'assets/images/car_dvgo.png', etaMin: 3, baseFare: 2600, perKm: 560),
    RideTier(id: 'comfort', name: 'Comfort', seats: 4, blurb: 'Comfortable cars', asset: 'assets/images/car_comfort.png', etaMin: 5, baseFare: 3800, perKm: 770),
    RideTier(id: 'executive', name: 'Executive', seats: 4, blurb: 'Premium cars', asset: 'assets/images/car_executive.png', etaMin: 6, baseFare: 5200, perKm: 1040),
    RideTier(id: 'xl', name: 'XL', seats: 6, blurb: 'Extra space', asset: 'assets/images/car_xl.png', etaMin: 6, baseFare: 4200, perKm: 700, isMore: true),
  ];

  RideQuote quote(RideTier t, double km) {
    final instant = _round((t.baseFare + t.perKm * km).round());
    final negLow = _round((instant * 0.85).round());
    final negHigh = _round((instant * 1.15).round());
    // Rivals always higher than our top-of-range.
    final rivalLow = _round((instant * 1.22).round());
    final rivalHigh = _round((instant * 1.45).round());
    final savings = _round(rivalLow - negLow);
    return RideQuote(
      tier: t,
      instant: instant,
      negLow: negLow,
      negHigh: negHigh,
      rivalLow: rivalLow,
      rivalHigh: rivalHigh,
      savings: savings,
    );
  }

  List<RideQuote> quotes(double km) => tiers.map((t) => quote(t, km)).toList();

  /// Rough trip duration in minutes from distance.
  int tripMinutes(double km) => (km * 2.4 + 4).round();

  /// Arrival clock like "6:15 AM", computed from now + trip time.
  String arrivalTime(double km) {
    final t = DateTime.now().add(Duration(minutes: tripMinutes(km)));
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    final mm = t.minute.toString().padLeft(2, '0');
    return '$h12:$mm $ampm';
  }
}
