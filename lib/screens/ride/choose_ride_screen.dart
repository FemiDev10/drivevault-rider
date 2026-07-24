import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/live_map.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';
import '../../services/mock/rewards_repository.dart';
import '../payment/payment_screen.dart';
import '../payment/offers_screen.dart';
import 'confirm_pickup_screen.dart';

const _ink = Color(0xFF0A0F2C);
const _muted = Color(0xFF8A90A8);
const _priceGrey = Color(0xFF9D9EB1);
const _sheetGrey = Color(0xFF4D4D4D);

class ChooseRideScreen extends StatefulWidget {
  const ChooseRideScreen({super.key, required this.pickup, required this.destination});
  final Place pickup;
  final Place destination;

  @override
  State<ChooseRideScreen> createState() => _ChooseRideScreenState();
}

class _ChooseRideScreenState extends State<ChooseRideScreen> {
  PriceMode _mode = PriceMode.negotiate;
  String _selected = 'dvgo';

  late final List<RideQuote> _quotes =
      PricingService.instance.quotes(widget.destination.distanceKm);

  RideQuote get _selectedQuote => _quotes.firstWhere((q) => q.tier.id == _selected);

  void _continue() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConfirmPickupScreen(
        pickup: widget.pickup,
        destination: widget.destination,
        quote: _selectedQuote,
        mode: _mode,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final arrival = PricingService.instance.arrivalTime(widget.destination.distanceKm);
    final main = _quotes.where((q) => !q.tier.isMore).toList();
    final more = _quotes.where((q) => q.tier.isMore).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Live map with route + moving cars
          const Positioned(
            top: 0, left: 0, right: 0, height: 360,
            child: LiveMap(showRoute: true),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: StatusBar()),

          // Top route pill
          Positioned(
            top: 64, left: 21, right: 21,
            child: _RoutePill(pickup: widget.pickup, destination: widget.destination,
                onClose: () => Navigator.of(context).popUntil((r) => r.isFirst)),
          ),

          // Sheet
          Positioned(
            top: 300, left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, -2))],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(width: 68, height: 6,
                      decoration: BoxDecoration(color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18))),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Choose a ride',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
                        const SizedBox(height: 16),
                        _ModeTabs(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      children: [
                        for (final q in main)
                          _RideCard(
                            quote: q, mode: _mode, arrival: arrival,
                            selected: q.tier.id == _selected,
                            onTap: () => setState(() => _selected = q.tier.id),
                          ),
                        const SizedBox(height: 4),
                        const Text('More',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
                        const SizedBox(height: 12),
                        for (final q in more)
                          _RideCard(
                            quote: q, mode: _mode, arrival: arrival,
                            selected: q.tier.id == _selected,
                            onTap: () => setState(() => _selected = q.tier.id),
                          ),
                      ],
                    ),
                  ),
                  _BottomBar(
                    mode: _mode,
                    tierName: _selectedQuote.tier.name,
                    onContinue: _continue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePill extends StatelessWidget {
  const _RoutePill({required this.pickup, required this.destination, required this.onClose});
  final Place pickup;
  final Place destination;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
      child: Row(
        children: [
          // back
          InkWell(
            onTap: onClose,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 36, height: 36,
              child: Icon(Icons.arrow_back, size: 20, color: _ink),
            ),
          ),
          // origin → destination, stacked so it reads like a route
          Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trip_origin, size: 11, color: AppColors.primary),
                    Container(width: 1.5, height: 8, color: const Color(0xFFDDE1EC)),
                    const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pickup.name.isEmpty ? 'Current location' : pickup.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                      const SizedBox(height: 2),
                      Text(destination.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // add stop
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: Color(0xFFF0F2FA), shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});
  final PriceMode mode;
  final ValueChanged<PriceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tab('Negotiate Price', PriceMode.negotiate),
          _tab('Instant Booking', PriceMode.instant),
        ],
      ),
    );
  }

  Widget _tab(String label, PriceMode m) {
    final active = mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(m),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: active ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 1.5, offset: Offset(0, 1))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? AppColors.primary : _muted)),
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({
    required this.quote,
    required this.mode,
    required this.arrival,
    required this.selected,
    required this.onTap,
  });
  final RideQuote quote;
  final PriceMode mode;
  final String arrival;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = quote.tier;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 70, height: 42, child: Image.asset(t.asset, fit: BoxFit.contain)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(t.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black)),
                          const SizedBox(width: 4),
                          const Icon(Icons.person_outline, size: 12, color: AppColors.black),
                          Text('${t.seats}', style: const TextStyle(fontSize: 12, color: AppColors.black)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('in ${t.etaMin} min', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _sheetGrey)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: CircleAvatar(radius: 1, backgroundColor: _sheetGrey),
                          ),
                          Text(arrival, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _sheetGrey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(t.blurb, style: const TextStyle(fontSize: 12, color: AppColors.subTextGrey)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      mode == PriceMode.negotiate
                          ? '${naira(quote.negLow)} - ${naira(quote.negHigh)}'
                          : naira(quote.instant),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.black),
                    ),
                    const SizedBox(height: 4),
                    if (mode == PriceMode.negotiate)
                      const Text('Price range', style: TextStyle(fontSize: 12, color: _priceGrey)),
                    if (selected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0x1A00853F), borderRadius: BorderRadius.circular(30)),
                        child: Text('Save ${naira(quote.savings)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.green)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEDEDED)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Typical price on other apps', style: TextStyle(fontSize: 12, color: _sheetGrey)),
                  const SizedBox(height: 2),
                  Text('${naira(quote.rivalLow)} - ${naira(quote.rivalHigh)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _sheetGrey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.mode, required this.tierName, required this.onContinue});
  final PriceMode mode;
  final String tierName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final brand = tierName.startsWith('Dv') ? tierName : 'Dv$tierName';
    final label = mode == PriceMode.negotiate ? 'Continue with  $brand' : 'Book  $brand';
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 4)],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Applied promo indicator
          ListenableBuilder(
            listenable: OffersStore.instance,
            builder: (context, _) {
              final store = OffersStore.instance;
              if (!store.hasApplied) return const SizedBox.shrink();
              final o = store.primary!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_outlined, size: 18, color: AppColors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${o.code} applied · saving ${naira(o.savings)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.green)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OffersScreen()),
                      ),
                      child: const Text('Change', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ],
                ),
              );
            },
          ),
          // Payment method row -> Payment screen
          ListenableBuilder(
            listenable: PaymentStore.instance,
            builder: (context, _) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaymentScreen()),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.green),
                        const SizedBox(width: 6),
                        Text(PaymentStore.instance.selectedLabel,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
                      ],
                    ),
                    const Icon(Icons.chevron_right, size: 22, color: _ink),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 51,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: onContinue,
                borderRadius: BorderRadius.circular(30),
                child: Center(
                  child: Text(label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
                ),
              ),
            ),
          ),
          if (mode == PriceMode.negotiate) ...[
            const SizedBox(height: 12),
            const Text('Set your offer on the next screen',
                style: TextStyle(fontSize: 12, color: _muted)),
          ],
        ],
      ),
    );
  }
}
