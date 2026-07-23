import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/live_map.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';
import '../../services/mock/rewards_repository.dart';
import '../../services/mock/driver.dart';
import 'trip_end_screens.dart';
import 'ride_outcome_screens.dart';
import 'incoming_call_screen.dart';
import '../safety/safety_screens.dart';
import 'trip_details_sheet.dart';
import 'payment_status_screen.dart';
import 'message_call_screens.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);

enum _Phase { finding, negotiating, confirmed, arrived, inProgress }

class RideProgressScreen extends StatefulWidget {
  const RideProgressScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.quote,
    required this.mode,
    this.offer = 0,
    this.autoAccept = false,
  });
  final Place pickup;
  final Place destination;
  final RideQuote quote;
  final PriceMode mode;
  final int offer;
  final bool autoAccept;

  @override
  State<RideProgressScreen> createState() => _RideProgressScreenState();
}

class _RideProgressScreenState extends State<RideProgressScreen> {
  _Phase _phase = _Phase.finding;
  Timer? _callTimer;
  int _round = 1;
  late int _driverAsk;
  late int _prevDriverAsk;
  late int _riderOffer;
  int _agreed = 0;
  int _roundSecs = 60; // per-round response timer
  Timer? _roundTimer;
  final List<_NegMsg> _msgs = [];
  bool _awaitingRider = true; // whose turn it is to respond

  String _now() {
    final t = DateTime.now();
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  }
  bool _driverTyping = false;
  Timer? _timer;
  Timer? _tick;
  int _wait = 203; // 3:23
  double _tripProgress = 0;

  @override
  void initState() {
    super.initState();
    _riderOffer = widget.offer;
    _driverAsk = widget.quote.negHigh;
    _prevDriverAsk = widget.quote.negHigh;
    WidgetsBinding.instance.addPostFrameCallback((_) => _chargeThenFind());
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _timer?.cancel();
    _tick?.cancel();
    _roundTimer?.cancel();
    super.dispose();
  }

