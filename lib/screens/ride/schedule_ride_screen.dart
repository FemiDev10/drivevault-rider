import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';
import '../../services/mock/rewards_repository.dart';
import '../../services/mock/schedule_repository.dart';
import '../account/account_widgets.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);
const _line = Color(0xFFEDEDED);
const _fieldBg = Color(0xFFF7F8FC);

/// Book-ahead flow (4132:22156).
///
/// Step 1 date & time → step 2 who's riding → step 3 tier (price *ranges*,
/// because a scheduled fare can't be fixed days out) → review → confirmed.
class ScheduleRideScreen extends StatefulWidget {
  const ScheduleRideScreen({super.key, this.forSomeoneElse = false});

  /// Entered via "Ride for someone" rather than "Schedule ahead".
  final bool forSomeoneElse;

  @override
  State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends State<ScheduleRideScreen> {
  DateTime? _date;
  TimeOfDay? _time;
  Place _pickup = PlacesRepository.currentLocation;
  Place? _dest;

  bool get _valid => _date != null && _time != null && _dest != null;

  DateTime get _when => DateTime(
      _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

  String get _dateText => _date == null
      ? 'DD/MM/YYYY'
      : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}';

  String get _timeText {
    if (_time == null) return '-:-';
    final h = _time!.hour % 12 == 0 ? 12 : _time!.hour % 12;
    return '$h:${_time!.minute.toString().padLeft(2, '0')} ${_time!.hour < 12 ? 'AM' : 'PM'}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: _themed,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 6, minute: 30),
      builder: _themed,
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _pickLocation({required bool isPickup}) async {
    final p = await Navigator.of(context).push<Place>(MaterialPageRoute(
        builder: (_) => _LocationPickerScreen(
            title: isPickup ? 'Set pickup' : 'Where to?', allowCurrent: isPickup)));
    if (p != null) {
      setState(() {
        if (isPickup) {
          _pickup = p;
        } else {
          _dest = p;
        }
      });
    }
  }

  Widget _themed(BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            onSurface: _ink,
          ),
        ),
        child: child!,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          AccountHeader(
              title: widget.forSomeoneElse ? 'Ride for someone' : 'Schedule ahead'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                const Text('Plan your ride',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 6),
                const Text(
                    'Book from 30 minutes up to 90 days ahead. We’ll assign a driver shortly before pickup.',
                    style: TextStyle(fontSize: 13, color: _sub, height: 1.45)),
                const SizedBox(height: 24),
                _field('Pickup',
                    _pickup.subtitle.isEmpty ? _pickup.name : _pickup.subtitle,
                    Icons.my_location, true, () => _pickLocation(isPickup: true)),
                const SizedBox(height: 16),
                _field('Destination', _dest?.name ?? 'Where to?', Icons.place_outlined,
                    _dest != null, () => _pickLocation(isPickup: false)),
                const SizedBox(height: 16),
                _field('Date', _dateText, Icons.calendar_today_outlined, _date != null, _pickDate),
                const SizedBox(height: 16),
                _field('Pickup time', _timeText, Icons.schedule, _time != null, _pickTime),
                const SizedBox(height: 20),
                if (_date != null && _time != null) _windowNote(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: PrimaryButton(
              label: 'Choose a ride',
              enabled: _valid,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ScheduleTierScreen(
                    pickup: _pickup,
                    destination: _dest!,
                    when: _when,
                    forSomeoneElse: widget.forSomeoneElse),
              )),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _windowNote() => Container(
        decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                'Your driver will arrive between $_timeText and ${_plus10()}. You can cancel free up to 1 hour before.',
                style: const TextStyle(fontSize: 12, color: _sub, height: 1.4)),
          ),
        ]),
      );

  String _plus10() {
    final t = _when.add(const Duration(minutes: 10));
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  Widget _field(String label, String value, IconData icon, bool filled, VoidCallback onTap) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        color: filled ? _ink : const Color(0xFFB0B4C4))),
              ),
              Icon(icon, size: 20, color: _sub),
            ]),
          ),
        ),
      ]);
}

