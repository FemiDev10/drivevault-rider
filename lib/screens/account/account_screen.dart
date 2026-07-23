import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/rider_profile.dart';
import '../../services/mock/safety_repository.dart';
import '../safety/safety_screens.dart';
import 'account_widgets.dart';
import 'verify_identity_screen.dart';
import 'edit_field_screens.dart';
import 'about_support_screens.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);

/// Rider account.
///
/// Deliberate departures from the original frame, and why:
/// * Name / phone / email are **not** free-text rows. Each opens a guarded flow
///   (phone re-OTPs, name locks after KYC, email needs confirmation).
/// * Adds identity verification, which the home screen already promises.
/// * Adds emergency contact, receipt delivery and account deletion — table
///   stakes for a ride-hailing account, all missing from the original.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _p = RiderProfile.instance;

  @override
  void initState() {
    super.initState();
    _p.addListener(_onChange);
  }

  @override
  void dispose() {
    _p.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const StatusBar(),
            const AccountHeader(title: 'Account'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                children: [
                  _profileBlock(),
                  const SizedBox(height: 24),
                  if (_p.idStatus != IdStatus.verified) ...[
                    _verifyBanner(),
                    const SizedBox(height: 28),
                  ],

                  SectionLabel('Personal details'),
                  RowTile(
                    label: 'Full name',
                    value: _p.fullName,
                    trailingChip: _p.nameLocked ? const StatusChip('Locked', AppColors.mutedText) : null,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditNameScreen())),
                  ),
                  RowTile(
                    label: 'Phone number',
                    value: _p.phone,
                    trailingChip: _p.phoneVerified ? const StatusChip('Verified', AppColors.green) : null,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChangePhoneScreen())),
                  ),
                  RowTile(
                    label: 'Email address',
                    value: _p.email ?? 'Not added',
                    valueMuted: _p.email == null,
                    trailingChip: _p.email == null
                        ? null
                        : (_p.emailVerified
                            ? const StatusChip('Verified', AppColors.green)
                            : const StatusChip('Verify', Color(0xFFB25E02))),
                    last: true,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EmailScreen())),
                  ),
                  const SizedBox(height: 28),

                  SectionLabel('Safety'),
                  RowTile(
                    label: 'Emergency contacts',
                    value: SafetyStore.instance.contacts.isEmpty
                        ? 'None added'
                        : '${SafetyStore.instance.contacts.length} added',
                    valueMuted: SafetyStore.instance.contacts.isEmpty,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const EmergencyContactsScreen())),
                  ),
                  RowTile(
                    label: 'Safety centre',
                    value: 'Share trip, report an issue, SOS',
                    last: true,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SafetyHubScreen())),
                  ),
                  const SizedBox(height: 28),

                  SectionLabel('Preferences'),
                  SwitchTile(
                    label: 'Email me receipts',
                    sub: _p.email == null
                        ? 'Add an email address to turn this on'
                        : 'Sent to ${_p.email}',
                    value: _p.emailReceipts && _p.emailVerified,
                    enabled: _p.emailVerified,
                    onChanged: _p.toggleEmailReceipts,
                  ),
                  SwitchTile(
                    label: 'Promotions and offers',
                    sub: 'Discounts, referrals and product news',
                    value: _p.promos,
                    onChanged: _p.togglePromos,
                    last: true,
                  ),
                  const SizedBox(height: 28),

                  SectionLabel('More'),
                  RowTile(label: 'About DriveVault', onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()))),
                  RowTile(label: 'Support', onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SupportScreen()))),
                  RowTile(
                      label: 'Delete account',
                      danger: true,
                      last: true,
                      onTap: _confirmDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileBlock() {
    final verified = _p.idStatus == IdStatus.verified;
    return Row(children: [
      Container(
        width: 64, height: 64,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(_p.initials,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white)),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(_p.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
            ),
            if (verified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 18, color: AppColors.green),
            ],
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star, size: 14, color: Color(0xFFF5C518)),
            const SizedBox(width: 4),
            Text(_p.rating.toStringAsFixed(2), style: const TextStyle(fontSize: 13, color: _sub)),
            const SizedBox(width: 12),
            Text('${_p.trips} trips', style: const TextStyle(fontSize: 13, color: _sub)),
          ]),
        ]),
      ),
    ]);
  }

  /// The home screen promises "Verify account" — this is where that lands.
  Widget _verifyBanner() {
    final inReview = _p.idStatus == IdStatus.inReview;
    return Container(
      decoration: BoxDecoration(
        color: inReview ? const Color(0xFFF3F5FF) : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: inReview ? const Color(0xFFD6DCFF) : const Color(0xFFFFE2AE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(inReview ? Icons.hourglass_top : Icons.badge_outlined,
            size: 22, color: inReview ? AppColors.primary : const Color(0xFFB25E02)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(inReview ? 'Verification in review' : 'Verify your account',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 4),
            Text(
              inReview
                  ? 'We’re checking your NIN ending ${_p.ninLast4}. This usually takes a few minutes.'
                  : 'Add your NIN to unlock priority support, mega promos and weekly discounts — and help keep DriveVault safe for everyone.',
              style: const TextStyle(fontSize: 13, color: _sub, height: 1.35),
            ),
            if (!inReview) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VerifyIdentityScreen())),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text('Verify now',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete your account?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
        content: const Text(
          'This permanently removes your rides, receipts and saved payment methods. '
          'Any open support case or unpaid fare must be settled first.',
          style: TextStyle(fontSize: 14, color: _sub, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep my account',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Deletion request sent. We’ll email you within 30 days.')));
            },
            child: const Text('Delete',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