  void _startRoundTimer() {
    _roundTimer?.cancel();
    setState(() => _roundSecs = _round >= 3 ? 30 : 60); // 30s on the final round
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _roundSecs = _roundSecs > 0 ? _roundSecs - 1 : 0);
      if (_roundSecs == 0) {
        t.cancel();
        if (_awaitingRider && _phase == _Phase.negotiating) _riderTimeout();
      }
    });
  }

  bool get _far => widget.destination.distanceKm >= 15; // scenario: long trip

  /// Card payments are debited FIRST — before a driver is found.
  /// Demo rule: Mastercard is declined (635), Visa/others succeed (332).
  Future<void> _chargeThenFind() async {
    final store = PaymentStore.instance;
    if (store.selectedId.startsWith('card:')) {
      final last4 = store.selectedId.substring(5);
      final card = store.cards.where((c) => c.last4 == last4).toList();
      final declined = card.isNotEmpty && card.first.brand == 'mastercard';
      final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => PaymentStatusScreen(outcome: declined ? PayOutcome.declined : PayOutcome.success)));
      if (ok != true) {
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
    }
    // High demand only shows on long trips (≥15km); otherwise find a driver directly.
    _timer = Timer(const Duration(milliseconds: 2500), _far ? _showHighDemand : _afterFinding);
  }

  /// Frame 648 — "Drivers are in high demand" (shown during finding).
  Future<void> _showHighDemand() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HighDemandSheet(),
    );
    if (mounted) _afterFinding();
  }

  void _afterFinding() {
    if (!mounted) return;
    if (widget.mode == PriceMode.instant) {
      _confirm(widget.quote.instant);
    } else {
      _startNegotiation();
    }
  }

  /// Driver counters the rider's opening offer immediately (round 1).
  void _startNegotiation() {
    _driverAsk = widget.quote.negHigh;
    _prevDriverAsk = widget.quote.negHigh + 600; // implied list price → shows "↓ ₦600 less"
    setState(() {
      _phase = _Phase.negotiating;
      _msgs.add(_NegMsg(mine: true, amount: widget.offer, time: _now(), diff: 0, label: 'Your opening offer'));
      _msgs.add(_NegMsg(mine: false, amount: _driverAsk, time: _now(), diff: _driverAsk - _prevDriverAsk, label: "Driver's counter offer"));
      _awaitingRider = true;
    });
    _startRoundTimer();
  }

  void _confirm(int price) {
    setState(() {
      _agreed = price;
      _phase = _Phase.confirmed;
    });
    // Drivers usually ring to confirm the pickup spot once they're on the way.
    _callTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) IncomingCallScreen.ring(context);
    });
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.arrived);
      _tick = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _wait = _wait > 0 ? _wait - 1 : 0);
        if (_wait == 0) t.cancel();
      });
      // Long trips demo the no-show: driver waits, rider never shows → 552.
      // Otherwise the driver starts the trip a few seconds after arriving.
      _timer = Timer(Duration(milliseconds: _far ? 8000 : 4500), _far ? _missedDriver : _startTrip);
    });
  }

  /// 4116:22166 — confirm before throwing away an in-flight negotiation.
  void _cancelNegotiation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel negotiation?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
        content: const Text(
            'Your current offer will be withdrawn and the driver will be released. '
            'Nothing has been charged.',
            style: TextStyle(fontSize: 14, color: _sub, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep negotiating',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endNegotiation();
            },
            child: const Text('Yes, end negotiation',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _endNegotiation({bool noAgreement = false}) {
    _roundTimer?.cancel();
    _timer?.cancel();
    _tick?.cancel();
    _callTimer?.cancel();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => NegotiationCancelledScreen(noAgreement: noAgreement)));
  }

  /// 1362:17801 — rider didn't show; the driver waited 10 minutes and left.
  void _missedDriver() {
    if (!mounted) return;
    _tick?.cancel();
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MissedDriverScreen()));
  }

  void _startTrip() {
    if (!mounted) return;
    _tick?.cancel();
    setState(() {
      _phase = _Phase.inProgress;
      _tripProgress = 0;
    });
    // Animate the car along the route to the drop-off; complete on arrival.
    _tick = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!mounted) return;
      setState(() => _tripProgress = (_tripProgress + 0.018).clamp(0.0, 1.0));
      if (_tripProgress >= 1.0) {
        t.cancel();
        _endTrip();
      }
    });
  }

  void _endTrip() {
    if (!mounted) return;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => ArrivedDialog(
        pickup: widget.pickup, destination: widget.destination, total: _agreed, tier: kTierLabel),
    );
  }

  void _openTripDetails() {
    TripDetailsSheet.show(context,
        pickup: widget.pickup, destination: widget.destination,
        fare: _agreed == 0 ? widget.quote.instant : _agreed,
        onCancel: () {
          _timer?.cancel();
          _tick?.cancel();
          _callTimer?.cancel();
          _roundTimer?.cancel();
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RideCancelledScreen()));
        });
  }

  // ----- negotiation -----
  void _bumpOffer(int d) => setState(() =>
      _riderOffer = (_riderOffer + d).clamp(widget.quote.negLow, widget.quote.negHigh));

  void _sendCounter() {
    if (_round >= 3 || _driverTyping || !_awaitingRider) return;
    _roundTimer?.cancel();
    setState(() {
      _round++;
      _msgs.add(_NegMsg(mine: true, amount: _riderOffer, time: _now(), diff: 0, label: 'Your counter'));
      _awaitingRider = false;
      _driverTyping = true;
    });
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final prev = _driverAsk;
      final next = ((_driverAsk + _riderOffer) / 2).round();
      final newAsk = ((next ~/ 20) * 20).clamp(_riderOffer, widget.quote.negHigh);
      setState(() {
        _prevDriverAsk = prev;
        _driverAsk = newAsk;
        _driverTyping = false;
        _msgs.add(_NegMsg(mine: false, amount: newAsk, time: _now(), diff: newAsk - prev, label: "Driver's counter offer"));
        _awaitingRider = true;
      });
      _startRoundTimer();
      if (widget.autoAccept && _driverAsk <= widget.offer) _confirm(_driverAsk);
    });
  }

  /// Rider didn't respond before the timer ran out.
  /// Rounds 1–2 → "You ran out of time" (562). Round 3 → simulate the driver
  /// not replying → auto-find the next driver (569 → 572) → reopen negotiation.
  void _riderTimeout() {
    if (_round >= 3) {
      _driverNoReplyRestart();
    } else {
      _show562();
    }
  }

  Future<void> _driverNoReplyRestart() async {
    // 563 "Driver didn't respond" → 569 finding animation → 572 driver found → reopen.
    await showModalBottomSheet(
      context: context, isDismissible: false, enableDrag: false,
      isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const _DriverDidntRespondSheet());
    if (!mounted) return;
    await showDialog(context: context, barrierDismissible: false, builder: (_) => const _AutoDialog(kind: _AutoKind.findingNext));
    if (!mounted) return;
    await showDialog(context: context, barrierDismissible: false, builder: (_) => const _AutoDialog(kind: _AutoKind.driverFound));
    if (!mounted) return;
    setState(() {
      _msgs.clear();
      _round = 1;
    });
    _startNegotiation();
  }

  /// Frame 562 — "You ran out of time".
  void _show562() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 68, height: 5,
              decoration: BoxDecoration(color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18)))),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, size: 22, color: _ink))),
          Container(width: 48, height: 48,
              decoration: const BoxDecoration(color: Color(0x1AF04438), shape: BoxShape.circle),
              child: const Icon(Icons.timer_outlined, size: 26, color: AppColors.red)),
          const SizedBox(height: 16),
          const Text('You ran out of time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 8),
          const Text('You didn’t respond within 60 seconds so the negotiation has ended, No charge has been applied.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _sub, height: 1.4)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFF0F2FA), borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Instant booking price', style: TextStyle(fontSize: 13, color: _sub)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                    child: const Text('AVAILABLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white))),
              ]),
              const SizedBox(height: 6),
              Text(naira(widget.quote.instant), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 2),
              const Text('Book immediately without negotiation', style: TextStyle(fontSize: 12, color: _sub)),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 51, child: Material(color: AppColors.primary, borderRadius: BorderRadius.circular(30),
              child: InkWell(borderRadius: BorderRadius.circular(30),
                  onTap: () { Navigator.pop(ctx); _confirm(widget.quote.instant); },
                  child: Center(child: Text('Book at instant price ${naira(widget.quote.instant)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)))))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 51, child: OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() { _msgs.clear(); _round = 1; _phase = _Phase.finding; });
                _timer = Timer(const Duration(milliseconds: 2200), _afterFinding);
              },
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: const Text('Find another driver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)))),
        ]),
      ),
    );
  }

  // Frame 558 — "Edit your counter" bottom sheet.
  Future<void> _editOffer() async {
    final ctrl = TextEditingController(text: _riderOffer.toString());
    final v = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Edit your counter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
              const Spacer(),
              InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, size: 22, color: _ink)),
            ]),
            const SizedBox(height: 16),
            const Text('Enter amount', style: TextStyle(fontSize: 13, color: _sub)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF0F2FA), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                const Text('₦ ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
                Expanded(child: TextField(
                  controller: ctrl, autofocus: true, keyboardType: TextInputType.number, cursorColor: AppColors.primary,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                  decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
                )),
              ]),
            ),
            const SizedBox(height: 8),
            Center(child: Text('Min ${naira(widget.quote.negLow)} — Max ${naira(widget.quote.negHigh)}',
                style: const TextStyle(fontSize: 12, color: _sub))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 51, child: Material(color: AppColors.primary, borderRadius: BorderRadius.circular(30),
                child: InkWell(borderRadius: BorderRadius.circular(30),
                    onTap: () => Navigator.pop(ctx, int.tryParse(ctrl.text.replaceAll(RegExp(r'\D'), ''))),
                    child: const Center(child: Text('Update offer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)))))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 51, child: Material(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(30),
                child: InkWell(borderRadius: BorderRadius.circular(30), onTap: () => Navigator.pop(ctx),
                    child: const Center(child: Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)))))),
          ]),
        ),
      ),
    );
    if (v != null) setState(() => _riderOffer = v.clamp(widget.quote.negLow, widget.quote.negHigh));
  }

  void _decline() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final inProgress = _phase == _Phase.inProgress;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Map fills behind everything — no white gap above the sheet.
          Positioned.fill(
            child: LiveMap(
              showRoute: inProgress,
              showCentrePin: !inProgress,
              centrePinLabel: 'Pick up on $kPickupStreet',
              tripProgress: inProgress ? _tripProgress : null,
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: StatusBar()),
          if (_phase == _Phase.confirmed)
            const Positioned(top: 60, left: 0, right: 0, child: _Banner(text: 'Your ride has been confirmed'))
          else
            Positioned(top: 64, left: 24, child: InkWell(
                onTap: _phase == _Phase.negotiating
                    ? _cancelNegotiation
                    : () => Navigator.of(context).maybePop(),
                child: Icon(_phase == _Phase.negotiating ? Icons.close : Icons.arrow_back,
                    size: 24, color: _ink))),
          // In-trip SOS — available from the moment a driver is assigned.
          if (_phase == _Phase.confirmed ||
              _phase == _Phase.arrived ||
              _phase == _Phase.inProgress)
            Positioned(
              top: 108, right: 20,
              child: Material(
                color: AppColors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showSosSheet(context),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.35), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text('SOS',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.red)),
                  ),
                ),
              ),
            ),
          Align(alignment: Alignment.bottomCenter, child: _sheet()),
        ],
      ),
    );
  }

  Widget _sheet() {
    switch (_phase) {
      case _Phase.finding: return _findingSheet();
      case _Phase.negotiating: return _negotiateSheet();
      case _Phase.confirmed: return _confirmedSheet();
      case _Phase.arrived: return _arrivedSheet();
      case _Phase.inProgress: return _inProgressSheet();
    }
  }

  BoxDecoration get _deco => const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, -2))],
      );

  Widget _wrap(List<Widget> children) => Container(
        width: double.infinity,
        decoration: _deco,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [_grabber(), const SizedBox(height: 14), ...children]),
      );

  Widget _findingSheet() => _wrap([
        const Text('Ride requested', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.black)),
        const SizedBox(height: 4),
        const Text('Finding a driver...', style: TextStyle(fontSize: 14, color: _sub)),
        const SizedBox(height: 12),
        const _IndeterminateBar(),
        const SizedBox(height: 16),
        _RideDetails(onMenu: _openTripDetails),
        const SizedBox(height: 16),
        const _MusicCard(),
      ]);

  Widget _negotiateSheet() {
    final isFinal = _round >= 3;
    return _wrap([
      // driver header
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          _initials(36, 13),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kDriver.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
            Row(children: [
              const Icon(Icons.star, size: 12, color: Color(0xFFF5C518)),
              const SizedBox(width: 3),
              Text('${kDriver.rating} · ${kDriver.car}', style: const TextStyle(fontSize: 12, color: _sub)),
            ]),
          ])),
          // per-round response timer (M:SS)
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: _roundSecs <= 10 ? AppColors.red : AppColors.primary, width: 2)),
            alignment: Alignment.center,
            child: Text('${_roundSecs ~/ 60}:${(_roundSecs % 60).toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _roundSecs <= 10 ? AppColors.red : AppColors.primary)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        for (int i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(right: 5),
            child: Icon(Icons.circle, size: 8, color: i < _round ? AppColors.red : const Color(0xFFE0E0E0))),
        const Spacer(),
        Text('Round $_round of 3', style: const TextStyle(fontSize: 12, color: _sub)),
      ]),
      const SizedBox(height: 14),
      // round-1 explainer
      if (_round == 1)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF0F2FA), borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'This negotiation has 3 rounds. You have 60 seconds per round to respond — 30 seconds on the final round. If no agreement is reached after Round 3, the negotiation ends.',
            style: TextStyle(fontSize: 12, color: Color(0xFF4D4D4D), height: 1.4)),
        ),
      const SizedBox(height: 12),
      // chat history (grows & scrolls like a real chat)
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 210),
        child: SingleChildScrollView(
          reverse: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final m in _msgs) _msgTile(m),
            if (_driverTyping)
              const Padding(padding: EdgeInsets.only(top: 4),
                  child: Align(alignment: Alignment.centerLeft, child: _TypingBubble())),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      if (_awaitingRider && !_driverTyping) ...[
        const Text('What would you like to do?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
        const SizedBox(height: 12),
        _greenBtn('Accept driver’s offer · ${naira(_driverAsk)}', () => _confirm(_driverAsk)),
        const SizedBox(height: 12),
        if (!isFinal) ...[
          const Text('OR COUNTER WITH YOUR OFFER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _sub, letterSpacing: 0.4)),
          const SizedBox(height: 10),
          Row(children: [
            _miniStep(Icons.remove, () => _bumpOffer(-100)),
            Expanded(child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(naira(_riderOffer), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(width: 6),
              GestureDetector(onTap: _editOffer, child: const Icon(Icons.edit_outlined, size: 16, color: _sub)),
            ]))),
            _miniStep(Icons.add, () => _bumpOffer(100)),
          ]),
          const SizedBox(height: 6),
          Center(child: Text('Min ${naira(widget.quote.negLow)} — Max ${naira(widget.quote.negHigh)}',
              style: const TextStyle(fontSize: 11, color: _sub))),
          const SizedBox(height: 12),
          _outlineBtn('Send counter offer · ${naira(_riderOffer)}', AppColors.primary, _sendCounter),
        ] else
          _outlineBtn('Decline', AppColors.red, _decline),
      ] else
        const Center(child: Padding(padding: EdgeInsets.all(8),
            child: Text('Waiting for the driver…', style: TextStyle(fontSize: 13, color: _sub)))),
    ]);
  }

  Widget _msgTile(_NegMsg m) {
    final down = m.diff < 0;
    final diffLabel = m.diff == 0 ? null : '${down ? '↓' : '↑'} ${naira(m.diff.abs())} ${down ? 'less' : 'more'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!m.mine)
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
              _initials(20, 9),
              const SizedBox(width: 6),
              Text(m.label, style: const TextStyle(fontSize: 11, color: _sub)),
              if (m.diff != 0) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(4)),
                    child: const Text('NEW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.white))),
              ],
            ]))
          else
            Padding(padding: const EdgeInsets.only(bottom: 4, right: 2),
                child: Text(m.label, style: const TextStyle(fontSize: 11, color: _sub))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: m.mine ? AppColors.primary : const Color(0xFFF0F2FA),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14), topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(m.mine ? 14 : 2), bottomRight: Radius.circular(m.mine ? 2 : 14),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(naira(m.amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: m.mine ? AppColors.white : _ink)),
              if (diffLabel != null)
                Text(diffLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: down ? const Color(0xFF0B7A3E) : AppColors.red)),
            ]),
          ),
          Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(m.time, style: const TextStyle(fontSize: 11, color: _sub))),
        ],
      ),
    );
  }

  Widget _confirmedSheet() => _wrap([
        const Text('Pickup in 4 min', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 12),
        _RideDetails(onMenu: _openTripDetails),
        const SizedBox(height: 12),
        _DriverCard(price: _agreed),
      ]);

  Widget _arrivedSheet() {
    final m = _wait ~/ 60, s = _wait % 60;
    return _wrap([
      Row(children: const [
        Icon(Icons.circle, size: 10, color: AppColors.green),
        SizedBox(width: 8),
        Text('Driver has arrived', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
      ]),
      const SizedBox(height: 12),
      const Text('Driver is waiting for you', style: TextStyle(fontSize: 13, color: _sub)),
      const SizedBox(height: 4),
      Text('$m:${s.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: _wait / 203, minHeight: 4,
            backgroundColor: const Color(0xFFE6E6E6), color: const Color(0xFFF59E0B)),
      ),
      const SizedBox(height: 16),
      _DriverCard(price: _agreed),
    ]);
  }

  Widget _inProgressSheet() => _wrap([
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEAF6ED), borderRadius: BorderRadius.circular(8)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ride in progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF306A00))),
            SizedBox(height: 2),
            Text('You’re on your way to your destination', style: TextStyle(fontSize: 12, color: Color(0xFF306A00))),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Destination', style: TextStyle(fontSize: 13, color: _sub)),
        const SizedBox(height: 4),
        Text(widget.destination.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
        const SizedBox(height: 16),
        _DriverCard(price: _agreed),
      ]);

  Widget _grabber() => Center(child: Container(width: 68, height: 5,
      decoration: BoxDecoration(color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18))));

  Widget _greenBtn(String label, VoidCallback? onTap) => SizedBox(
        width: double.infinity, height: 48,
        child: Material(color: onTap == null ? AppColors.green.withValues(alpha: 0.5) : AppColors.green, borderRadius: BorderRadius.circular(30),
            child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(30),
                child: Center(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white))))),
      );

  Widget _outlineBtn(String label, Color color, VoidCallback? onTap) => SizedBox(
        width: double.infinity, height: 48,
        child: OutlinedButton(onPressed: onTap,
            style: OutlinedButton.styleFrom(side: BorderSide(color: color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color))),
      );

  Widget _miniStep(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0xFFF0F2FA), shape: const CircleBorder(),
        child: InkWell(onTap: onTap, customBorder: const CircleBorder(),
            child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 18, color: AppColors.primary))),
      );

  Widget _initials(double size, double fs) => Container(width: size, height: size,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(kDriver.initials, style: TextStyle(fontSize: fs, fontWeight: FontWeight.w700, color: AppColors.white)));
}

