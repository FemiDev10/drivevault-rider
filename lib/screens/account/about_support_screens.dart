import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import 'account_widgets.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);
const _line = Color(0xFFEDEDED);

const _kVersion = 'Version DV.224.0';

/// 996:17492 — About DriveVault.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'About'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                RowTile(label: 'Rate the app', onTap: () => _toast(context, 'Opens the app store')),
                RowTile(label: 'Careers at DriveVault', onTap: () => _toast(context, 'Opens careers page')),
                RowTile(label: 'Terms of service', onTap: () => _openDoc(context, 'Terms of service')),
                RowTile(label: 'Privacy policy', last: true, onTap: () => _openDoc(context, 'Privacy policy')),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(_kVersion, style: TextStyle(fontSize: 14, color: _sub)),
          ),
        ]),
      ),
    );
  }

  void _toast(BuildContext c, String m) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

  void _openDoc(BuildContext c, String title) => Navigator.of(c).push(
      MaterialPageRoute(builder: (_) => _ArticleScreen(title: title, body: _legalBody, feedback: false)));
}

const _legalBody =
    'This prototype uses placeholder legal copy. In the shipping app this screen carries the '
    'full DriveVault agreement covering your use of the platform, negotiated fares, cancellation '
    'and no-show fees, driver conduct, data handling under the Nigeria Data Protection Act, and '
    'how disputes are resolved.\n\nContact legal@drivevault.ng with any questions.';

/// 996:17615 — Support home.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Support'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                // search
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(children: const [
                    Icon(Icons.search, size: 20, color: _sub),
                    SizedBox(width: 10),
                    Text('Search help articles...', style: TextStyle(fontSize: 14, color: _sub)),
                  ]),
                ),
                const SizedBox(height: 28),

                SectionLabel('Support cases'),
                _IconRow(
                  icon: Icons.chat_bubble_outline,
                  title: 'Inbox',
                  sub: 'View open cases',
                  last: true,
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SupportInboxScreen())),
                ),
                const SizedBox(height: 28),

                SectionLabel('Get help with a recent ride'),
                _RideRow(
                  place: 'Borno Way, Lagos',
                  when: 'Today, 4:10 PM',
                  trailing: 'Cancelled',
                  onTap: () => _issues(context),
                ),
                _RideRow(
                  place: 'Borno Way, Lagos',
                  when: 'Today, 4:10 PM',
                  trailing: '₦7,500',
                  last: true,
                  onTap: () => _issues(context),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _OlderRidesScreen())),
                  child: const Text('Select an older ride',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
                const SizedBox(height: 28),

                SectionLabel('Get help with something else'),
                RowTile(label: 'About DriveVault', onTap: () => _topic(context, 'About DriveVault')),
                RowTile(label: 'App and features', onTap: () => _topic(context, 'App and features')),
                RowTile(label: 'Account and data', onTap: () => _topic(context, 'Account and data')),
                RowTile(label: 'Payments and pricing', last: true, onTap: () => _topic(context, 'Payments and pricing')),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _issues(BuildContext c) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => const RideIssuesScreen()));

  void _topic(BuildContext c, String title) => Navigator.of(c).push(
      MaterialPageRoute(builder: (_) => _ArticleScreen(title: title, body: _topicBody, feedback: true)));
}

const _topicBody =
    'Browse the most common questions in this area. If none of them match what you’re seeing, '
    'you can start a support case and an agent will pick it up — usually within a few minutes '
    'during the day.';

/// 996:17952 — common ride issues.
class RideIssuesScreen extends StatelessWidget {
  const RideIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Get help'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                const Text('Browse common ride-related issues and get in touch with our support team below.',
                    style: TextStyle(fontSize: 14, color: _sub, height: 1.45)),
                const SizedBox(height: 20),
                RowTile(
                    label: 'My payment card was charged twice for the same trip',
                    onTap: () => _article(context, 'My payment card was charged twice for the same trip', _doubleChargeBody)),
                RowTile(
                    label: 'Issue with a cancellation fee',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ContactSupportScreen(subject: 'Issue with a cancellation fee')))),
                RowTile(
                    label: 'Ride did not happen',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ContactSupportScreen(subject: 'Ride did not happen')))),
                RowTile(
                    label: 'Other',
                    last: true,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ContactSupportScreen(subject: 'Other')))),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _article(BuildContext c, String t, String b) => Navigator.of(c)
      .push(MaterialPageRoute(builder: (_) => _ArticleScreen(title: t, body: b, feedback: true)));
}