/// Tier selection for a scheduled ride (966:18549 with the "Schedule ahead"
/// toggle). Fares are shown as **ranges** — a scheduled price can't be fixed.
class ScheduleTierScreen extends StatefulWidget {
  const ScheduleTierScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.when,
    this.forSomeoneElse = false,
  });
  final Place pickup;
  final Place destination;
  final DateTime when;
  final bool forSomeoneElse;

  @override
  State<ScheduleTierScreen> createState() => _ScheduleTierScreenState();
}

class _ScheduleTierScreenState extends State<ScheduleTierScreen> {
  late final List<RideQuote> _quotes =
      PricingService.instance.quotes(widget.destination.distanceKm);
  late String _selected = _quotes.first.tier.id;

  RideQuote get _picked => _quotes.firstWhere((q) => q.tier.id == _selected);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Choose a ride'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Text('Arriving by ${widget.destination.name}',
                    style: const TextStyle(fontSize: 13, color: _sub)),
                const SizedBox(height: 12),
                for (final q in _quotes) _tierRow(q),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: PrimaryButton(
              label: 'Next',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => WhoIsRidingScreen(
                  pickup: widget.pickup,
                  destination: widget.destination,
                  when: widget.when,
                  quote: _picked,
                  forSomeoneElse: widget.forSomeoneElse,
                ),
              )),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tierRow(RideQuote q) {
    final on = q.tier.id == _selected;
    // scheduled = price range, not a fixed fare
    final low = (q.instant * 0.9).round();
    final high = (q.instant * 1.2).round();
    return InkWell(
      onTap: () => setState(() => _selected = q.tier.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: on ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: on ? AppColors.primary : AppColors.stroke,
              width: on ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: const Color(0xFFF0F2FA), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.directions_car, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(q.tier.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(width: 6),
                Icon(Icons.person, size: 13, color: _sub),
                Text('${q.tier.seats}', style: const TextStyle(fontSize: 12, color: _sub)),
              ]),
              const SizedBox(height: 2),
              Text(q.tier.blurb, style: const TextStyle(fontSize: 12, color: _sub)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${naira(low)} – ${naira(high)}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 2),
            const Text('Price range', style: TextStyle(fontSize: 11, color: _sub)),
          ]),
        ]),
      ),
    );
  }
}

/// 968:19283 — "Who is riding?" Me / saved riders / add someone else.
class WhoIsRidingScreen extends StatefulWidget {
  const WhoIsRidingScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.when,
    required this.quote,
    this.forSomeoneElse = false,
  });
  final Place pickup;
  final Place destination;
  final DateTime when;
  final RideQuote quote;
  final bool forSomeoneElse;

  @override
  State<WhoIsRidingScreen> createState() => _WhoIsRidingScreenState();
}

class _WhoIsRidingScreenState extends State<WhoIsRidingScreen> {
  final _s = ScheduleStore.instance;
  late RiderContact? _picked =
      widget.forSomeoneElse && _s.savedRiders.isNotEmpty ? _s.savedRiders.first : null;
  bool _share = true;

  @override
  void initState() {
    super.initState();
    _s.addListener(_r);
  }

  void _r() => setState(() {});

