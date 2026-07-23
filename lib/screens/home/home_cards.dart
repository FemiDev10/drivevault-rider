import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/mock/rider_profile.dart';
import '../../services/mock/safety_repository.dart';
import '../account/verify_identity_screen.dart';
import '../payment/offers_screen.dart';

const _ink = Color(0xFF0A0F2C);
const _muted = Color(0xFF808080);

/// Staggered entrance — each section fades and lifts into place on first paint.
class FadeInUp extends StatefulWidget {
  const FadeInUp({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (_, child) => Opacity(
          opacity: _a.value,
          child: Transform.translate(offset: Offset(0, 16 * (1 - _a.value)), child: child),
        ),
        child: widget.child,
      );
}

/// ---------------------------------------------------------------------------
/// Promo carousel — auto-advancing, swipeable, tappable.
/// ---------------------------------------------------------------------------

class _Promo {
  const _Promo(this.title, this.sub, this.icon, this.a, this.b);
  final String title, sub;
  final IconData icon;
  final Color a, b;
}

const _promos = [
  _Promo('10% off your next ride', 'Limited time · Expires tonight', Icons.card_giftcard,
      Color(0xFF1A2A80), Color(0xFF3A4FC4)),
  _Promo('Refer a friend, get ₦1,500', 'Both of you earn · Unlimited', Icons.group_add,
      Color(0xFF0C6B4F), Color(0xFF17A06F)),
  _Promo('Weekend fare cap', 'Never pay above ₦5,000 Sat–Sun', Icons.bolt,
      Color(0xFF7A2E8E), Color(0xFFB44BC8)),
];

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});
  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _pc = PageController();
  Timer? _auto;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pc.hasClients) return;
      _pc.animateToPage((_page + 1) % _promos.length,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 86,
        child: PageView.builder(
          controller: _pc,
          itemCount: _promos.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(right: 2),
            child: _card(_promos[i]),
          ),
        ),
      ),
      const SizedBox(height: 8),
      // dots
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_promos.length, (i) {
          final on = i == _page;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: on ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: on ? AppColors.primary : const Color(0xFFD5D8E4),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    ]);
  }

  Widget _card(_Promo p) => GestureDetector(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const OffersScreen())),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [p.a, p.b], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            // playful pattern
            Positioned(right: -30, top: -34, child: _blob(104, 0.10)),
            Positioned(right: 34, bottom: -30, child: _blob(72, 0.07)),
            Positioned(right: 96, top: 16, child: _blob(26, 0.09)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(p.icon, size: 22, color: AppColors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white)),
                      const SizedBox(height: 3),
                      Text(p.sub,
                          style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 18, color: AppColors.white),
              ]),
            ),
          ]),
        ),
      );

  Widget _blob(double size, double alpha) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: alpha), shape: BoxShape.circle),
      );
}

/// ---------------------------------------------------------------------------
/// Verify account — reflects real profile state and breathes until acted on.
/// ---------------------------------------------------------------------------

class VerifyCard extends StatefulWidget {
  const VerifyCard({super.key});
  @override
  State<VerifyCard> createState() => _VerifyCardState();
}

class _VerifyCardState extends State<VerifyCard> with SingleTickerProviderStateMixin {
  final _p = RiderProfile.instance;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void initState() {
    super.initState();
    _p.addListener(_r);
  }

  void _r() => setState(() {});

  @override
  void dispose() {
    _p.removeListener(_r);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _p.idStatus;
    final verified = s == IdStatus.verified;
    final inReview = s == IdStatus.inReview;

    final title = verified
        ? 'Account verified'
        : inReview
            ? 'Verification in review'
            : 'Verify account';
    final sub = verified
        ? 'Priority support & weekly discounts unlocked'
        : inReview
            ? 'Usually takes a few minutes'
            : 'Unlock mega promos & weekly discounts';
    final accent = verified
        ? AppColors.green
        : inReview
            ? AppColors.primary
            : const Color(0xFFB25E02);

    return GestureDetector(
      onTap: verified
          ? null
          : () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const VerifyIdentityScreen())),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          // gentle breathing halo only while action is still needed
          final pulse = (!verified && !inReview)
              ? 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi)
              : 0.0;
          return Container(
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.25 + 0.25 * pulse)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.06 + 0.08 * pulse),
                  blurRadius: 12 + 6 * pulse,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                    verified
                        ? Icons.verified
                        : inReview
                            ? Icons.hourglass_top
                            : Icons.verified_user_outlined,
                    size: 22,
                    color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                    const SizedBox(height: 3),
                    Text(sub, style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
              if (!verified) const Icon(Icons.chevron_right, size: 18, color: _muted),
            ]),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// DriveVault Rewards — counts up, fills in, and reacts to taps.
