import 'package:flutter/material.dart';

/// ===== Places =====

enum PlaceIcon { recent, bus, pin, school, hospital, mall, airport, generic }

class Place {
  final String name;
  final String subtitle;
  final double distanceKm;
  final PlaceIcon icon;

  const Place({
    required this.name,
    required this.subtitle,
    required this.distanceKm,
    this.icon = PlaceIcon.generic,
  });
}

IconData iconFor(PlaceIcon i) {
  switch (i) {
    case PlaceIcon.recent:
      return Icons.access_time;
    case PlaceIcon.bus:
      return Icons.directions_bus_outlined;
    case PlaceIcon.pin:
      return Icons.location_on_outlined;
    case PlaceIcon.school:
      return Icons.school_outlined;
    case PlaceIcon.hospital:
      return Icons.local_hospital_outlined;
    case PlaceIcon.mall:
      return Icons.storefront_outlined;
    case PlaceIcon.airport:
      return Icons.flight_outlined;
    case PlaceIcon.generic:
      return Icons.location_on_outlined;
  }
}

/// ===== Saved shortcuts =====

enum ShortcutKind { home, work, custom }

class Shortcut {
  final ShortcutKind kind;
  final String label; // "Home", "Work", or a custom name
  final Place? place; // null = not yet set

  const Shortcut({required this.kind, required this.label, this.place});

  bool get isSet => place != null;

  Shortcut copyWith({String? label, Place? place}) =>
      Shortcut(kind: kind, label: label ?? this.label, place: place ?? this.place);
}

/// ===== Ride tiers & pricing =====

enum PriceMode { negotiate, instant }

class RideTier {
  final String id;
  final String name;
  final int seats;
  final String blurb;
  final String asset;
  final int etaMin;
  final int baseFare;
  final int perKm;
  final bool isMore; // shown under the "More" section

  const RideTier({
    required this.id,
    required this.name,
    required this.seats,
    required this.blurb,
    required this.asset,
    required this.etaMin,
    required this.baseFare,
    required this.perKm,
    this.isMore = false,
  });
}

/// A fully-computed price quote for one tier on one trip.
class RideQuote {
  final RideTier tier;
  final int instant; // fixed price (Instant Booking)
  final int negLow; // negotiate range low
  final int negHigh; // negotiate range high
  final int rivalLow; // "other apps" low — always above ours
  final int rivalHigh; // "other apps" high
  final int savings; // vs the cheapest rival price

  const RideQuote({
    required this.tier,
    required this.instant,
    required this.negLow,
    required this.negHigh,
    required this.rivalLow,
    required this.rivalHigh,
    required this.savings,
  });
}
