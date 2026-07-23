import 'package:flutter/material.dart';
import 'dv_widgets.dart';

/// The Google + Apple social sign-in buttons used on Create Account and
/// Welcome Back. Non-functional in the prototype (mock auth only).
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
          label: 'Continue with Apple',
          icon: const Icon(Icons.apple, size: 16, color: Colors.black),
          onTap: () {},
        ),
      ],
    );
  }
}
