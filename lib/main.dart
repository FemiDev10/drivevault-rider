import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'widgets/phone_frame.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/auth/welcome_back_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/account/about_support_screens.dart';

void main() {
  runApp(const DriveVaultApp());
}

class DriveVaultApp extends StatelessWidget {
  const DriveVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        // SF Pro is the design font. It renders natively on Apple devices;
        // elsewhere the platform default is used. A bundled font can be added
        // later if exact cross-platform matching is required.
        fontFamily: 'SF Pro Display',
      ),
      // Wrap every screen in the phone frame so the web build looks like a
      // real device and stays pixel-matched to the 393x852 Figma canvas.
      builder: (context, child) => PhoneFrame(child: child ?? const SizedBox()),
      initialRoute: Routes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case Routes.splash:
            return _page(const SplashScreen());
          case Routes.onboarding:
            return _page(const OnboardingScreen());
          case Routes.createAccount:
            return _page(const CreateAccountScreen());
          case Routes.signIn:
            return _page(const WelcomeBackScreen());
          case Routes.otp:
            final phone = settings.arguments as String?;
            return _page(OtpScreen(phone: phone ?? '+234 816 687 9486'));
          case Routes.home:
            return _page(const HomeScreen());
          case Routes.account:
            return _page(const AccountScreen());
          case Routes.support:
            return _page(const SupportScreen());
          case Routes.about:
            return _page(const AboutScreen());
          default:
            return _page(const SplashScreen());
        }
      },
    );
  }

  static MaterialPageRoute _page(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}

/// Named routes for the whole app.
class Routes {
  Routes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const createAccount = '/auth/create';
  static const signIn = '/auth/signin';
  static const otp = '/auth/otp';
  static const home = '/home';
  static const account = '/account';
  static const support = '/support';
  static const about = '/about';
}
