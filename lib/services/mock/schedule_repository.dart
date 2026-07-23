import 'package:flutter/foundation.dart';
import 'ride_models.dart';

/// Someone other than the account holder taking the ride.
class RiderContact {
  RiderContact({required this.name, required this.phone});
  String name;
  String phone;
}

/// A booked-ahead ride.
class ScheduledRide {
  ScheduledRide({
    required this.pickup,
    required this.destination,
    required this.when,
    required this.tier,
    required this.fare,
    required this.paymentLabel,
    this.rider,
    this.shareDetailsWithRider = true,
  });

  final Place pickup;
  final Place destination;
  DateTime when;
  String tier;
  int fare;
  String paymentLabel;

  /// null = the account holder is riding.
  RiderContact? rider;
  bool shareDetailsWithRider;

  bool get forSomeoneElse => rider != null;

  /// "Tomorrow • 6:30 AM" style label.
  String get whenLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = day.difference(today).inDays;
    final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
    final time = '$h:${when.minute.toString().padLeft(2, '0')} ${when.hour < 12 ? 'AM' : 'PM'}';
    if (diff == 0) return 'Today • $time';
    if (diff == 1) return 'Tomorrow • $time';
    return '${when.day}/${when.month}/${when.year} • $time';
  }

  String get dateLabel =>
      '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}/${when.year}';

  String get timeLabel {
    final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
    return '$h:${when.minute.toString().padLeft(2, '0')} ${when.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Drivers are dispatched to arrive inside a 10-minute window.
  String get pickupWindow {
    String f(DateTime t) {
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
    }
    return '${f(when)} - ${f(when.add(const Duration(minutes: 10)))}';
  }

  String estimatedDropoff(int minutes) {
    final t = when.add(Duration(minutes: minutes + 5));
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  }
}

class ScheduleStore extends ChangeNotifier {
  ScheduleStore._();
  static final ScheduleStore instance = ScheduleStore._();

  final List<ScheduledRide> rides = [];

  /// Saved people you book for, so you don't retype a number every time.
  final List<RiderContact> savedRiders = [
    RiderContact(name: 'Anita', phone: '+234 248 240 8455'),
  ];

  void add(ScheduledRide r) {
    rides.add(r);
    rides.sort((a, b) => a.when.compareTo(b.when));
    notifyListeners();
  }

  void cancel(ScheduledRide r) {
    rides.remove(r);
    notifyListeners();
  }

  void addRider(RiderContact c) {
    savedRiders.add(c);
    notifyListeners();
  }

  void removeRider(RiderContact c) {
    savedRiders.remove(c);
    notifyListeners();
  }

  void touch() => notifyListeners();
}
