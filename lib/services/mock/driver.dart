/// Mock driver + trip data for the ride lifecycle.
class Driver {
  final String name;
  final String plate;
  final String car;
  final double rating;
  final int trips;
  final String avatar;
  final String initials;
  const Driver({
    required this.name,
    required this.plate,
    required this.car,
    required this.rating,
    required this.trips,
    required this.avatar,
    required this.initials,
  });
}

const kDriver = Driver(
  name: 'Olu Adeyemi',
  plate: 'LAG 234 XY',
  car: 'Toyota Camry',
  rating: 4.78,
  trips: 342,
  avatar: 'assets/images/driver_avatar.png',
  initials: 'OA',
);

const kPickupStreet = 'Shehu Biliaminu Ola Adua Street';
const kTierLabel = 'DriveVault Go';