  @override
  void dispose() {
    _s.removeListener(_r);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Who is riding?'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                const Text('We’ll share this info with the driver',
                    style: TextStyle(fontSize: 13, color: _sub)),
                const SizedBox(height: 16),
                _riderRow(null, 'Me', '+234 803 000 0000'),
                for (final r in _s.savedRiders) _riderRow(r, r.name, r.phone),
                InkWell(
                  onTap: _addSomeone,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(children: const [
                      Icon(Icons.add, size: 20, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text('Add someone else',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ]),
                  ),
                ),
                if (_picked != null) ...[
                  const SizedBox(height: 12),
                  // 968:20032 — let the rider get the driver + vehicle details by SMS.
                  Container(
                    decoration:
                        BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                          Text('Share ride details with rider',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                          SizedBox(height: 3),
                          Text('Let them know the vehicle number, arrival time and driver location.',
                              style: TextStyle(fontSize: 12, color: _sub, height: 1.3)),
                        ]),
                      ),
                      Switch(
                        value: _share,
                        onChanged: (v) => setState(() => _share = v),
                        activeColor: AppColors.white,
                        activeTrackColor: AppColors.primary,
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: PrimaryButton(
              label: 'Next',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ScheduleReviewScreen(
                  pickup: widget.pickup,
                  destination: widget.destination,
                  when: widget.when,
                  quote: widget.quote,
                  rider: _picked,
                  shareWithRider: _share,
                ),
              )),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _riderRow(RiderContact? c, String name, String phone) {
    final on = _picked == c;
    return Column(children: [
      InkWell(
        onTap: () => setState(() => _picked = c),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF0F2FA), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(name[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                        color: _ink)),
                const SizedBox(height: 2),
                Text(phone, style: const TextStyle(fontSize: 12, color: _sub)),
              ]),
            ),
            if (c != null)
              InkWell(
                onTap: () => _riderMenu(c),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.more_horiz, size: 20, color: _sub),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 18, height: 18,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: on ? AppColors.primary : const Color(0xFFC7CBD9),
                      width: on ? 5 : 1.5)),
            ),
          ]),
        ),
      ),
      const Divider(height: 1, color: _line),
    ]);
  }

  /// 968:19576 — Edit rider / Remove rider.
  void _riderMenu(RiderContact c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
                width: 68, height: 5,
                decoration: BoxDecoration(
                    color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18))),
          ),
          const SizedBox(height: 18),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined, size: 20, color: _ink),
            title: const Text('Edit rider', style: TextStyle(fontSize: 14, color: _ink)),
            onTap: () {
              Navigator.pop(ctx);
              _addSomeone(edit: c);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
            title: const Text('Remove rider',
                style: TextStyle(fontSize: 14, color: AppColors.red)),
            onTap: () {
              if (_picked == c) _picked = null;
              _s.removeRider(c);
              Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
  }

  /// 968:19165 — rider's name + phone.
  void _addSomeone({RiderContact? edit}) {
    final name = TextEditingController(text: edit?.name ?? '');
    final phone = TextEditingController(text: edit?.phone ?? '+234 ');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            final ok = name.text.trim().isNotEmpty &&
                phone.text.replaceAll(RegExp(r'\D'), '').length >= 11;
            return Container(
              decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                          width: 68, height: 5,
                          decoration: BoxDecoration(
                              color: const Color(0xFFDCDFE5),
                              borderRadius: BorderRadius.circular(18))),
                    ),
                    const SizedBox(height: 16),
                    Text(edit == null ? 'Add rider' : 'Edit rider',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                    const SizedBox(height: 6),
                    const Text('The driver will see this name and number.',
                        style: TextStyle(fontSize: 13, color: _sub)),
                    const SizedBox(height: 18),
                    LabeledField(
                        label: 'Rider’s name',
                        controller: name,
                        hint: 'Enter rider’s name',
                        onChanged: (_) => setSheet(() {})),
                    const SizedBox(height: 14),
                    LabeledField(
                        label: 'Phone number',
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setSheet(() {})),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: edit == null ? 'Add rider' : 'Save changes',
                      enabled: ok,
                      onTap: () {
                        if (edit != null) {
                          edit.name = name.text.trim();
                          edit.phone = phone.text.trim();
                          _s.touch();
                        } else {
                          final c = RiderContact(
                              name: name.text.trim(), phone: phone.text.trim());
                          _s.addRider(c);
                          _picked = c;
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  ]),
            );
          },
        ),
      ),
    );
  }
}

/// 966:18865 — review everything before booking, each block editable.
class ScheduleReviewScreen extends StatefulWidget {
  const ScheduleReviewScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.when,
    required this.quote,
    required this.rider,
    required this.shareWithRider,
  });
  final Place pickup;
  final Place destination;
  final DateTime when;
  final RideQuote quote;
  final RiderContact? rider;
  final bool shareWithRider;

  @override
  State<ScheduleReviewScreen> createState() => _ScheduleReviewScreenState();
}

class _ScheduleReviewScreenState extends State<ScheduleReviewScreen> {
  Place get _pickup => widget.pickup;
  Place get _dest => widget.destination;
  RideQuote get _quote => widget.quote;

  late final ScheduledRide _ride = ScheduledRide(
    pickup: _pickup,
    destination: _dest,
    when: widget.when,
    tier: _quote.tier.name,
    fare: _quote.instant,
    paymentLabel: PaymentStore.instance.selectedLabel,
    rider: widget.rider,
    shareDetailsWithRider: widget.shareWithRider,
  );

