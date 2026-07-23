import 'package:flutter/material.dart';
import 'dv_widgets.dart';
import '../screens/auth/email_login_screen.dart';

/// The Google + email + Apple sign-in buttons used on Create Account and
/// Welcome Back. Google/Apple are mock-only; email runs a real OTP flow.
class SocialButtons extends StatelessWidget {
  const SocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialButton(
          label: 'Continue with Google',
          icon: Image.asset('assets/icons/google.png'),
          onTap: () {},
        ),
        const SizedBox(height: 8),
        SocialButton(
          label: 'Continue with email',
          icon: const Icon(Icons.mail_outline, size: 16, color: Colors.black),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EmailLoginScreen())),
        ),
        const SizedBox(height: 8),
        SocialButton(
          label: 'Continue with Apple',
          icon: const Icon(Icons.apple, size: 16, color: Colors.black),
          onTap: () {},
        ),
      ],
    );
  }
}
