import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/rewards_repository.dart';
import '../payment/payment_screen.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);

enum PayOutcome { success, failed, declined }

/// Frames 332 / 634 / 635 — card payment result. Returns true on success.
class PaymentStatusScreen extends StatefulWidget {
  const PaymentStatusScreen({super.key, required this.outcome});
  final PayOutcome outcome;

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  bool _processing = true;
  late PayOutcome _outcome = widget.outcome;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _runProcessing();
  }

  void _runProcessing() {
    setState(() => _processing = true);
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _processing = false);
      if (_outcome == PayOutcome.success) {
        Timer(const Duration(milliseconds: 1100), () { if (mounted) Navigator.of(context).pop(true); });
      }
    });
  }

  /// Re-evaluate the payment against the currently-selected method.
  /// Mastercard = declined, anything else (Visa / Apple Pay / Bank Transfer) = success.
  void _recheck() {
    final store = PaymentStore.instance;
    var declined = false;
    if (store.selectedId.startsWith('card:')) {
      final last4 = store.selectedId.substring(5);
      final c = store.cards.where((x) => x.last4 == last4).toList();
      declined = c.isNotEmpty && c.first.brand == 'mastercard';
    }
    setState(() => _outcome = declined ? PayOutcome.declined : PayOutcome.success);
    _runProcessing();
  }

  Future<void> _tryAnotherCard() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddCardScreen()));
    if (mounted) _recheck();
  }

  Future<void> _changeMethod() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentScreen()));
    if (mounted) _recheck();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failed = _outcome != PayOutcome.success;
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // faint clouds
            const Positioned(top: 90, left: 40, child: Icon(Icons.cloud, size: 40, color: Color(0xFFE4EAFB))),
            const Positioned(top: 78, left: 150, child: Icon(Icons.cloud, size: 26, color: Color(0xFFE4EAFB))),
            const Positioned(top: 96, right: 40, child: Icon(Icons.cloud, size: 44, color: Color(0xFFE4EAFB))),
            Column(
              children: [
                const StatusBar(),
                SizedBox(
                  height: 42,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: InkWell(onTap: () => Navigator.of(context).pop(false),
                          child: const Icon(Icons.arrow_back_ios_new, size: 20, color: _ink)),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _processing
                        ? Column(mainAxisSize: MainAxisSize.min, children: const [
                            SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary)),
                            SizedBox(height: 16),
                            Text('Processing your payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                          ])
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            // glowing status icon
                            Container(
                              width: 88, height: 88,
                              decoration: BoxDecoration(shape: BoxShape.circle,
                                  color: (failed ? AppColors.red : AppColors.green).withValues(alpha: 0.10)),
                              alignment: Alignment.center,
                              child: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: failed ? AppColors.red : AppColors.green),
                                child: Icon(failed ? Icons.close : Icons.check, size: 26, color: AppColors.white),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(failed ? 'Payment failed' : 'Payment successful',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                                    color: failed ? AppColors.red : AppColors.primary)),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _outcome == PayOutcome.success
                                    ? 'Your payment has been secured.'
                                    : _outcome == PayOutcome.declined
                                        ? 'Your card was declined. Please try another card or payment method.'
                                        : 'An error occurred. Please try again',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: _sub, height: 1.4),
                              ),
                            ),
                          ]),
                  ),
                ),
                if (!_processing && failed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(children: [
                      SizedBox(width: double.infinity, height: 51, child: Material(color: AppColors.primary, borderRadius: BorderRadius.circular(30),
                          child: InkWell(borderRadius: BorderRadius.circular(30),
                              onTap: _outcome == PayOutcome.declined ? _tryAnotherCard : _recheck,
                              child: Center(child: Text(_outcome == PayOutcome.declined ? 'Try another card' : 'Try again',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)))))),
                      const SizedBox(height: 6),
                      SizedBox(width: double.infinity, height: 51,
                          child: TextButton(onPressed: _changeMethod,
                              child: const Text('Change payment method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)))),
                    ]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
