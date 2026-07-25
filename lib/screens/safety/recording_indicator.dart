import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/mock/recorder_controller.dart';
import 'ride_recorder_screen.dart';

/// App-wide "still recording" banner. Rendered above every screen so a rider
/// who records and keeps using the app (or their phone) can never forget it's
/// running — and can stop it in one tap from anywhere.
class RecordingIndicator extends StatelessWidget {
  const RecordingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final rec = RecorderController.instance;
    return AnimatedBuilder(
      animation: rec,
      builder: (context, _) {
        if (!rec.isRecording) return const SizedBox.shrink();
        return Positioned(
          top: 8,
          left: 12,
          right: 12,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
                ),
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: Row(children: [
                  const _BlinkingDot(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rec.nearCap
                          ? 'Recording ${rec.elapsedLabel} · stopping soon'
                          : 'Recording ${rec.elapsedLabel} · tap to view',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white),
                    ),
                  ),
                  // Open the recorder screen
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RideRecorderScreen())),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(Icons.chevron_right, size: 20, color: AppColors.white),
                    ),
                  ),
                  // One-tap stop from anywhere
                  InkWell(
                    onTap: rec.stop,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Stop',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
        child: Container(
          width: 10, height: 10,
          decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
        ),
      );
}
