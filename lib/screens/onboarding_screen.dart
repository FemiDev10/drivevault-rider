import 'package:flutter/material.dart';
import '../main.dart';

/// Onboarding — three full-bleed slides exported pixel-exact from Figma.
/// Interactive hotspots (Skip / Next / Get Started) are overlaid on top of
/// the designed artwork and drive navigation. Swiping also works.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = <String>[
    'assets/images/onboarding1.png',
    'assets/images/onboarding2.png',
    'assets/images/onboarding3.png',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToAuth() => Navigator.of(context).pushReplacementNamed(Routes.createAccount);

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _goToAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Slides
        PageView.builder(
          controller: _controller,
          itemCount: _slides.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Image(
            image: AssetImage(_slides[i]),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // "Skip" hotspot (top-right) — matches the designed Skip label.
        Positioned(
          top: 48,
          right: 8,
          child: _Hotspot(
            width: 76,
            height: 40,
            onTap: _goToAuth,
          ),
        ),

        // "Next" / "Get Started" hotspot — sits over the blue button.
        Positioned(
          left: 24,
          right: 24,
          bottom: 44,
          child: _Hotspot(
            height: 58,
            borderRadius: 30,
            onTap: _next,
          ),
        ),
      ],
    );
  }
}

/// A transparent, tappable region with a subtle press ripple.
class _Hotspot extends StatelessWidget {
  const _Hotspot({
    required this.onTap,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final VoidCallback onTap;
  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: SizedBox(width: width, height: height),
      ),
    );
  }
}
