import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/safety_repository.dart';
import '../account/account_widgets.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);
const _line = Color(0xFFEDEDED);

/// 991:16291 — Safety hub.
class SafetyHubScreen extends StatefulWidget {
  const SafetyHubScreen({super.key});
  @override
  State<SafetyHubScreen> createState() => _SafetyHubScreenState();
}

class _SafetyHubScreenState extends State<SafetyHubScreen> {
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

  @override
  Widget build(BuildContext context) {
    final n = _s.contacts.length;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Safety'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                _row(Icons.contacts_outlined, 'Emergency contacts',
                    n == 0 ? 'None added' : '$n added',
                    () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const EmergencyContactsScreen()))),
                // "Share trip" deliberately omitted: it only means anything during
                // an active trip, and the in-trip sheet already carries that action.
                _row(Icons.flag_outlined, 'Report an issue',
                    'Report unsafe driver or incident',
                    () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
                    last: true),
                const SizedBox(height: 28),
                // The SOS entry point lives here too, not only mid-trip.
                _sosButton(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sosButton() => SizedBox(
        height: 52,
        child: Material(
          color: AppColors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => showSosSheet(context),
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.sos, size: 20, color: AppColors.red),
                SizedBox(width: 8),
                Text('Emergency assistance',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.red)),
              ]),
            ),
          ),
        ),
      );

  Widget _row(IconData icon, String title, String sub, VoidCallback onTap, {bool last = false}) =>
      Column(children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
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

/// 3027:20993 — SOS. Deliberately two-step: nothing dials until the rider
/// taps the red button, and the notify-contacts choice is explicit.
void showSosSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SosSheet(),
  );
}

class _SosSheet extends StatefulWidget {
  const _SosSheet();
  @override
  State<_SosSheet> createState() => _SosSheetState();
}

class _SosSheetState extends State<_SosSheet> {
  final _s = SafetyStore.instance;
  late final Set<EmergencyContact> _notify = _s.contacts.toSet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
              width: 68, height: 5,
              decoration: BoxDecoration(
                  color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18))),
        ),
        const SizedBox(height: 20),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.10), shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded, size: 28, color: AppColors.red),
        ),
        const SizedBox(height: 14),
        const Text('Only use this in a genuine emergency.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 6),
        const Text('If you are in danger, tap the button below to call.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _sub, height: 1.4)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 54,
          child: Material(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: AppColors.red,
                  content: Text(_notify.isEmpty
                      ? 'Calling 112…'
                      : 'Calling 112 · notifying ${_notify.length} contact${_notify.length == 1 ? '' : 's'}'),
                ));
              },
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.call, size: 20, color: AppColors.white),
                  SizedBox(width: 8),
                  Text('Call 112',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text("This will call Nigeria's national emergency number",
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _sub)),
        const SizedBox(height: 20),
        if (_s.contacts.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Also notify your trusted contacts?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
          ),
          const SizedBox(height: 8),
          ..._s.contacts.map((c) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.trailing,
                activeColor: AppColors.primary,
                value: _notify.contains(c),
                onChanged: (v) => setState(() =>
                    v == true ? _notify.add(c) : _notify.remove(c)),
                title: Text(c.name, style: const TextStyle(fontSize: 14, color: _ink)),
                subtitle: Text(c.phone, style: const TextStyle(fontSize: 12, color: _sub)),
              )),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(12)),
            child: const Text(
                'You have no emergency contacts yet. Add one so we can alert someone for you.',
                style: TextStyle(fontSize: 13, color: _sub, height: 1.4)),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _sub)),
          ),
        ),
      ]),
    );
  }
}