// ---------- shared ----------

class _Banner extends StatelessWidget {
  const _Banner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(height: 44,
            decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(text, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600))),
      );
}

class _RideDetails extends StatelessWidget {
  const _RideDetails({required this.onMenu});
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.stroke)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ride details', style: TextStyle(fontSize: 14, color: _sub)),
            const SizedBox(height: 5),
            const Text('Meet at your pickup spot on $kPickupStreet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFEAF6ED), borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF306A00)),
                SizedBox(width: 4),
                Text('Bank Transfer', style: TextStyle(fontSize: 14, color: Color(0xFF306A00))),
              ]),
            ),
          ])),
          InkWell(
            onTap: onMenu,
            customBorder: const CircleBorder(),
            child: Container(width: 35, height: 35,
                decoration: const BoxDecoration(color: Color(0xFFF9F9FF), shape: BoxShape.circle),
                child: const Icon(Icons.more_horiz, size: 20, color: _ink)),
          ),
        ],
      ),
    );
  }
}

class _MusicCard extends StatelessWidget {
  const _MusicCard();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(aspectRatio: 346 / 200, child: Image.asset('assets/images/driver_wait.png', fit: BoxFit.cover, alignment: Alignment.topCenter)),
        Container(color: const Color(0xFFEBD5FF), padding: const EdgeInsets.all(16),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Listen to a music while you wait', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black)),
              SizedBox(height: 8),
              Text('Have some fun while you wait, just tap the screens to dodge the obstacles',
                  style: TextStyle(fontSize: 14, color: Color(0xFF4D4D4D))),
            ])),
      ]),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.price});
  final int price;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.stroke)),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            CircleAvatar(radius: 24, backgroundImage: AssetImage(kDriver.avatar)),
            const SizedBox(height: 6),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, size: 14, color: Color(0xFFF5C518)),
              const SizedBox(width: 2),
              Text('${kDriver.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.black)),
            ]),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kDriver.plate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 2),
            Text(kDriver.car, style: const TextStyle(fontSize: 13, color: _sub)),
            const SizedBox(height: 2),
            Text(kDriver.name, style: const TextStyle(fontSize: 13, color: AppColors.black)),
            const SizedBox(height: 2),
            Row(children: const [
              Icon(Icons.verified, size: 14, color: AppColors.primary),
              SizedBox(width: 4),
              Text('Verified', style: TextStyle(fontSize: 13, color: AppColors.primary)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(naira(price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 2),
            Text('${kDriver.trips} trips', style: const TextStyle(fontSize: 12, color: _sub)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: SizedBox(height: 48, child: Material(color: AppColors.primary, borderRadius: BorderRadius.circular(30),
              child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessageScreen())),
                  borderRadius: BorderRadius.circular(30),
                  child: const Center(child: Text('Message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white))))))),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => showCallDriverSheet(context),
            customBorder: const CircleBorder(),
            child: Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFFF5F6FA), shape: BoxShape.circle),
                child: const Icon(Icons.call_outlined, size: 20, color: AppColors.primary)),
          ),
        ]),
      ]),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF0F2FA), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('Driver is typing', style: TextStyle(fontSize: 12, color: _sub)),
        const SizedBox(width: 8),
        AnimatedBuilder(animation: _c, builder: (context, _) {
          return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
            final t = ((_c.value + i * 0.2) % 1.0);
            final o = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(opacity: o, child: const CircleAvatar(radius: 3, backgroundColor: _sub)));
          }));
        }),
      ]),
    );
  }
}

