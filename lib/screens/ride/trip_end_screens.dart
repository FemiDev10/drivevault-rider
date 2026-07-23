import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';
import '../../services/mock/driver.dart';
import 'choose_ride_screen.dart';
import 'receipt_screen.dart';

const _ink = Color(0xFF0A0F2C);

/// Re-book the same route (Repeat ride) or the reverse (Return route).
void _rebook(BuildContext context, Place from, Place to) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChooseRideScreen(pickup: from, destination: to)));
}
const _sub = Color(0xFF808080);
const _payGrey = Color(0xFF6A6C88);
const _stroke = Color(0xFFE6E6E6);
const _blueStroke = Color(0xFFE8ECF8);

/// Frame 380 (958:15306) — "You've arrived!" centred modal. Pixel-matched.
class ArrivedDialog extends StatelessWidget {
  const ArrivedDialog({super.key, required this.pickup, required this.destination, required this.total, required this.tier});
  final Place pickup;
  final Place destination;
  final int total;
  final String tier;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: SizedBox(
          width: 300,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(7)),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Featured success icon: #D1FADF disc with a #ECFDF3 ring
                    Container(
                      width: 70, height: 70,
                      decoration: const BoxDecoration(color: Color(0xFFECFDF3), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Container(
                        width: 56, height: 56,
                        decoration: const BoxDecoration(color: Color(0xFFD1FADF), shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 28, color: Color(0xFF039855)),
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text('You’ve arrived!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black)),
                    const SizedBox(height: 2),
                    const Text('Hope it was a smooth ride', style: TextStyle(fontSize: 12, color: _sub)),
                    const SizedBox(height: 17),
                    // Total fare — gradient card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Color(0xFF1A2A80), Color(0xFF2A3A90)]),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('Total fare', style: TextStyle(fontSize: 12, color: Color(0xCCFFFFFF))),
                          const SizedBox(height: 4),
                          Text(naira(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.white)),
                          const SizedBox(height: 4),
                          Text('Bank Transfer · $tier ride', style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    // Info card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(7)),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _kv('Pickup', pickup.subtitle.isNotEmpty ? pickup.subtitle : pickup.name),
                          const SizedBox(height: 10),
                          _kv('Drop-off', destination.name),
                          const SizedBox(height: 10),
                          _kv('Distance', '${destination.distanceKm.toStringAsFixed(1)}km'),
                          const SizedBox(height: 10),
                          _kv('Driver', kDriver.name),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    // Rate Driver
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: AppColors.primary, borderRadius: BorderRadius.circular(26),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => RateDriverScreen(total: total, pickup: pickup, destination: destination, tier: tier)));
                          },
                          borderRadius: BorderRadius.circular(26),
                          child: const Padding(padding: EdgeInsets.symmetric(vertical: 13),
                              child: Center(child: Text('Rate Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // View details
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TripSummaryScreen(total: total, pickup: pickup, destination: destination, tier: tier)));
                      },
                      borderRadius: BorderRadius.circular(26),
                      child: const Padding(padding: EdgeInsets.symmetric(vertical: 13),
                          child: Center(child: Text('View details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _payGrey)))),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10, top: 11,
                child: InkWell(
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Icon(Icons.close, size: 21, color: Color(0xFF667085)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 12px Regular, label #808080 left ↔ value black right.
  Widget _kv(String k, String v) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontSize: 12, color: _sub)),
          const SizedBox(width: 12),
          Expanded(child: Text(v, textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: AppColors.black))),
        ],
      );
}

/// Frames 377 → 379 — rate (stars first, feedback revealed after a star is chosen).
class RateDriverScreen extends StatefulWidget {
  const RateDriverScreen({super.key, required this.total, required this.pickup, required this.destination, required this.tier});
  final int total;
  final Place pickup;
  final Place destination;
  final String tier;

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int _stars = 0;
  final _tags = <String>{};
  bool _submitted = false;
  static const _allTags = ['Friendly', 'On time', 'Respectful', 'Clean', 'Good conversation', 'Quiet'];

  void _submit() {
    if (_stars == 0) return;
    setState(() => _submitted = true);
    Timer(const Duration(milliseconds: 900), _toSummary);
  }

  void _toSummary() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TripSummaryScreen(total: widget.total, pickup: widget.pickup, destination: widget.destination, tier: widget.tier)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                const StatusBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Rate your driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                        const SizedBox(height: 4),
                        const Text('Your feedback helps us maintain quality service',
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _sub)),
                        const SizedBox(height: 20),
                        _driverCard(),
                        const SizedBox(height: 24),
                        const Text('How was your ride?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final on = i < _stars;
                            return GestureDetector(
                              onTap: () => setState(() => _stars = i + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(on ? Icons.star : Icons.star_border, size: 42,
                                    color: on ? const Color(0xFFF5C518) : const Color(0xFFCBD0DC)),
                              ),
                            );
                          }),
                        ),
                        // Feedback revealed only after a rating is chosen (frame 379).
                        if (_stars > 0) ...[
                          const SizedBox(height: 28),
                          const Align(alignment: Alignment.centerLeft,
                              child: Text('Add feedback (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink))),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10, runSpacing: 10,
                            children: _allTags.map((t) {
                              final on = _tags.contains(t);
                              return GestureDetector(
                                onTap: () => setState(() => on ? _tags.remove(t) : _tags.add(t)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: on ? AppColors.primary.withValues(alpha: 0.08) : AppColors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: on ? AppColors.primary : const Color(0xFFE6E8F0)),
                                  ),
                                  child: Text(t, style: TextStyle(fontSize: 13, color: on ? AppColors.primary : AppColors.black)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          const Align(alignment: Alignment.centerLeft,
                              child: Text('Feedback (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink))),
                          const SizedBox(height: 8),
                          Container(
                            height: 100,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE6E8F0))),
                            padding: const EdgeInsets.all(12),
                            child: const TextField(
                              maxLines: null, expands: true, cursorColor: AppColors.primary,
                              decoration: InputDecoration(isCollapsed: true, border: InputBorder.none,
                                  hintText: 'Tell us more…', hintStyle: TextStyle(fontSize: 13, color: _sub)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity, height: 51,
                        child: Material(
                          color: _stars > 0 ? AppColors.primary : const Color(0xFFEDEFF5),
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            onTap: _stars > 0 ? _submit : null,
                            borderRadius: BorderRadius.circular(30),
                            child: Center(child: Text('Submit rating',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _stars > 0 ? AppColors.white : _sub))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(onTap: _toSummary, child: const Text('Skip', style: TextStyle(fontSize: 14, color: _sub))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_submitted)
            Positioned(top: 26, left: 24, right: 24, child: Container(
              height: 49,
              decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: const Text('Rating submitted!', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            )),
        ],
      ),
    );
  }

  Widget _driverCard() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _initialsAvatar(48, 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kDriver.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 2),
                Text('${kDriver.car} · ${kDriver.plate}', style: const TextStyle(fontSize: 13, color: _sub)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star, size: 14, color: Color(0xFFF5C518)),
                  const SizedBox(width: 4),
                  Text('${kDriver.rating} · ${kDriver.trips} trips', style: const TextStyle(fontSize: 12, color: _sub)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _initialsAvatar(double size, double fontSize) => Container(
      width: size, height: size,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(kDriver.initials, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: AppColors.white)),
    );

/// Frame 2667:19566 — trip summary / view details (static map, fare breakdown).
class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key, required this.total, required this.pickup, required this.destination, required this.tier});
  final int total;
  final Place pickup;
  final Place destination;
  final String tier;

  @override
  Widget build(BuildContext context) {
    const booking = 224, discount = 500;
    final rideFare = total - booking + discount;
    final km = destination.distanceKm;
    final mins = PricingService.instance.tripMinutes(km);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const StatusBar(),
            SizedBox(
              height: 42,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    InkWell(onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: _ink)),
                    const Expanded(child: Center(child: Text('Fri, 29 May 2026 · 5:43 PM',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)))),
                    const SizedBox(width: 18),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  // Static map with distance pill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 180,
                      child: Stack(
                        children: [
                          Positioned.fill(child: Image.asset('assets/images/route_map.png', fit: BoxFit.cover, alignment: Alignment.center)),
                          Positioned(
                            left: 12, top: 13,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 1)]),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.navigation, size: 11, color: AppColors.primary),
                                const SizedBox(width: 7),
                                Text('${km.toStringAsFixed(1)} km · $mins min', style: const TextStyle(fontSize: 11, color: _ink)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Trip summary card
                  _card(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trip summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
                      const SizedBox(height: 16),
                      _routeRow(Icons.radio_button_unchecked,
                          pickup.subtitle.isNotEmpty ? pickup.subtitle : pickup.name, '05:56 PM'),
                      const SizedBox(height: 16),
                      _routeRow(Icons.location_on, destination.name, '06:32 PM'),
                      const SizedBox(height: 16),
                      Row(children: [
                        const Icon(Icons.schedule, size: 16, color: _ink),
                        const SizedBox(width: 4),
                        Text('$mins min', style: const TextStyle(fontSize: 12, color: _ink)),
                        const SizedBox(width: 16),
                        const Icon(Icons.navigation_outlined, size: 16, color: _ink),
                        const SizedBox(width: 4),
                        Text('${km.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: _ink)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.local_taxi_outlined, size: 16, color: _ink),
                        const SizedBox(width: 6),
                        Text(kTierLabel, style: const TextStyle(fontSize: 12, color: _ink)),
                      ]),
                    ],
                  )),
                  const SizedBox(height: 16),
                  // Action buttons row
                  _card(Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionBtn(icon: Icons.receipt_long_outlined, label: 'Receipt',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ReceiptScreen(total: total, pickup: pickup, destination: destination)))),
                      const _ActionBtn(icon: Icons.chat_bubble_outline, label: 'Support'),
                      _ActionBtn(icon: Icons.refresh, label: 'Repeat ride', onTap: () => _rebook(context, pickup, destination)),
                      _ActionBtn(icon: Icons.alt_route, label: 'Return route', onTap: () => _rebook(context, destination, pickup)),
                    ],
                  )),
                  const SizedBox(height: 16),
                  // Driver row
                  Row(children: [
                    _initialsAvatar(48, 16),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kDriver.name.split(' ').first, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
                        const SizedBox(height: 4),
                        Text('${kDriver.car} · ${kDriver.plate}', style: const TextStyle(fontSize: 14, color: Color(0xFF8A90A8))),
                      ],
                    )),
                    Row(children: [
                      Text('${kDriver.rating}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A90A8))),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 18, color: Color(0xFFF5C518)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  // Fare breakdown
                  _card(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fare breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                      const SizedBox(height: 12),
                      _fareRow('Ride Fare', naira(rideFare)),
                      _fareRow('Distance', '${km.toStringAsFixed(1)}km'),
                      _fareRow('Time', '$mins mins'),
                      _fareRow('Booking fee', naira(booking)),
                      _fareRow('Discount', '-${naira(discount)}', color: const Color(0xFF193CB8)),
                      _fareRow('Total', naira(total), bold: true, border: false),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.all(8),
                        child: Row(children: [
                          Container(width: 32, height: 32,
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(6)),
                              alignment: Alignment.center,
                              child: const Text('₦', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF10B981)))),
                          const SizedBox(width: 8),
                          const Text('Bank Transfer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                        ]),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _stroke)),
        padding: const EdgeInsets.all(17),
        child: child,
      );

  Widget _routeRow(IconData icon, String text, String time) => Row(
        children: [
          Icon(icon, size: 16, color: icon == Icons.location_on ? AppColors.primary : _ink),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: _ink))),
          Text(time, style: const TextStyle(fontSize: 12, color: _payGrey)),
        ],
      );

  Widget _fareRow(String k, String v, {bool bold = false, bool border = true, Color? color}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: border ? const BoxDecoration(border: Border(bottom: BorderSide(color: _blueStroke))) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: _ink)),
            Text(v, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: color ?? _ink)),
          ],
        ),
      );

  Widget _bottomNav() => Container(
        height: 72,
        decoration: const BoxDecoration(color: AppColors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 4)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _NavItem(icon: Icons.home_outlined, label: 'Home', active: false),
            _NavItem(icon: Icons.event_note, label: 'Trips', active: true),
            _NavItem(icon: Icons.person_outline, label: 'Account', active: false),
          ],
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(width: 48, height: 48,
              decoration: const BoxDecoration(color: Color(0xFFF5F6FA), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: _ink)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active});
  final IconData icon;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final c = active ? AppColors.primary : _sub;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: c)),
      ],
    );
  }
}
