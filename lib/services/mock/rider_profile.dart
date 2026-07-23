import 'package:flutter/foundation.dart';

/// Identity state for the signed-in rider.
///
/// Ride-hailing rules this models (and the original UI missed):
/// * Phone is the login credential — it can only change through a re-OTP flow.
/// * Legal name is locked once identity is verified, because it must match the
///   ID on file for disputes, insurance and safety escalations.
/// * Email is optional (many riders sign up with phone only) but must be
///   verified before it can receive receipts.
enum IdStatus { unverified, inReview, verified }

class RiderProfile extends ChangeNotifier {
  RiderProfile._();
  static final RiderProfile instance = RiderProfile._();

  String firstName = 'Femi';
  String lastName = 'Jimoh';
  String phone = '+234 803 000 0000';
  bool phoneVerified = true; // signup was phone + OTP

  String? email; // many riders never provide one
  bool emailVerified = false;

  IdStatus idStatus = IdStatus.unverified;
  String? ninLast4;

  double rating = 5.00;
  int trips = 47;

  bool emailReceipts = true;
  bool promos = false;

  String? emergencyName;
  String? emergencyPhone;

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  /// The name is only editable until the identity is verified.
  bool get nameLocked => idStatus == IdStatus.verified;

  void setName(String first, String last) {
    firstName = first.trim();
    lastName = last.trim();
    notifyListeners();
  }

  void setPhone(String value) {
    phone = value;
    phoneVerified = true; // only ever set after an OTP round-trip
    notifyListeners();
  }

  void setEmail(String value) {
    email = value.trim();
    emailVerified = false; // a new address always starts unverified
    notifyListeners();
  }

  void confirmEmail() {
    emailVerified = true;
    notifyListeners();
  }

  void submitNin(String nin) {
    ninLast4 = nin.substring(nin.length - 4);
    idStatus = IdStatus.inReview;
    notifyListeners();
  }

  /// Prototype shortcut so reviewers can see the verified state.
  void approveId() {
    idStatus = IdStatus.verified;
    notifyListeners();
  }

  void setEmergency(String name, String phone) {
    emergencyName = name;
    emergencyPhone = phone;
    notifyListeners();
  }

  void toggleEmailReceipts(bool v) {
    emailReceipts = v;
    notifyListeners();
  }

  void togglePromos(bool v) {
    promos = v;
    notifyListeners();
  }
}
