import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';
import '../../services/mock/driver.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF6A6C88);
const _rowStroke = Color(0xFFEDEEF3);
const _cardGrey = Color(0xFFF5F6FA);

/// "Here's your receipt, Femi." — a document/PDF-style receipt.
/// Navy bar carries only the logo + date; the title sits in the white body.
/// The layout is intentionally document-shaped and keeps that look on mobile.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.total, required this.pickup, required this.destination, this.card});
  final int total;
  final Place pickup;
  final Place destination;
  final String? card; // e.g. "7586" for a card receipt, null = Bank Transfer

  @override
  Widget build(BuildContext context) {
    const booking = 224, discount = 500;
    final rideFare = total - booking + discount;
    final km = destination.distanceKm;
    final mins = PricingService.instance.tripMinutes(km);
    final pickupText = pickup.subtitle.isNotEmpty ? pickup.subtitle : pickup.name;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // thin backdrop strip with a close control (outside the document)
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, size: 24, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  color: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // navy header — logo left, date right
                      Container(
                        color: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        child: Row(
                          children: [
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(9)),
                              alignment: Alignment.center,
                              child: const Icon(Icons.electric_car, size: 18, color: AppColors.white),
                            ),
                            const SizedBox(width: 8),
                            const Text('DriveVault',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.white)),
                            const Spacer(),
                            const Text('29 June 2026',
                                style: TextStyle(fontSize: 15, color: Color(0xF2FFFFFF))),
                          ],
                        ),
                      ),
                      // white document body
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 30, 28, 44),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Here’s your receipt, Femi.",
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black, height: 1.1)),
                            const SizedBox(height: 10),
                            const Text('Thanks for riding with DriveVault. Here’s a summary of your trip.',
                                style: TextStyle(fontSize: 14, color: _sub)),
                            const SizedBox(height: 6),
                            const Text('Invoice #DV-2026-0439',
                                style: TextStyle(fontSize: 13, color: _sub)),
                            const SizedBox(height: 30),
                            // Total headline
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
                                const Spacer(),
                                Text(naira(total),
                                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(height: 2, color: AppColors.primary),
                            const SizedBox(height: 26),
                            // fare breakdown
                            const Text('FARE BREAKDOWN',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8)),
                            const SizedBox(height: 12),
                            _row('Ride fare', '${naira(rideFare)}.00'),
                            _row('Booking fee', '${naira(booking)}.00'),
                            _row('Discount', '-${naira(discount)}.00', color: AppColors.green, labelColor: AppColors.green),
                            _row('Total', '${naira(total)}.00', bold: true, border: false),
                            const SizedBox(height: 26),
                            // payment
                            const Text('PAYMENT',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: 0.8)),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(color: _cardGrey, borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(7)),
                                  alignment: Alignment.center,
                                  child: const Text('₦', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(card == null ? 'Bank Transfer' : 'Card ···· $card',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                                      if (card != null)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Text('29 JUNE 2026 · 06:32PM', style: TextStyle(fontSize: 11, color: _sub)),
                                        ),
                                    ],
                                  ),
                                ),
                                Text('${naira(total)}.00',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                              ]),
                            ),
                            const SizedBox(height: 28),
                            // trip details
                            const Text('TRIP DETAILS',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: 0.8)),
                            const SizedBox(height: 16),
                            Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(kDriver.initials,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(kDriver.name.split(' ').first,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                                  Text('${kDriver.car} · ${kDriver.plate}',
                                      style: const TextStyle(fontSize: 13, color: _sub)),
                                ],
                              ),
                            ]),
                            const SizedBox(height: 18),
                            Text('Distance: ${km.toStringAsFixed(1)}KM',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                            const SizedBox(height: 8),
                            Text('Duration: $mins mins',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                            const SizedBox(height: 16),
                            // route timeline
                            _stop(top: true, addr: pickupText, time: '05:56 PM', addrFirst: true),
                            _stop(top: false, addr: destination.name, time: '06:32 PM', addrFirst: false),
                            const SizedBox(height: 34),
                            const Center(
                              child: Text('Fare does not include fees that may be charged by your bank. Contact your bank directly for enquiries.',
                                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _sub)),
                            ),
                            const SizedBox(height: 6),
                            const Center(
                              child: Text('© 2026 DriveVault. Lagos, Nigeria.',
                                  style: TextStyle(fontSize: 12, color: _sub)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false, bool border = true, Color? color, Color? labelColor}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: border ? const BoxDecoration(border: Border(bottom: BorderSide(color: _rowStroke))) : null,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: TextStyle(fontSize: 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: labelColor ?? _ink)),
          Text(v, style: TextStyle(fontSize: 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: color ?? _ink)),
        ]),
      );

  /// One route stop with a connector rail. `addrFirst` puts the address above the time.
  Widget _stop({required bool top, required String addr, required String time, required bool addrFirst}) {
    final addrWidget = Text(addr, style: const TextStyle(fontSize: 15, color: _ink));
    final timeWidget = Text(time, style: const TextStyle(fontSize: 12, color: _sub));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Icon(top ? Icons.radio_button_checked : Icons.location_on, size: 18, color: AppColors.primary),
            if (top) Expanded(child: Container(width: 2, color: const Color(0xFFDADCE6))),
          ]),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: top ? 14 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: addrFirst
                  ? [addrWidget, const SizedBox(height: 2), timeWidget]
                  : [timeWidget, const SizedBox(height: 2), addrWidget],
            ),
          ),
        ],
      ),
    );
  }
}