class _IndeterminateBar extends StatelessWidget {
  const _IndeterminateBar();
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(4),
      child: const LinearProgressIndicator(minHeight: 4, backgroundColor: Color(0xFFECECEC), color: AppColors.primary));
}

/// Card payment: processing → success (pops true) / fail (pops false).
class PaymentProcessingDialog extends StatefulWidget {
  const PaymentProcessingDialog({super.key});
  @override
  State<PaymentProcessingDialog> createState() => _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<PaymentProcessingDialog> {
  int _state = 0;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _state = 1);
      Timer(const Duration(milliseconds: 900), () { if (mounted) Navigator.of(context).pop(true); });
    });
  }
  @override
  void dispose() { _t?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_state == 0) ...[
            const SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary)),
            const SizedBox(height: 16),
            const Text('Debiting your card', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 4),
            const Text('Please wait…', style: TextStyle(fontSize: 12, color: _sub)),
          ] else ...[
            Container(width: 64, height: 64, decoration: const BoxDecoration(color: Color(0x1A00853F), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, size: 40, color: AppColors.green)),
            const SizedBox(height: 16),
            const Text('Payment successful', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
          ],
        ]),
      ),
    );
  }
}

class _NegMsg {
  final bool mine;
  final int amount;
  final String time;
  final int diff;
  final String label;
  const _NegMsg({required this.mine, required this.amount, required this.time, required this.diff, required this.label});
}