  @override
  Widget build(BuildContext context) {
    final mins = PricingService.instance.tripMinutes(_dest.distanceKm);
    // A fare booked days out can only be a range — never quote it as fixed.
    final low = (_ride.fare * 0.9).round();
    final high = (_ride.fare * 1.2).round();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Review your ride'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                _block('Date & time', () => Navigator.of(context).pop(), [
                  _kv('Date', _ride.dateLabel),
                  _kv('Pickup time', _ride.timeLabel),
                ]),
                const SizedBox(height: 20),
                _block('Route', () => Navigator.of(context).pop(), [
                  _stop(_pickup.subtitle.isEmpty ? _pickup.name : _pickup.subtitle,
                      'Driver will pick you up at ${_ride.pickupWindow}', true),
                  const SizedBox(height: 14),
                  _stop(_dest.name,
                      'Estimated dropoff: ${_ride.estimatedDropoff(mins)}', false),
                ]),
                const SizedBox(height: 20),
                _block('Ride details', null, [
                  _kv('Ride type', _quote.tier.name),
                  _kv('Payment', _ride.paymentLabel),
                  _kv('Estimated fare', '${naira(low)} – ${naira(high)}'),
                  if (_ride.forSomeoneElse) _kv('Rider', _ride.rider!.name),
                ]),
                const SizedBox(height: 16),
                Container(
                  decoration:
                      BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(14),
                  child: Row(children: const [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'The final fare is confirmed when a driver accepts. You can still negotiate then.',
                          style: TextStyle(fontSize: 12, color: _sub, height: 1.4)),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: PrimaryButton(
              label: 'Schedule ride',
              onTap: () {
                ScheduleStore.instance.add(_ride);
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => ScheduleConfirmedScreen(ride: _ride)));
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _block(String title, VoidCallback? onEdit, List<Widget> children) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stroke)),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
            const Spacer(),
            if (onEdit != null)
              InkWell(
                onTap: onEdit,
                child: const Text('Edit',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(k, style: const TextStyle(fontSize: 13, color: _sub)),
          const Spacer(),
          Text(v,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
        ]),
      );

  Widget _stop(String addr, String note, bool isPickup) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isPickup ? Icons.radio_button_checked : Icons.location_on,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(addr, style: const TextStyle(fontSize: 14, color: _ink)),
              const SizedBox(height: 3),
              Text(note, style: const TextStyle(fontSize: 12, color: _sub)),
            ]),
          ),
        ],
      );
}

/// 968:20787 — booked.
class ScheduleConfirmedScreen extends StatelessWidget {
  const ScheduleConfirmedScreen({super.key, required this.ride});
  final ScheduledRide ride;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 76, height: 76,
                    decoration:
                        const BoxDecoration(color: Color(0xFFECFDF3), shape: BoxShape.circle),
                    child: const Icon(Icons.event_available, size: 34, color: AppColors.green),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text('Ride scheduled',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _ink)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                      ride.forSomeoneElse
                          ? 'We’ll text ${ride.rider!.name} the driver details before pickup.'
                          : 'We’ll assign a driver shortly before your pickup time.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.mutedText, height: 1.45)),
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.stroke)),
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _kv('Date & time', ride.whenLabel),
                    _kv('Pickup', ride.pickup.subtitle.isEmpty
                        ? ride.pickup.name
                        : ride.pickup.subtitle),
                    _kv('Destination', ride.destination.name),
                    _kv('Ride type', ride.tier),
                    _kv('Payment', ride.paymentLabel),
                    if (ride.forSomeoneElse) _kv('Rider', ride.rider!.name),
                  ]),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                    label: 'Done',
                    onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: const TextStyle(fontSize: 13, color: _sub)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
          ),
        ]),
      );
}

/// 989:17223 — the scheduled-ride card that sits on the home screen.
class ScheduledRideCard extends StatefulWidget {
  const ScheduledRideCard({super.key});
  @override
  State<ScheduledRideCard> createState() => _ScheduledRideCardState();
}

class _ScheduledRideCardState extends State<ScheduledRideCard> {
  final _s = ScheduleStore.instance;

