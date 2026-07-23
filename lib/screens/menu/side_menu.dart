import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../ride/my_rides_screen.dart';
import '../payment/payment_screen.dart';
import '../account/account_screen.dart';
import '../account/about_support_screens.dart';
import '../account/edit_field_screens.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);

/// Side menu (975:20978) — slides in from the left over the home screen.
class SideMenu {
  static Future<void> open(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Align(
          alignment: Alignment.centerLeft,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(curved),
            child: Material(
              elevation: 16,
              shadowColor: Colors.black38,
              child: _MenuPanel(),
            ),
          ),
        );
      },
    );
  }
}

class _MenuPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: SizedBox(
        width: 318,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AccountScreen()));
                  },
                  child: Row(children: [
                    Container(width: 44, height: 44,
                        decoration: const BoxDecoration(color: Color(0xFFF0F2FA), shape: BoxShape.circle),
                        child: const Icon(Icons.person_outline, size: 24, color: _sub)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Femi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
                        Text('My account', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 22, color: _sub),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(children: const [
                  Icon(Icons.star, size: 16, color: Color(0xFFF5C518)),
                  SizedBox(width: 8),
                  Text('5.00 Rating', style: TextStyle(fontSize: 14, color: _ink)),
                ]),
                const SizedBox(height: 8),
                Row(children: const [
                  Icon(Icons.access_time, size: 16, color: _sub),
                  SizedBox(width: 8),
                  Text('47 trips', style: TextStyle(fontSize: 14, color: _ink)),
                ]),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFEDEDED), height: 1),
                const SizedBox(height: 12),
                _item(Icons.credit_card, 'Payment & Promotions', 'Cards, wallet & Bank Transfer, enter promo code',
                    () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentScreen())); }),
                _item(Icons.access_time, 'My Rides', 'Past and upcoming',
                    () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyRidesScreen())); }),
                _item(Icons.shield_outlined, 'Safety', 'Emergency & contacts', () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyContactScreen())); }),
                _item(Icons.chat_bubble_outline, 'Support', 'Help center & issues', () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())); }),
                _item(Icons.info_outline, 'About', 'Version & legal', () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())); }),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 34, height: 34,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.directions_car_filled_outlined, size: 18, color: AppColors.white)),
                      const SizedBox(height: 10),
                      const Text('Become a driver', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white)),
                      const SizedBox(height: 2),
                      const Text('Earn money on your own schedule', style: TextStyle(fontSize: 12, color: Color(0xCCFFFFFF))),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, height: 44,
                        child: Material(color: AppColors.white, borderRadius: BorderRadius.circular(30),
                            child: InkWell(borderRadius: BorderRadius.circular(30), onTap: () {},
                                child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text('Learn more', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                                ])))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 51,
                  child: Material(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(30),
                      child: InkWell(borderRadius: BorderRadius.circular(30),
                          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                          child: const Center(child: Text('Sign out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red))))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, String sub, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Icon(icon, size: 22, color: _ink),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 12, color: _sub)),
            ])),
          ]),
        ),
      );
}
