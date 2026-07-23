import 'package:flutter/material.dart';
import '../../main.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/dv_widgets.dart';
import '../../widgets/social_buttons.dart';

/// Welcome Back — phone sign-in. "Next" → OTP verification.
class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  final _phone = TextEditingController();
  bool get _valid => _phone.text.trim().isNotEmpty;

  @override
  void dispose() {
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
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to continue to DriveVault',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.subTextGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const FieldLabel('Phone Number'),
                  const SizedBox(height: 8),
                  DvTextField(
                    hint: 'Please enter your phone number',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Next', enabled: _valid, onTap: _next),
                  const SizedBox(height: 24),
                  const OrDivider('or continue with'),
                  const SizedBox(height: 16),
                  const SocialButtons(),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushReplacementNamed(Routes.createAccount),
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(fontSize: 14, color: AppColors.black),
                            ),
                            TextSpan(
                              text: 'Sign Up',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
