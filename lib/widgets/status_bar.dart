import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// iOS-style status bar (9:41 · dynamic island · signal/wifi/battery) to match
/// the Figma frames. [dark] = true renders black glyphs (light screens),
/// false renders white glyphs (photo/onboarding screens).
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, this.dark = true});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? AppColors.black : AppColors.white;
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Time
          Positioned(
            left: 0,
            top: 20,
            width: 108,
            child: Text(
              '9:41',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
          ),
          // Dynamic island
          Positioned(
            top: 12,
            child: Container(
              width: 122,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          // Right side cluster
          Positioned(
            right: 27,
            top: 22,
            child: Row(
              children: [
                _SignalBars(color: color),
                const SizedBox(width: 7),
                Icon(Icons.wifi, size: 17, color: color),
                const SizedBox(width: 6),
                _Battery(color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        return Container(
          width: 3,
          height: 4.0 + i * 3,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

class _Battery extends StatelessWidget {
  const _Battery({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 25,
          height: 13,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(3.5),
          ),
          padding: const EdgeInsets.all(1.5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.85,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 1),
        Container(
          width: 1.4,
          height: 4.2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
