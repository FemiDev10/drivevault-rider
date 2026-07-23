import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';

/// Brand splash — the DriveVault logo on the primary blue.
/// Rendered from the exact Figma export, then auto-advances to onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _FadeIn(
      child: Image(
        image: AssetImage('assets/images/splash.png'),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});
  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 600),
      child: widget.child,
    );
  }
}