  @override
  void initState() {
    super.initState();
    _s.addListener(_r);
  }

  void _r() => setState(() {});

  @override
  void dispose() {
    _s.removeListener(_r);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_s.rides.isEmpty) return const SizedBox.shrink();
    final r = _s.rides.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stroke)),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.event, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Scheduled ride',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
          const Spacer(),
          Text(r.whenLabel, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
        ]),
        const SizedBox(height: 10),
        _line(Icons.radio_button_checked,
            r.pickup.subtitle.isEmpty ? r.pickup.name : r.pickup.subtitle),
        const SizedBox(height: 6),
        _line(Icons.location_on, r.destination.name),
        if (r.forSomeoneElse) ...[
          const SizedBox(height: 8),
          Text('For ${r.rider!.name}',
              style: const TextStyle(fontSize: 12, color: _sub)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.stroke),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ScheduleConfirmedScreen(ride: r))),
                child: const Text('View details',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 38,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.red.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => _confirmCancel(r),
                child: const Text('Cancel',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _line(IconData i, String text) => Row(children: [
        Icon(i, size: 14, color: _sub),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _ink)),
        ),
      ]);

  void _confirmCancel(ScheduledRide r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel scheduled ride?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
        content: Text(
            'Your ${r.whenLabel} ride will be cancelled. It’s free to cancel more than 1 hour before pickup.',
            style: const TextStyle(fontSize: 14, color: _sub, height: 1.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep it',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary))),
          TextButton(
              onPressed: () {
                _s.cancel(r);
                Navigator.pop(ctx);
              },
              child: const Text('Cancel ride',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.red))),
        ],
      ),
    );
  }
}

/// Lightweight destination/pickup picker that returns a [Place] via pop.
/// Used by the schedule flow so pickup is editable and a destination is chosen.
class _LocationPickerScreen extends StatefulWidget {
  const _LocationPickerScreen({required this.title, this.allowCurrent = false});
  final String title;
  final bool allowCurrent;

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  final _q = TextEditingController();
  List<Place> _results = PlacesRepository.instance.recents;

  @override
  void initState() {
    super.initState();
    _q.addListener(() =>
        setState(() => _results = PlacesRepository.instance.search(_q.text)));
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          AccountHeader(title: widget.title),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                  color: _fieldBg, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                const Icon(Icons.search, size: 20, color: _sub),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _q,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) => v.trim().isNotEmpty ? _useTyped() : null,
                    style: const TextStyle(fontSize: 15, color: _ink),
                    decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Enter address or place',
                        hintStyle: TextStyle(fontSize: 15, color: Color(0xFFB0B4C4))),
                  ),
                ),
                if (_q.text.isNotEmpty)
                  InkWell(
                    onTap: () => setState(_q.clear),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 18, color: _sub),
                    ),
                  ),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // Manually type any address — not everywhere is in the list.
                if (_q.text.trim().isNotEmpty) _useTypedTile(),
                if (widget.allowCurrent && _q.text.trim().isEmpty)
                  _tile(PlacesRepository.currentLocation, isCurrent: true),
                for (final p in _results) _tile(p),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  /// Return a Place built from exactly what the rider typed.
  void _useTyped() {
    final text = _q.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(Place(name: text, subtitle: '', distanceKm: 6.0));
  }

  Widget _useTypedTile() => InkWell(
        onTap: _useTyped,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            const Icon(Icons.add_location_alt_outlined, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Use “${_q.text.trim()}”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 2),
                const Text('Set this as your address',
                    style: TextStyle(fontSize: 12, color: _sub)),
              ]),
            ),
          ]),
        ),
      );

  Widget _tile(Place p, {bool isCurrent = false}) => InkWell(
        onTap: () => Navigator.of(context).pop(p),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Icon(isCurrent ? Icons.my_location : iconFor(p.icon),
                size: 20, color: isCurrent ? AppColors.primary : _sub),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name,
                    style: const TextStyle(fontSize: 14, color: _ink)),
                if (p.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(p.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _sub)),
                ],
              ]),
            ),
            if (!isCurrent && p.distanceKm > 0)
              Text('${p.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 12, color: _sub)),
          ]),
        ),
      );
}
