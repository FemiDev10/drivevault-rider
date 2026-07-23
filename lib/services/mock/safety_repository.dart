import 'package:flutter/foundation.dart';

/// A person we notify if the rider triggers SOS.
class EmergencyContact {
  EmergencyContact({required this.firstName, required this.lastName, required this.phone});
  String firstName;
  String lastName;
  String phone;

  String get name => '$firstName $lastName'.trim();
}

/// Saved place shortcut (Home / Work / custom).
class SavedPlace {
  SavedPlace({required this.label, required this.address, this.icon = 'place'});
  String label;
  String address;
  String icon; // 'home' | 'work' | 'place'
}

class SafetyStore extends ChangeNotifier {
  SafetyStore._();
  static final SafetyStore instance = SafetyStore._();

  final List<EmergencyContact> contacts = [];

  final List<SavedPlace> places = [
    SavedPlace(label: 'Home', address: 'Ringroad 12 avenue, Yaba', icon: 'home'),
    SavedPlace(label: 'Work', address: 'Sabo, Yaba', icon: 'work'),
  ];

  void addContact(EmergencyContact c) {
    contacts.add(c);
    notifyListeners();
  }

  void updateContact(EmergencyContact c, String first, String last, String phone) {
    c.firstName = first.trim();
    c.lastName = last.trim();
    c.phone = phone.trim();
    notifyListeners();
  }

  void removeContact(EmergencyContact c) {
    contacts.remove(c);
    notifyListeners();
  }

  void addPlace(SavedPlace p) {
    places.add(p);
    notifyListeners();
  }

  void removePlace(SavedPlace p) {
    places.remove(p);
    notifyListeners();
  }
}