/// ---------------------------------------------------------------------------

class RewardsCard extends StatefulWidget {
  const RewardsCard({super.key});
  @override
  State<RewardsCard> createState() => _RewardsCardState();
}

class _RewardsCardState extends State<RewardsCard> with SingleTickerProviderStateMixin {
  static const _points = 120;
  static const _goal = 200;
  static const _ridesDone = 3;
  static const _ridesGoal = 5;

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 250), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const OffersScreen())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF16226B), Color(0xFF2A3A9E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned(right: -40, top: -50, child: _blob(140, 0.07)),
          Positioned(right: 40, bottom: -46, child: _blob(96, 0.05)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('DRIVEVAULT REWARDS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Color(0xB3FFFFFF))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Silver',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white)),
                ),
              ]),
              const SizedBox(height: 10),
              // animated point counter
              AnimatedBuilder(
                animation: _a,
                builder: (_, __) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${(_points * _a.value).round()}',
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          height: 1)),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text('pts',
                        style: TextStyle(fontSize: 12, color: Color(0xB3FFFFFF))),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              // weekly challenge
              Container(
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(children: [
                    const Expanded(
                      child: Text('Ride 5 times this week',
                          style: TextStyle(fontSize: 12, color: Color(0xE6FFFFFF))),
                    ),
                    Text('$_ridesDone/$_ridesGoal',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
                  ]),
                  const SizedBox(height: 10),
                  // ride pips fill in one by one
                  AnimatedBuilder(
                    animation: _a,
                    builder: (_, __) => Row(
                      children: List.generate(_ridesGoal, (i) {
                        final filled = _a.value * _ridesDone > i;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: i == _ridesGoal - 1 ? 0 : 6),
                            height: 7,
                            decoration: BoxDecoration(
                              color: filled
                                  ? AppColors.white
                                  : Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              // progress to next reward
              AnimatedBuilder(
                animation: _a,
                builder: (_, __) {
                  final pct = (_points / _goal) * _a.value;
                  return Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF7DE2B8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.emoji_events_outlined,
                          size: 13, color: Color(0xB3FFFFFF)),
                      const SizedBox(width: 6),
                      Text('${_goal - _points} pts to your next free ride',
                          style: const TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
                      const Spacer(),
                      const Text('View all',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white)),
                    ]),
                  ]);
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _blob(double size, double alpha) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: alpha), shape: BoxShape.circle),
      );
}

/// ---------------------------------------------------------------------------
/// Saved places — Home / Work / custom shortcuts under the search bar.
/// ---------------------------------------------------------------------------

class SavedPlacesRow extends StatefulWidget {
  const SavedPlacesRow({super.key, required this.onPick, required this.onAdd});
  final void Function(SavedPlace) onPick;
  final VoidCallback onAdd;

  @override
  State<SavedPlacesRow> createState() => _SavedPlacesRowState();
}

class _SavedPlacesRowState extends State<SavedPlacesRow> {
  final _s = SafetyStore.instance;

  @override
  void initState() {
    super.initState();
    _s.addListener(_r);
  }

  void _r() => setState(() {});

  @override
  void dispose() {
    _s.removeListener(_r);
    super.dispose();
  }

  IconData _icon(String key) => switch (key) {
        'home' => Icons.home_outlined,
        'work' => Icons.work_outline,
        _ => Icons.place_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          for (final p in _s.places) ...[
            _chip(
              icon: _icon(p.icon),
              label: p.label,
              onTap: () => widget.onPick(p),
              onLongPress: () => _confirmRemove(p),
            ),
            const SizedBox(width: 8),
          ],
          _chip(icon: Icons.add, label: 'Add shortcut', dashed: true, onTap: widget.onAdd),
        ],
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool dashed = false,
  }) =>
      Material(
        color: dashed ? Colors.transparent : const Color(0xFFF4F5F9),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: dashed ? Border.all(color: const Color(0xFFD5D8E4)) : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: dashed ? _muted : AppColors.primary),
              const SizedBox(width: 7),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: dashed ? _muted : _ink)),
            ]),
          ),
        ),
      );

  void _confirmRemove(SavedPlace p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove ${p.label}?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
        content: Text(p.address, style: const TextStyle(fontSize: 14, color: _muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary))),
          TextButton(
              onPressed: () {
                _s.removePlace(p);
                Navigator.pop(ctx);
              },
              child: const Text('Remove',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.red))),
        ],
      ),
    );
  }
}
