import 'package:flutter/material.dart';
import '../../main.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/dv_widgets.dart';
import '../../widgets/social_buttons.dart';

/// Create Account — first name, last name, phone. "Next" → OTP verification.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();

  bool get _valid =>
      _first.text.trim().isNotEmpty &&
      _last.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _next() {
    Navigator.of(context).pushNamed(
      Routes.otp,
      arguments: _phone.text.trim().isEmpty ? '+234 816 687 9486' : _phone.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackChevron(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in your details to get started.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.subTextGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const FieldLabel('First Name'),
                  const SizedBox(height: 8),
                  DvTextField(
                    hint: 'e.g Gbemi',
                    controller: _first,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Last Name'),
                  const SizedBox(height: 8),
                  DvTextField(
                    hint: 'e.g Adeyemi',
                    controller: _last,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Phone Number'),
                  const SizedBox(height: 8),
                  DvTextField(
                    hint: '+234 302 234 4242',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We’ll send a verification code here',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(label: 'Next', enabled: _valid, onTap: _next),
                  const SizedBox(height: 8),
                  const _TermsText(),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushReplacementNamed(Routes.signIn),
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(fontSize: 14, color: AppColors.black),
                            ),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(fontSize: 14, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const OrDivider('or sign up with'),
                  const SizedBox(height: 16),
                  const SocialButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'By signing up, you agree to our '),
            TextSpan(text: 'Terms of Use', style: TextStyle(color: AppColors.primary)),
            TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.primary)),
          ],
          style: TextStyle(fontSize: 13, color: AppColors.textInsideCircle),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
