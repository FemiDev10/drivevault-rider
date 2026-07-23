import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/driver.dart';

/// Terminal outcome screens for a ride that never completed.
/// Ride cancelled = 1359:17530, Missed driver = 1362:17801.

/// Shared centred outcome layout: icon, title, body, rule, primary + secondary action.
class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondary,
    this.width = 300,
    this.badge,
    this.footer,
    this.centered = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Widget secondary;
  final double width;
  final IconData? badge;
  final Widget? footer;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // icon (with optional corner badge)
          Center(
            child: SizedBox(
              width: badge == null ? 64 : 84,
              height: badge == null ? 64 : 82,
              child: Stack(
                children: [
                  Container(
                    width: badge == null ? 64 : 72,
                    height: badge == null ? 64 : 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: iconColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: badge == null ? 30 : 40, color: iconColor),
                  ),
                  if (badge != null)
                    Positioned(
                      left: 48, top: 48,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.red, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Icon(badge, size: 16, color: AppColors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0A0F2C))),
          const SizedBox(height: 17),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.4)),
          const SizedBox(height: 32),
          Container(height: 1, color: AppColors.stroke),
          const SizedBox(height: 25),
          // primary
          SizedBox(
            height: 50,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.2),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: onPrimary,
                child: Center(
                  child: Text(primaryLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          secondary,
          if (footer != null) ...[const SizedBox(height: 22), footer!],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const StatusBar(),
            Expanded(
              child: centered
                  ? Center(child: SingleChildScrollView(child: Center(child: content)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 72),
                      child: Center(child: content)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plain text button used as the secondary action.
Widget _textAction(String label, VoidCallback onTap) => SizedBox(
      height: 50,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.mutedText)),
        ),
      ),
    );

/// Outlined secondary button (used where the design shows a bordered button).
Widget _outlinedAction(String label, VoidCallback onTap) => SizedBox(
      height: 50,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.stroke),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0A0F2C))),
          ),
        ),
      ),
    );

/// 1359:17530 — shown after the rider cancels.
class RideCancelledScreen extends StatelessWidget {
  const RideCancelledScreen({super.key, this.onBookAgain});
  final VoidCallback? onBookAgain;

  @override
  Widget build(BuildContext context) {
    void goHome() => Navigator.of(context).popUntil((r) => r.isFirst);
    return _Outcome(
      icon: Icons.close,
      iconColor: AppColors.mutedText,
      title: 'Ride cancelled',
      body: 'Your cancellation has been recorded. No charge has been applied.',
      primaryLabel: 'Book a new ride',
      onPrimary: () {
        goHome();
        onBookAgain?.call();
      },
      secondary: _textAction('Go home', goHome),
    );
  }
}

/// 1362:17801 — the driver waited and left before the rider showed up.
class MissedDriverScreen extends StatelessWidget {
  const MissedDriverScreen({super.key, this.onFindNewDriver, this.onChangePickup});
  final VoidCallback? onFindNewDriver;
  final VoidCallback? onChangePickup;

  @override
  Widget build(BuildContext context) {
    final first = kDriver.name.split(' ').first;
    return _Outcome(
      width: 345,
      centered: false,
      icon: Icons.directions_car_outlined,
      iconColor: AppColors.mutedText,
      badge: Icons.priority_high,
      title: 'Looks like you missed your driver',
      body: '$first waited 10 minutes at your pickup. A small no-show fee may apply to cover their time.',
      primaryLabel: 'Find a new driver',
      onPrimary: () {
        Navigator.of(context).popUntil((r) => r.isFirst);
        onFindNewDriver?.call();
      },
      secondary: _outlinedAction('Change pickup location', () {
        Navigator.of(context).popUntil((r) => r.isFirst);
        onChangePickup?.call();
      }),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Did something go wrong? ',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/support'),
            child: const Text('Contact support.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

/// 4116:22166 — the rider ended the negotiation before agreeing a fare.
/// No money moved and no driver was assigned, so the copy is reassuring
/// rather than apologetic, and the primary action restarts the search.
class NegotiationCancelledScreen extends StatelessWidget {
  const NegotiationCancelledScreen({super.key, this.noAgreement = false});

  /// True when the rounds ran out rather than the rider backing out.
  final bool noAgreement;

  @override
  Widget build(BuildContext context) {
    void goHome() => Navigator.of(context).popUntil((r) => r.isFirst);
    return _Outcome(
      icon: noAgreement ? Icons.handshake_outlined : Icons.close,
      iconColor: AppColors.mutedText,
      title: noAgreement ? 'No agreement reached' : 'Negotiation cancelled',
      body: noAgreement
          ? 'You and the driver couldn’t agree on a fare. Nothing has been charged — try again or book at the standard price.'
          : 'You ended the negotiation. No driver was assigned and nothing has been charged.',
      primaryLabel: 'Try again',
      onPrimary: goHome,
      secondary: _textAction('Go home', goHome),
    );
  }
}
