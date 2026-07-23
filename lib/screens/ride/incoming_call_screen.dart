import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/mock/driver.dart';
import 'message_call_screens.dart';

/// Incoming in-app call from the driver.
///
/// Uses the DriveVault navy surface rather than the usual telecom green so the
/// call reads as an in-app DriveVault call (masked number), not a phone call.
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  /// Present the ringing screen over whatever is on screen.
  static Future<void> ring(BuildContext context) {
    return Navigator.of(context).push(PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const IncomingCallScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ));
  }

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _giveUp;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    // an unanswered call stops ringing on its own
    _giveUp = Timer(const Duration(seconds: 25), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _giveUp?.cancel();
    super.dispose();
  }

  void _accept() {
    _giveUp?.cancel();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CallDriverScreen()));
  }

  void _decline() {
    _giveUp?.cancel();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF22348F), Color(0xFF141F63)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // close (minimise) — the ride screen stays underneath
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 8),
                  child: InkWell(
                    onTap: _decline,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 20, color: AppColors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // pulsing avatar
              SizedBox(
                width: 200, height: 200,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => CustomPaint(
                    painter: _RingPainter(_pulse.value),
                    child: Center(child: child),
                  ),
                  child: Container(
                    width: 104, height: 104,
                    decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(kDriver.initials,
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(kDriver.name,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.white)),
              const SizedBox(height: 8),
              const Text('Incoming call · your driver',
                  style: TextStyle(fontSize: 14, color: Color(0xCCFFFFFF))),
              const SizedBox(height: 6),
              Text('${kDriver.car} · ${kDriver.plate}',
                  style: const TextStyle(fontSize: 13, color: Color(0x99FFFFFF))),
              const SizedBox(height: 18),
              // trust cue — riders should know the number is masked
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.lock_outline, size: 13, color: AppColors.white),
                  SizedBox(width: 6),
                  Text('Your number stays private',
                      style: TextStyle(fontSize: 12, color: AppColors.white)),
                ]),
              ),
              const Spacer(),
              // decline / accept
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CallAction(
                        color: AppColors.red,
                        icon: Icons.call_end,
                        label: 'Decline',
                        onTap: _decline),
                    _CallAction(
                        color: AppColors.green,
                        icon: Icons.call,
                        label: 'Accept',
                        onTap: _accept),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({required this.color, required this.icon, required this.label, required this.onTap});
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 72, height: 72, child: Icon(icon, size: 30, color: AppColors.white)),
        ),
      ),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(fontSize: 14, color: AppColors.white)),
    ]);
  }
}

/// Two expanding rings that fade out — the "ringing" cue.
class _RingPainter extends CustomPainter {
  _RingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 2; i++) {
      final p = (t + i * 0.5) % 1.0;
      final radius = 52 + p * 48;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: (1 - p) * 0.35);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}
