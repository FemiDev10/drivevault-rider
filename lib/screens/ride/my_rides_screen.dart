import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';
import 'trip_end_screens.dart';
import '../account/account_screen.dart';
import '../../services/mock/schedule_repository.dart';
import 'schedule_ride_screen.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);
const _green = Color(0xFF00853F);

class _Ride {
  final String date, time, addr;
  final int fare;
  final bool cancelled;
  const _Ride(this.date, this.time, this.addr, this.fare, {this.cancelled = false});
}

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});
  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  int _tab = 0; // 0 past, 1 scheduled

  static const _addr = 'Truck Central, Tiamiyu Savage Street, Lagos, Nigeria';
  static const _past = {
    'December 2026': [
      _Ride('22 Dec', '7:25 am', _addr, 9280),
      _Ride('22 Dec', '', _addr, 0, cancelled: true),
      _Ride('22 Dec', '7:25 am', _addr, 9280),
      _Ride('22 Dec', '7:25 am', _addr, 9280),
    ],
    'May 2026': [
      _Ride('22 May', '7:25 am', _addr, 9280),
      _Ride('22 May', '7:25 am', _addr, 9280),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const StatusBar(),
            // header (ICON LEFT): X close · My rides · spacer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: SizedBox(
                height: 42,
                child: Row(children: [
                  InkWell(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.close, size: 24, color: AppColors.black)),
                  const Expanded(child: Center(child: Text('My rides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black)))),
                  const SizedBox(width: 24),
                ]),
              ),
            ),
            const SizedBox(height: 23),
            // tabs with shared bottom border
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.stroke))),
                child: Row(children: [
                  _tabBtn('Past', 0),
                  const SizedBox(width: 16),
                  _tabBtn('Scheduled', 1),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _tab == 0 ? _pastList() : _scheduledList()),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int i) {
    final on = _tab == i;
    return GestureDetector(
      onTap: () => setState(() => _tab = i),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: on ? AppColors.primary : Colors.transparent, width: 1.5))),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: on ? FontWeight.w500 : FontWeight.w400, color: on ? AppColors.primary : _sub)),
      ),
    );
  }

  Widget _pastList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        for (final entry in _past.entries) ...[
          Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black)),
          const SizedBox(height: 16),
          for (int i = 0; i < entry.value.length; i++) ...[
            _rideRow(entry.value[i]),
            if (i < entry.value.length - 1) const Divider(height: 32, color: Color(0xFFEDEDED)),
          ],
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _rideRow(_Ride r) {
    return InkWell(
      onTap: r.cancelled ? null : () {
        final dest = Place(name: r.addr.split(',').first, subtitle: r.addr, distanceKm: 8.9);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripSummaryScreen(
            total: r.fare, pickup: PlacesRepository.currentLocation, destination: dest, tier: 'DriveVault Go')));
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(r.cancelled ? Icons.car_crash_outlined : Icons.directions_car_outlined, size: 20, color: AppColors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.cancelled ? '${r.date}  • Cancelled' : '${r.date}  • ${r.time}',
                    style: TextStyle(fontSize: 12, color: r.cancelled ? AppColors.red : _green)),
                const SizedBox(height: 8),
                Text(r.addr, style: const TextStyle(fontSize: 14, color: AppColors.black)),
                const SizedBox(height: 8),
                Text(naira(r.fare), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
              ],
            ),
          ),
          const SizedBox(width: 35),
          const Icon(Icons.repeat, size: 24, color: AppColors.black),
        ],
      ),
    );
  }

  /// Scheduled tab — real bookings, with the empty state as a fallback.
  Widget _scheduledList() {
    final rides = ScheduleStore.instance.rides;
    if (rides.isEmpty) return _scheduledEmpty();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        for (final r in rides)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ScheduleConfirmedScreen(ride: r))),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.stroke)),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF0F2FA), shape: BoxShape.circle),
                    child: const Icon(Icons.event, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.whenLabel,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: _green)),
                      const SizedBox(height: 4),
                      Text(r.destination.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: AppColors.black)),
                      if (r.forSomeoneElse) ...[
                        const SizedBox(height: 3),
                        Text('For ${r.rider!.name}',
                            style: const TextStyle(fontSize: 12, color: _sub)),
                      ],
                    ]),
                  ),
                  const Icon(Icons.chevron_right, size: 22, color: _sub),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _scheduledEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64,
              decoration: const BoxDecoration(color: Color(0xFFF0F2FA), shape: BoxShape.circle),
              child: const Icon(Icons.event_outlined, size: 30, color: _sub)),
          const SizedBox(height: 16),
          const Text('No upcoming rides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
          const SizedBox(height: 4),
          const Text('Schedule a ride from the home screen', style: TextStyle(fontSize: 13, color: _sub)),
        ]),
      );

  Widget _bottomNav() => Container(
        height: 86,
        decoration: const BoxDecoration(color: AppColors.white, boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(4, 0))]),
        padding: const EdgeInsets.only(top: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _nav(Icons.home_outlined, 'Home', false, () => Navigator.of(context).popUntil((r) => r.isFirst)),
          const SizedBox(width: 80),
          _nav(Icons.event_note, 'Trips', true, () {}),
          const SizedBox(width: 80),
          _nav(Icons.person_outline, 'Account', false,
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen()))),
        ]),
      );

  Widget _nav(IconData icon, String label, bool active, VoidCallback onTap) {
    final c = active ? AppColors.primary : _sub;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(height: 7),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: c)),
        ]));
  }
}
