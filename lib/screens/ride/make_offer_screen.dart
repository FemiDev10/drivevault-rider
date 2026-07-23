import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/live_map.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';
import '../../services/mock/driver.dart';
import 'ride_progress_screen.dart';

const _ink = Color(0xFF0A0F2C);
const _muted = Color(0xFF8A90A8);
const _sub = Color(0xFF808080);

class MakeOfferScreen extends StatefulWidget {
  const MakeOfferScreen({super.key, required this.pickup, required this.destination, required this.quote});
  final Place pickup;
  final Place destination;
  final RideQuote quote;

  @override
  State<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends State<MakeOfferScreen> {
  late int _offer;
  bool _autoAccept = false;

  @override
  void initState() {
    super.initState();
    _offer = widget.quote.instant.clamp(widget.quote.negLow, widget.quote.negHigh);
  }

  void _bump(int d) => setState(() => _offer = (_offer + d).clamp(widget.quote.negLow, widget.quote.negHigh));

  void _send() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RideProgressScreen(
        pickup: widget.pickup,
        destination: widget.destination,
        quote: widget.quote,
        mode: PriceMode.negotiate,
        offer: _offer,
        autoAccept: _autoAccept,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, height: 420,
              child: LiveMap(showCentrePin: true, centrePinLabel: 'Pick up on $kPickupStreet', filledLabel: true)),
          const Positioned(top: 0, left: 0, right: 0, child: StatusBar()),
          Positioned(top: 64, left: 24, child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back, size: 24, color: _ink))),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, -2))],
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 68, height: 5,
                      decoration: BoxDecoration(color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18)))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Make your offer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _ink)),
                      InkWell(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.close, size: 22, color: _ink)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tier card
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.stroke)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(width: 56, height: 34, child: Image.asset(q.tier.asset, fit: BoxFit.contain)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('Dv${q.tier.name.replaceFirst('Dv', '')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black)),
                                const SizedBox(width: 4),
                                const Icon(Icons.person_outline, size: 12, color: AppColors.black),
                                Text('${q.tier.seats}', style: const TextStyle(fontSize: 12, color: AppColors.black)),
                              ]),
                              const SizedBox(height: 2),
                              Text('${q.tier.blurb} ·', style: const TextStyle(fontSize: 12, color: _sub)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0x1A00853F), borderRadius: BorderRadius.circular(30)),
                          child: Text('Save ${naira(q.savings)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.green)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stepper
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF0F2FA), borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        _StepBtn(icon: Icons.remove, onTap: () => _bump(-100)),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(naira(_offer), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.edit_outlined, size: 16, color: _muted),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('Recommended fare: ${naira(q.instant)}', style: const TextStyle(fontSize: 12, color: _muted)),
                            ],
                          ),
                        ),
                        _StepBtn(icon: Icons.add, onTap: () => _bump(100)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Min ${naira(q.negLow)}', style: const TextStyle(fontSize: 12, color: _muted)),
                      Text('Max ${naira(q.negHigh)}', style: const TextStyle(fontSize: 12, color: _muted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text('Auto-accept offer of ${naira(_offer)}', style: const TextStyle(fontSize: 14, color: AppColors.black))),
                      Switch(
                        value: _autoAccept,
                        activeColor: AppColors.white,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) => setState(() => _autoAccept = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 51,
                    child: Material(
                      color: AppColors.primary, borderRadius: BorderRadius.circular(30),
                      child: InkWell(
                        onTap: _send, borderRadius: BorderRadius.circular(30),
                        child: const Center(child: Text('Send offer to drivers',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white))),
                      ),
                    ),
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

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary, shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap, customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20, color: AppColors.white)),
      ),
    );
  }
}