const _doubleChargeBody =
    'There may be a temporary card authorisation to check your card’s validity and minimise any '
    'fraudulent use of your card and information. It is listed as a pending charge on your account. '
    'The authorisation is never charged to your account and is released immediately or within 14 days. '
    'In rare cases, it may take up to 30 days, depending on your bank. If the amount has not been '
    'released after 14 days, please contact your bank or financial institution. The authorisation can '
    'also be held for a cancelled ride.\n\n'
    'Card authorisation can fail for the following reasons:\n'
    '• You have insufficient funds in your account\n'
    '• Your bank doesn’t allow a transaction\n'
    '• The system notices suspicious card activity\n\n'
    'If it fails, you won’t be able to request a trip. In this case, please contact our Support team.';

/// 996:18109 / 996:18212 — help article with a "did this help?" step.
class _ArticleScreen extends StatefulWidget {
  const _ArticleScreen({required this.title, required this.body, required this.feedback});
  final String title;
  final String body;
  final bool feedback;

  @override
  State<_ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<_ArticleScreen> {
  bool? _helpful;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Help'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(widget.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink, height: 1.35)),
                const SizedBox(height: 18),
                Text(widget.body,
                    style: const TextStyle(fontSize: 14, color: _sub, height: 1.55)),
              ],
            ),
          ),
          if (widget.feedback) _feedbackBar(),
        ]),
      ),
    );
  }

  Widget _feedbackBar() {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: _helpful == false
          ? Column(children: [
              const Text('We’re sorry to hear that!',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
              const SizedBox(height: 4),
              const Text('Would you like to get in touch with us?',
                  style: TextStyle(fontSize: 13, color: _sub)),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Chat with us',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ContactSupportScreen(subject: widget.title))),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46, width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.stroke),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('No thank you',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                ),
              ),
            ])
          : _helpful == true
              ? const Center(
                  child: Text('Thanks — glad that helped.',
                      style: TextStyle(fontSize: 14, color: AppColors.green)))
              : Column(children: [
                  const Text('Does this information solve your issue?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _choice('Yes', () => setState(() => _helpful = true))),
                    const SizedBox(width: 10),
                    Expanded(child: _choice('No', () => setState(() => _helpful = false))),
                  ]),
                ]),
    );
  }

  Widget _choice(String label, VoidCallback onTap) => SizedBox(
        height: 40,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.stroke),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 14, color: _ink)),
        ),
      );
}

/// 996:18278 — describe the issue and send it in.
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key, required this.subject});
  final String subject;

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _msg = TextEditingController();

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Contact support'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(widget.subject,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 20),
                SectionLabel('Ride'),
                const _RideRow(place: 'Borno Way, Lagos', when: 'Today, 4:10 PM', last: true),
                const SizedBox(height: 20),
                LabeledField(
                  label: 'Describe your issue',
                  controller: _msg,
                  hint: 'Tell us what happened',
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: PrimaryButton(
              label: 'Send message',
              enabled: _msg.text.trim().isNotEmpty,
              onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SupportCaseScreen())),
            ),
          ),
        ]),
      ),
    );
  }
}

/// 996:18400 — case inbox.
class SupportInboxScreen extends StatelessWidget {
  const SupportInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Support cases'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                SectionLabel('Active'),
                _IconRow(
                  icon: Icons.chat_bubble_outline,
                  title: 'DriveVault Support',
                  sub: 'Our team is reviewing your case. An agent will message you here ASAP',
                  last: true,
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SupportCaseScreen())),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(_kVersion, style: TextStyle(fontSize: 14, color: _sub)),
          ),
        ]),
      ),
    );
  }
}

