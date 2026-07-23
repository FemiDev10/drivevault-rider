import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The DriveVault designs are drawn for an iPhone 14/15 Pro canvas of
/// 393 x 852 logical pixels. To make the web build read as a real phone
/// (and to keep every screen pixel-matched to Figma), we render the whole
/// app inside a fixed 393 x 852 "device" that is centred on a neutral
/// backdrop and scaled down to fit smaller windows.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  static const double designWidth = 393;
  static const double designHeight = 852;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.deviceBackdrop,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Fit the 393x852 device into the available space, but never
            // upscale beyond 1:1 so the design stays crisp.
            final scale = (constraints.maxHeight / designHeight)
                .clamp(0.0, 1.0)
                .toDouble();
            final fitScale = (constraints.maxWidth / designWidth)
                .clamp(0.0, 1.0)
                .toDouble();
            final s = scale < fitScale ? scale : fitScale;

            return SizedBox(
              width: designWidth * s,
              height: designHeight * s,
              child: FittedBox(
                fit: BoxFit.contain,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: designWidth,
                    height: designHeight,
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
