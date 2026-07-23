import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../ride/route_search_screen.dart';
import '../ride/my_rides_screen.dart';
import '../menu/side_menu.dart';

/// Home — map, greeting, search, promos & rewards, bottom nav.
/// Pixel-matched to Figma. Interactions are mocked (prototype only).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _ink = Color(0xFF0A0F2C); // headings
  static const _muted = Color(0xFF8A90A8); // secondary text
  static const _fieldBg = Color(0xFFF5F6FA);
  static const _fieldBorder = Color(0xFFE8ECF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDECE8),
      body: Stack(
        children: [
          // Map background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: Image.asset('assets/images/home_map.png', fit: BoxFit.cover),
          ),

          const Positioned(top: 0, left: 0, right: 0, child: StatusBar()),

          // Menu button
          Positioned(
            top: 71,
            left: 24,
            child: GestureDetector(
              onTap: () => SideMenu.open(context),
              child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 2.4,
                    offset: const Offset(0, 4.8),
                  ),
                ],
              ),
              child: const Icon(Icons.menu, size: 20, color: _ink),
            ),
            ),
          ),

          // Bottom sheet
          Positioned(
            top: 230,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Grabber
                  Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFE3EF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _greetingRow(),
                          const SizedBox(height: 16),
                          _searchBar(context),
                          const SizedBox(height: 16),
                          _sectionHeader('Promos & Rewards', trailingViewAll: true),
                          const SizedBox(height: 12),
                          _promoCard(),
                          const SizedBox(height: 8),
                          _verifyCard(),
                          const SizedBox(height: 16),
                          _sectionHeader('Your rewards'),
                          const SizedBox(height: 12),
                          _rewardsCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom nav
          const Positioned(bottom: 0, left: 0, right: 0, child: _BottomNav()),
        ],
      ),
    );
  }

  Widget _greetingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Good morning',
                style: TextStyle(fontSize: 12, color: _muted)),
            SizedBox(height: 2),
            Text('Chidi 👋',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('CN',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white)),
        ),
      ],
    );
  }

  Widget _searchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RouteSearchScreen()),
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _fieldBorder, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 17.5),
        child: Row(
          children: const [
            Icon(Icons.search, size: 18, color: _muted),
            SizedBox(width: 12),
            Text('Where are you heading?',
                style: TextStyle(fontSize: 14, color: _muted)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {bool trailingViewAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
        if (trailingViewAll)
          Row(
            children: const [
              Text('View all',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
            ],
          ),
      ],
    );
  }

  Widget _promoCard() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -32,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.card_giftcard,
                      size: 22, color: AppColors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('10% off your next ride',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white)),
                    SizedBox(height: 2),
                    Text('Limited time · Expires tonight',
                        style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifyCard() {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _fieldBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user_outlined,
                size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Verify account',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
              SizedBox(height: 2),
              Text('Earn 50 bonus points',
                  style: TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: _muted),
        ],
      ),
    );
  }

  Widget _rewardsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stroke),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DRIVEVAULT REWARDS',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('0',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1)),
              SizedBox(width: 2),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('pts',
                    style: TextStyle(fontSize: 12, color: _muted)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: Text('Ride 5 times this week',
                          style: TextStyle(fontSize: 12, color: _muted)),
                    ),
                    Text('0/5',
                        style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Container(width: 2, height: 6, color: AppColors.primary),
                      Expanded(
                        child: Container(height: 6, color: const Color(0x26171717)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('Next reward at 200 pts · 200 pts away',
                style: TextStyle(fontSize: 10, color: _muted)),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _navItem(Icons.home_outlined, 'Home', active: true),
          const SizedBox(width: 80),
          _navItem(Icons.calendar_today_outlined, 'Trips',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyRidesScreen()))),
          const SizedBox(width: 80),
          _navItem(Icons.person_outline, 'Account'),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool active = false, VoidCallback? onTap}) {
    final color = active ? AppColors.primary : AppColors.subTextGrey;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 7),
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: color)),
      ],
    ),
    );
  }
}
