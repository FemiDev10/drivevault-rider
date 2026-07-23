import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/rider_profile.dart';
import 'account_widgets.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);

/// Shared scaffold for the small single-purpose edit flows.
class _EditScaffold extends StatelessWidget {
  const _EditScaffold({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          top: false,
          child: Column(children: [
            const StatusBar(),
            AccountHeader(title: title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: children,
              ),
            ),
          ]),
        ),
      );
}

/// Name is editable only before identity verification. After KYC it must match
/// the ID on file, so we explain and route to support instead of silently
/// disabling the field.
class EditNameScreen extends StatefulWidget {
  const EditNameScreen({super.key});
  @override
  State<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  final _p = RiderProfile.instance;
  late final _first = TextEditingController(text: _p.firstName);
  late final _last = TextEditingController(text: _p.lastName);

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_p.nameLocked) {
      return _EditScaffold(title: 'Full name', children: [
        _Notice(
          icon: Icons.lock_outline,
          title: 'Your name is locked',
          body: 'Your account is verified, so your name must match the ID on file. '
              'Our support team can change it if something is wrong.',
        ),
        const SizedBox(height: 16),
        _ReadOnlyValue(label: 'Full name', value: _p.fullName),
        const SizedBox(height: 24),
        PrimaryButton(
            label: 'Contact support',
            onTap: () => Navigator.of(context).pushNamed('/support')),
      ]);
    }

    return _EditScaffold(title: 'Full name', children: [
      const Text('Use the name on your ID. Once you verify your account, this can’t be changed here.',
          style: TextStyle(fontSize: 14, color: _sub, height: 1.45)),
      const SizedBox(height: 24),
      LabeledField(label: 'First name', controller: _first, onChanged: (_) => setState(() {})),
      const SizedBox(height: 16),
      LabeledField(label: 'Last name', controller: _last, onChanged: (_) => setState(() {})),
      const SizedBox(height: 28),
      PrimaryButton(
        label: 'Save',
        enabled: _first.text.trim().isNotEmpty && _last.text.trim().isNotEmpty,
        onTap: () {
          _p.setName(_first.text, _last.text);
          Navigator.of(context).pop();
        },
      ),
    ]);
  }
}

/// Changing the phone number re-verifies with an OTP, because the number is
/// the login credential and the anchor for masked driver calls.
class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});
  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = RiderProfile.instance;
    return _EditScaffold(title: 'Phone number', children: [
      _ReadOnlyValue(label: 'Current number', value: p.phone, chip: 'Verified'),
      const SizedBox(height: 24),
      if (!_codeSent) ...[
        const Text('You’ll sign in with this number, and drivers reach you through it. '
            'We’ll send a code to confirm it’s yours.',
            style: TextStyle(fontSize: 14, color: _sub, height: 1.45)),
        const SizedBox(height: 20),
        LabeledField(
          label: 'New phone number',
          controller: _phone,
          hint: '+234 800 000 0000',
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Send code',
          enabled: _phone.text.trim().length >= 10,
          onTap: () => setState(() => _codeSent = true),
        ),
      ] else ...[
        Text('Enter the 4-digit code we sent to ${_phone.text.trim()}.',
            style: const TextStyle(fontSize: 14, color: _sub, height: 1.45)),
        const SizedBox(height: 20),
        LabeledField(
          label: 'Verification code',
          controller: _code,
          hint: '••••',
          keyboardType: TextInputType.number,
          maxLength: 4,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.red)),
        ],
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Confirm new number',
          enabled: _code.text.trim().length == 4,
          onTap: () {
            if (_code.text.trim() != '0291') {
              setState(() => _error = 'That code isn’t right. Check and try again.');
              return;
            }
            p.setPhone(_phone.text.trim());
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone number updated')));
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _codeSent = false),
            child: const Text('Use a different number',
                style: TextStyle(fontSize: 13, color: AppColors.primary)),
          ),
        ),
      ],
    ]);
  }
}

/// Email is optional — plenty of riders sign up with a phone only — but it must
/// be confirmed before it can carry receipts.
class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});
  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _p = RiderProfile.instance;
  late final _email = TextEditingController(text: _p.email ?? '');
  bool _sent = false;

  bool get _valid {
    final v = _email.text.trim();
    return v.contains('@') && v.contains('.') && v.length > 5;
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // already verified — show state and allow a change
    if (_p.email != null && _p.emailVerified && !_sent) {
      return _EditScaffold(title: 'Email address', children: [
        _ReadOnlyValue(label: 'Email address', value: _p.email!, chip: 'Verified'),
        const SizedBox(height: 16),
        const Text('Receipts and trip summaries are sent here.',
            style: TextStyle(fontSize: 14, color: _sub)),
        const SizedBox(height: 24),
        LabeledField(
          label: 'Change email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Send confirmation link',
          enabled: _valid && _email.text.trim() != _p.email,
          onTap: () {
            _p.setEmail(_email.text);
            setState(() => _sent = true);
          },
        ),
      ]);
    }

    if (_sent) {
      return _EditScaffold(title: 'Email address', children: [
        _Notice(
          icon: Icons.mark_email_unread_outlined,
          title: 'Check your inbox',
          body: 'We sent a confirmation link to ${_p.email}. '
              'Your email isn’t used for receipts until you confirm it.',
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'I’ve confirmed it',
          onTap: () {
            _p.confirmEmail();
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _sent = false),
            child: const Text('Resend or change address',
                style: TextStyle(fontSize: 13, color: AppColors.primary)),
          ),
        ),
      ]);
    }

    return _EditScaffold(title: 'Email address', children: [
      const Text('Optional — add an email if you want receipts and trip summaries. '
          'You’ll always be able to sign in with your phone number.',
          style: TextStyle(fontSize: 14, color: _sub, height: 1.45)),
      const SizedBox(height: 24),
      LabeledField(
        label: 'Email address',
        controller: _email,
        hint: 'you@example.com',
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 28),
      PrimaryButton(
        label: 'Send confirmation link',
        enabled: _valid,
        onTap: () {
          _p.setEmail(_email.text);
          setState(() => _sent = true);
        },
      ),
    ]);
  }
}

/// Emergency contact — required for the safety features the menu advertises.
class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});
  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final _p = RiderProfile.instance;
  late final _name = TextEditingController(text: _p.emergencyName ?? '');
  late final _phone = TextEditingController(text: _p.emergencyPhone ?? '');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EditScaffold(title: 'Emergency contact', children: [
        const Text('If you use the SOS button during a trip, we’ll share your live location '
            'and trip details with this person.',
            style: TextStyle(fontSize: 14, color: _sub, height: 1.45)),
        const SizedBox(height: 24),
        LabeledField(label: 'Contact name', controller: _name, onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        LabeledField(
            label: 'Phone number',
            controller: _phone,
            hint: '+234 800 000 0000',
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Save contact',
          enabled: _name.text.trim().isNotEmpty && _phone.text.trim().length >= 10,
          onTap: () {
            _p.setEmergency(_name.text, _phone.text);
            Navigator.of(context).pop();
          },
        ),
      ]);
}

/// Informational callout.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 13, color: _sub, height: 1.4)),
            ]),
          ),
        ]),
      );
}

/// Non-editable value display with an optional status chip.
class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value, this.chip});
  final String label;
  final String value;
  final String? chip;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F1F5), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 15, color: _ink))),
              if (chip != null) StatusChip(chip!, AppColors.green),
            ]),
          ),
        ],
      );
}