/// 991:17218 / 991:16470 — emergency contacts list + empty state.
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});
  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
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

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add() async {
    final added = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AddEmergencyContactScreen()));
    if (added == true && mounted) _toast('Contact added');
  }

  @override
  Widget build(BuildContext context) {
    final empty = _s.contacts.isEmpty;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Emergency contacts'),
          Expanded(
            child: empty
                ? _emptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    children: [
                      const Text('EMERGENCY CONTACTS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: _sub)),
                      const SizedBox(height: 6),
                      const Text('These contacts will be notified if you trigger the SOS button.',
                          style: TextStyle(fontSize: 12, color: _sub, height: 1.4)),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _s.contacts.length; i++)
                        _contactRow(_s.contacts[i], i == _s.contacts.length - 1),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: PrimaryButton(label: 'Add emergency contact', onTap: _add),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: Color(0xFFF0F2FA), shape: BoxShape.circle),
              child: const Icon(Icons.contacts_outlined, size: 32, color: _sub),
            ),
            const SizedBox(height: 18),
            const Text('No contacts added',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 8),
            const Text(
                'For your security, add at least one person that we can call in an emergency.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.45)),
          ]),
        ),
      );

  Widget _contactRow(EmergencyContact c, bool last) => Column(children: [
        InkWell(
          onTap: () => _editSheet(c),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: Color(0xFFF0F2FA), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                    c.firstName.isEmpty ? '?' : c.firstName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: const TextStyle(fontSize: 14, color: _ink)),
                  const SizedBox(height: 3),
                  Text(c.phone, style: const TextStyle(fontSize: 12, color: _sub)),
                ]),
              ),
              const Icon(Icons.more_horiz, size: 22, color: _sub),
            ]),
          ),
        ),
        if (!last) const Divider(height: 1, color: _line),
      ]);

  /// 3014:23399 — edit sheet with remove.
  void _editSheet(EmergencyContact c) {
    final first = TextEditingController(text: c.firstName);
    final last = TextEditingController(text: c.lastName);
    final phone = TextEditingController(text: c.phone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                  width: 68, height: 5,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18))),
            ),
            const SizedBox(height: 16),
            const Text('Edit contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 16),
            LabeledField(label: 'Full name', controller: first),
            const SizedBox(height: 12),
            LabeledField(label: 'Last name', controller: last),
            const SizedBox(height: 12),
            LabeledField(label: 'Phone number', controller: phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save changes',
              onTap: () {
                _s.updateContact(c, first.text, last.text, phone.text);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48, width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmDelete(c);
                },
                child: const Text('Remove contact',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.red)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// 3018:23552 — delete confirmation.
  void _confirmDelete(EmergencyContact c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Emergency Contact?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
        content: Text('${c.name} will no longer be notified if you trigger SOS.',
            style: const TextStyle(fontSize: 14, color: _sub, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              _s.removeContact(c);
              Navigator.pop(ctx);
              _toast('Contact deleted');
            },
            child: const Text('Delete',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

/// 991:16593 — add contact form.
class AddEmergencyContactScreen extends StatefulWidget {
  const AddEmergencyContactScreen({super.key});
  @override
  State<AddEmergencyContactScreen> createState() => _AddEmergencyContactScreenState();
}

class _AddEmergencyContactScreenState extends State<AddEmergencyContactScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController(text: '+234 ');

  bool get _valid =>
      _first.text.trim().isNotEmpty && _phone.text.replaceAll(RegExp(r'\D'), '').length >= 11;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
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
          const AccountHeader(title: 'Add contact'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                LabeledField(
                    label: 'First name',
                    controller: _first,
                    hint: 'Enter first name',
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 16),
                LabeledField(
                    label: 'Last name',
                    controller: _last,
                    hint: 'Enter last name',
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 16),
                LabeledField(
                    label: 'Phone number',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {})),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: PrimaryButton(
              label: 'Add contact',
              enabled: _valid,
              onTap: () {
                SafetyStore.instance.addContact(EmergencyContact(
                    firstName: _first.text, lastName: _last.text, phone: _phone.text));
                Navigator.of(context).pop(true);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

/// 3025:20511 — report an unsafe driver or incident.
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});
  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  static const _reasons = [
    'Driver was rude or aggressive',
    'Driver took a wrong route',
    'Driver asked for more than agreed fare',
    'I felt unsafe during the ride',
    'Driver did not have AC on',
    'Other',
  ];

  int? _picked;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
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
          const AccountHeader(title: 'Report an issue'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                // which trip this is about
                Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('Reporting for trip on June 8, 2026',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                    SizedBox(height: 4),
                    Text('Lagos Island → Victoria Island',
                        style: TextStyle(fontSize: 12, color: _sub)),
                  ]),
                ),
                const SizedBox(height: 22),
                const Text('What Happened?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 8),
                for (var i = 0; i < _reasons.length; i++) _reasonRow(i),
                const SizedBox(height: 22),
                const Text('Tell us more (optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                const SizedBox(height: 8),
                TextField(
                  controller: _details,
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14, color: _ink),
                  decoration: InputDecoration(
                    hintText: 'Describe what happened...',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB0B4C4)),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FC),
                    counterText: '${_details.text.length}/500',
                    counterStyle: const TextStyle(fontSize: 11, color: _sub),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(children: [
              PrimaryButton(
                label: 'Submit report',
                enabled: _picked != null,
                onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const _ReportSubmittedScreen())),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.lock_outline, size: 13, color: _sub),
                SizedBox(width: 6),
                Text('Your report is confidential.',
                    style: TextStyle(fontSize: 12, color: _sub)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _reasonRow(int i) {
    final on = _picked == i;
    return InkWell(
      onTap: () => setState(() => _picked = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Expanded(
            child: Text(_reasons[i],
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    color: _ink)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18, height: 18,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: on ? AppColors.primary : const Color(0xFFC7CBD9),
                    width: on ? 5 : 1.5)),
          ),
        ]),
      ),
    );
  }
}

/// 3027:21163 — report submitted.
class _ReportSubmittedScreen extends StatelessWidget {
  const _ReportSubmittedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72, height: 72,
                    decoration: const BoxDecoration(color: Color(0xFFECFDF3), shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 34, color: AppColors.green),
                  ),
                  const SizedBox(height: 20),
                  const Text('Report submitted',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
                  const SizedBox(height: 12),
                  const Text(
                      'Thanks for telling us. Our safety team reviews every report and will follow up if we need more detail.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.45)),
                  const SizedBox(height: 32),
                  PrimaryButton(
                      label: 'Go back to safety',
                      onTap: () => Navigator.of(context).pop()),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