enum _AutoKind { findingNext, driverFound }

/// Frames 569 / 572 — driver-no-reply auto flow (self-dismisses).
class _AutoDialog extends StatefulWidget {
  const _AutoDialog({required this.kind});
  final _AutoKind kind;
  @override
  State<_AutoDialog> createState() => _AutoDialogState();
}

class _AutoDialogState extends State<_AutoDialog> with SingleTickerProviderStateMixin {
  Timer? _t;
  late final AnimationController _car =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 2800), () { if (mounted) Navigator.of(context).pop(); });
  }
  @override
  void dispose() { _t?.cancel(); _car.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final found = widget.kind == _AutoKind.driverFound;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  // old driver, crossed out
                  Stack(clipBehavior: Clip.none, children: [
                    Container(width: 56, height: 56,
                        decoration: const BoxDecoration(color: Color(0xFFE7E9F0), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Text('OA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF9AA0B4)))),
                    Positioned(right: -2, top: -2, child: Container(width: 20, height: 20,
                        decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 13, color: AppColors.white))),
                  ]),
                  const SizedBox(width: 70), // gap the car travels across
                  // new driver
                  if (found)
                    Stack(clipBehavior: Clip.none, children: [
                      CircleAvatar(radius: 30, backgroundImage: AssetImage(kDriver.avatar)),
                      const Positioned(right: -2, bottom: -2, child: CircleAvatar(radius: 10, backgroundColor: AppColors.green,
                          child: Icon(Icons.check, size: 12, color: AppColors.white))),
                    ])
                  else
                    Container(width: 56, height: 56,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF0F2FA),
                            border: Border.all(color: AppColors.primary, width: 2))),
                ]),
                // dashed line + moving car (only while searching)
                if (!found)
                  const Positioned.fill(child: CustomPaint(painter: _DashPainter())),
                if (!found)
                  AnimatedBuilder(
                    animation: _car,
                    builder: (context, _) => Align(
                      alignment: Alignment(-0.55 + 1.1 * _car.value, 0),
                      child: Transform.rotate(angle: 1.5708,
                          child: const Icon(Icons.local_taxi, size: 20, color: AppColors.primary)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(found ? kDriver.name : 'Finding your next driver',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0A0F2C))),
          const SizedBox(height: 6),
          if (found) ...[
            Text('${kDriver.car} · ABC 123 XY', style: const TextStyle(fontSize: 13, color: Color(0xFF8A90A8))),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, size: 14, color: Color(0xFFF5C518)),
              const SizedBox(width: 4),
              Text('${kDriver.rating} · ${kDriver.trips} trips', style: const TextStyle(fontSize: 12, color: Color(0xFF8A90A8))),
            ]),
          ] else
            const Text('The previous driver didn’t respond in time. We’re connecting you to the next closest available driver — your offer and price range stay the same.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF808080), height: 1.4)),
          const SizedBox(height: 20),
          const ClipRRect(borderRadius: BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(minHeight: 4, backgroundColor: Color(0xFFECECEC), color: AppColors.primary)),
        ]),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final paint = Paint()
      ..color = const Color(0xFFBFC5D6)
      ..strokeWidth = 1.5;
    const dash = 5.0, gap = 4.0;
    double x = size.width * 0.30;
    final end = size.width * 0.70;
    while (x < end) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, end), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) => false;
}

