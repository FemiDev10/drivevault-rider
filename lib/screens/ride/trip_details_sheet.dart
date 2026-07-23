import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);

/// Frame 354 — Trip details bottom sheet (opened by the "…" on ride details).
class TripDetailsSheet extends StatelessWidget {
  const TripDetailsSheet({super.key, required this.pickup, required this.destination, required this.fare, required this.onCancel});
  final Place pickup;
  final Place destination;
  final int fare;
  final VoidCallback onCancel;

  static Future<void> show(BuildContext context,
      {required Place pickup, required Place destination, required int fare, required VoidCallback onCancel}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TripDetailsSheet(pickup: pickup, destination: destination, fare: fare, onCancel: onCancel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 68, height: 5,
              decoration: BoxDecoration(color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18)))),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Trip details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
              const Spacer(),
              InkWell(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.close, size: 22, color: _ink)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEDEDED), height: 1),
          const SizedBox(height: 16),
          // route
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.radio_button_checked, size: 16, color: AppColors.primary),
                  Container(width: 1.5, height: 22, color: const Color(0xFFCBD0DC)),
                  const Icon(Icons.square_rounded, size: 12, color: AppColors.primary),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pickup.subtitle.isNotEmpty ? pickup.subtitle : pickup.name,
                        style: const TextStyle(fontSize: 14, color: _ink)),
                    const SizedBox(height: 18),
                    Text(destination.subtitle.isNotEmpty ? destination.subtitle : destination.name,
                        style: const TextStyle(fontSize: 14, color: _ink)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEDEDED), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.ios_share, size: 20, color: _ink),
              const SizedBox(width: 10),
              const Expanded(child: Text('Share trip status', style: TextStyle(fontSize: 14, color: _ink))),
              InkWell(
                onTap: () => _showShareSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF0F2FA), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Share', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEDEDED), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.green),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${naira(fare)}.00', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                  const Text('Bank Transfer', style: TextStyle(fontSize: 12, color: _sub)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEDEDED), height: 1),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 51,
            child: Material(
              color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).maybePop();
                  _showCancelRide(context, onCancel);
                },
                borderRadius: BorderRadius.circular(30),
                child: const Center(child: Text('Cancel trip',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red))),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 51,
            child: Material(
              color: AppColors.primary, borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(30),
                child: const Center(child: Text('Close',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Share trip (4116:22167) ----
void _showShareSheet(BuildContext context) {
  showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (ctx) => _ShareSheet(),
  );
}

class _ShareSheet extends StatefulWidget {
  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _copied = false;
  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Share trip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
            const Spacer(),
            InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, size: 22, color: _ink)),
          ]),
          const SizedBox(height: 6),
          const Text('Share your trip so others can follow your journey in real time.', style: TextStyle(fontSize: 13, color: _sub)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE6E8F0))),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const Expanded(child: Text('https://kfmapgoogle/247', style: TextStyle(fontSize: 14, color: _ink))),
              InkWell(onTap: () => setState(() => _copied = true), child: const Icon(Icons.copy, size: 18, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 51, child: Material(color: AppColors.primary, borderRadius: BorderRadius.circular(30),
              child: InkWell(borderRadius: BorderRadius.circular(30), onTap: () => Navigator.pop(context),
                  child: const Center(child: Text('Share', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)))))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 44,
              child: TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)))),
        ]),
      ),
      if (_copied)
        Positioned(top: -70, left: 0, right: 0, child: Container(
          height: 49, margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: const Text('Link copied!', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)))),
    ]);
  }
}

// ---- Cancel ride (4116:22167) ----
void _showCancelRide(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(alignment: Alignment.centerRight, child: InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, size: 20, color: _sub))),
          const Text('Cancel this ride?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 6),
          const Text('Are you sure you want to cancel? The driver is already on their way.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _sub)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 51, child: Material(color: AppColors.primary, borderRadius: BorderRadius.circular(30),
              child: InkWell(borderRadius: BorderRadius.circular(30), onTap: () => Navigator.pop(ctx),
                  child: const Center(child: Text('Keep my ride', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)))))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 44,
              child: TextButton(onPressed: () { Navigator.pop(ctx); _showCancelReasons(context, onConfirm); },
                  child: const Text('Cancel ride', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red)))),
        ]),
      ),
    ),
  );
}

void _showCancelReasons(BuildContext context, VoidCallback onConfirm) {
  const reasons = [
    [Icons.wrong_location_outlined, 'Selected wrong dropoff'],
    [Icons.timer_outlined, 'Wait time was too long'],
    [Icons.error_outline, 'Requested by accident'],
    [Icons.person_outline, 'Driver asked to cancel'],
    [Icons.location_on_outlined, 'Selected wrong pickup'],
    [Icons.apps, 'Other'],
  ];
  showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.arrow_back_ios_new, size: 18, color: _ink)),
          const Expanded(child: Center(child: Text('Cancel ride?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)))),
          InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, size: 20, color: _ink)),
        ]),
        const SizedBox(height: 16),
        const Text('What went wrong?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 8),
        for (final r in reasons)
          InkWell(
            onTap: () { Navigator.pop(ctx); onConfirm(); },
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(children: [
                  Icon(r[0] as IconData, size: 20, color: AppColors.primary),
                  const SizedBox(width: 14),
                  Text(r[1] as String, style: const TextStyle(fontSize: 14, color: _ink)),
                ])),
          ),
      ]),
    ),
  );
}
