import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../ride/route_search_screen.dart';
import '../ride/my_rides_screen.dart';
import '../account/account_screen.dart';
import 'home_cards.dart';
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
                          FadeInUp(delayMs: 0, child: _greetingRow()),
                          const SizedBox(height: 16),
                          FadeInUp(delayMs: 60, child: _searchBar(context)),
                          const SizedBox(height: 16),
                          FadeInUp(
                              delayMs: 120,
                              child: _sectionHeader('Promos & Rewards', trailingViewAll: true)),
                          const SizedBox(height: 12),
                          const FadeInUp(delayMs: 180, child: PromoCarousel()),
                          const SizedBox(height: 10),
                          const FadeInUp(delayMs: 240, child: VerifyCard()),
                          const SizedBox(height: 20),
                          FadeInUp(delayMs: 300, child: _sectionHeader('Your rewards')),
                          const SizedBox(height: 12),
                          const FadeInUp(delayMs: 360, child: RewardsCard()),
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
          _navItem(Icons.person_outline, 'Account',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen()))),
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