/// Frame 648 — "Drivers are in high demand" (auto-dismisses or Keep searching).
class _HighDemandSheet extends StatefulWidget {
  const _HighDemandSheet();
  @override
  State<_HighDemandSheet> createState() => _HighDemandSheetState();
}

class _HighDemandSheetState extends State<_HighDemandSheet> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 3200), () { if (mounted) Navigator.of(context).pop(); });
  }
  @override
  void dispose() { _t?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 68, height: 5, decoration: BoxDecoration(color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18)))),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: InkWell(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close, size: 22, color: _ink))),
        // illustration: phone + no-car
        Container(
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.phone_iphone, size: 44, color: AppColors.primary),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4)]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 28, height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.red, width: 2)),
                    child: const Icon(Icons.no_transfer, size: 16, color: AppColors.red)),
                const SizedBox(width: 8),
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 60, height: 6, color: const Color(0xFFE0E3EC)),
                  const SizedBox(height: 5),
                  Container(width: 40, height: 6, decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(3))),
                ]),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Drivers are in high demand', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 6),
        const Text('Give it a minute and try again, more are heading your way.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _sub, height: 1.4)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 51, child: Material(color: AppColors.primary, borderRadius: BorderRadius.circular(30),
            child: InkWell(borderRadius: BorderRadius.circular(30), onTap: () => Navigator.of(context).pop(),
                child: const Center(child: Text('Keep searching', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)))))),
      ]),
    );
  }
}

/// Frame 563 — "Driver didn't respond" (auto-dismisses).
class _DriverDidntRespondSheet extends StatefulWidget {
  const _DriverDidntRespondSheet();
  @override
  State<_DriverDidntRespondSheet> createState() => _DriverDidntRespondSheetState();
}

class _DriverDidntRespondSheetState extends State<_DriverDidntRespondSheet> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 2400), () { if (mounted) Navigator.of(context).pop(); });
  }
  @override
  void dispose() { _t?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 68, height: 5, decoration: BoxDecoration(color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18)))),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: InkWell(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close, size: 22, color: _ink))),
        Container(width: 56, height: 56,
            decoration: const BoxDecoration(color: Color(0x1AF59E0B), shape: BoxShape.circle),
            child: const Icon(Icons.schedule, size: 28, color: Color(0xFFF59E0B))),
        const SizedBox(height: 16),
        const Text('Driver didn’t respond', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 6),
        const Text('The driver took too long to reply. We’re automatically finding you the next closest driver',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _sub, height: 1.4)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CircleAvatar(radius: 4, backgroundColor: i == 2 ? AppColors.primary : const Color(0xFFCBD0DC))))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 51, child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Text('Cancel search', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)))),
      ]),
    );
  }
}