/// 996:18545 — the support case conversation.
class SupportCaseScreen extends StatelessWidget {
  const SupportCaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'DriveVault Support'),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(children: const [
              Text('Case 43975952', style: TextStyle(fontSize: 14, color: _sub)),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                _bubble('Thanks for reaching out — we’ve got your case and an agent is reviewing it now.',
                    '10:31 AM', false),
                const SizedBox(height: 16),
                _bubble('Okay, thank you.', '10:31 AM', true),
              ],
            ),
          ),
          // composer
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(22)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: const Text('Message...', style: TextStyle(fontSize: 14, color: _sub)),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.mic_none, size: 22, color: _sub),
              const SizedBox(width: 12),
              const Icon(Icons.send, size: 22, color: AppColors.primary),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _bubble(String text, String time, bool mine) => Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : const Color(0xFFF2F3F7),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text,
                style: TextStyle(fontSize: 14, color: mine ? AppColors.white : _ink, height: 1.35)),
            const SizedBox(height: 6),
            Text(time,
                style: TextStyle(
                    fontSize: 11, color: mine ? const Color(0xB3FFFFFF) : _sub)),
          ]),
        ),
      );
}

/// 996:17787 — older rides grouped by month.
class _OlderRidesScreen extends StatelessWidget {
  const _OlderRidesScreen();

  @override
  Widget build(BuildContext context) {
    Widget group(String month, List<Widget> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SectionLabel(month), ...rows, const SizedBox(height: 24)],
        );

    void open() => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RideIssuesScreen()));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Select a ride'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                group('March 2026', [
                  _RideRow(place: 'Borno Way, Lagos', when: 'Today, 4:10 PM', trailing: 'Cancelled', onTap: open),
                  _RideRow(place: 'Borno Way, Lagos', when: 'Today, 4:10 PM', trailing: '₦7,500', last: true, onTap: open),
                ]),
                group('January 2026', [
                  _RideRow(place: 'Borno Way, Lagos', when: 'Today, 4:10 PM', trailing: 'Cancelled', onTap: open),
                  _RideRow(place: 'Borno Way, Lagos', when: 'Today, 4:10 PM', trailing: '₦7,500', last: true, onTap: open),
                ]),
                group('December 2025', [
                  _RideRow(place: '38 Alh Wasiu Solaa Street, Lagos Nigeria', when: 'Today, 4:10 PM', trailing: 'Cancelled', onTap: open),
                  _RideRow(place: 'Borno Way, Lagos', when: 'Today, 4:10 PM', trailing: '₦7,500', last: true, onTap: open),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Icon + title + subtitle row with a chevron.
class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.title, required this.sub, this.onTap, this.last = false});
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 20, color: _ink),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: _ink)),
                  const SizedBox(height: 4),
                  Text(sub, style: const TextStyle(fontSize: 12, color: _sub, height: 1.3)),
                ]),
              ),
              const Icon(Icons.chevron_right, size: 24, color: _sub),
            ]),
          ),
        ),
        if (!last) const Divider(height: 1, color: _line),
      ]);
}

/// Car icon + place + time, with an optional status/fare on the right.
class _RideRow extends StatelessWidget {
  const _RideRow({required this.place, required this.when, this.trailing, this.onTap, this.last = false});
  final String place;
  final String when;
  final String? trailing;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.directions_car_outlined, size: 20, color: _ink),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(place, style: const TextStyle(fontSize: 14, color: _ink)),
                  const SizedBox(height: 4),
                  Text(when, style: const TextStyle(fontSize: 12, color: _sub)),
                ]),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Text(trailing!,
                    style: TextStyle(
                        fontSize: 12,
                        color: trailing == 'Cancelled' ? AppColors.red : _ink,
                        fontWeight: trailing == 'Cancelled' ? FontWeight.w400 : FontWeight.w600)),
              ],
            ]),
          ),
        ),
        if (!last) const Divider(height: 1, color: _line),
      ]);
}
