import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/rider_profile.dart';
import 'account_widgets.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);

/// Identity verification via NIN — the flow the home screen's "Verify account"
/// prompt was pointing at but never had.
///
/// Nigerian riders verify with an 11-digit NIN. We state the purpose and the
/// data handling up front, because asking for a national ID without saying why
/// is the fastest way to lose a signup.
class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});
  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final _nin = TextEditingController();
  bool _consent = false;
  bool _submitting = false;

  bool get _valid => _nin.text.trim().length == 11 && _consent;

  @override
  void dispose() {
    _nin.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    RiderProfile.instance.submitNin(_nin.text.trim());
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _VerificationSubmittedScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Verify your account'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                const Text('Add your NIN',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 8),
                const Text(
                  'Your National Identification Number confirms you’re a real person. '
                  'It’s checked once and never shown to drivers.',
                  style: TextStyle(fontSize: 14, color: _sub, height: 1.45),
                ),
                const SizedBox(height: 24),
                LabeledField(
                  label: 'NIN',
                  controller: _nin,
                  hint: '11 digits',
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                _benefits(),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => setState(() => _consent = !_consent),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Checkbox(
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                      activeColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'I agree that DriveVault can verify this NIN with NIMC to confirm my identity.',
                          style: TextStyle(fontSize: 13, color: _sub, height: 1.4),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _submitting ? 'Checking…' : 'Submit for verification',
                  enabled: _valid && !_submitting,
                  onTap: _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.lock_outline, size: 13, color: _sub),
                    SizedBox(width: 6),
                    Text('Encrypted and stored securely',
                        style: TextStyle(fontSize: 12, color: _sub)),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _benefits() => Container(
        decoration: BoxDecoration(
            color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('What verifying unlocks',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
          SizedBox(height: 12),
          _Benefit('Priority support'),
          _Benefit('Mega promos'),
          _Benefit('Weekly discounts'),
          _Benefit('Keeps DriveVault safe for everyone'),
        ]),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: _sub))),
        ]),
      );
}

/// Confirmation after submitting — sets expectations instead of dumping the
/// rider back into a list with no feedback.
class _VerificationSubmittedScreen extends StatelessWidget {
  const _VerificationSubmittedScreen();

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
                    child: const Icon(Icons.hourglass_top, size: 32, color: AppColors.green),
                  ),
                  const SizedBox(height: 20),
                  const Text('Verification submitted',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
                  const SizedBox(height: 12),
                  const Text(
                    'We’re checking your details with NIMC. This usually takes a few minutes — '
                    'you can keep riding while we do.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.45),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Done',
                    onTap: () {
                      // prototype: approve so reviewers can see the verified state
                      RiderProfile.instance.approveId();
                      Navigator.of(context).pop();
                    },
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
