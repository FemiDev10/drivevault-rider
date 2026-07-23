import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/dv_widgets.dart';
import 'otp_screen.dart';

/// Email sign-in: enter an address, receive a 4-digit code.
///
/// Passwordless on purpose — the phone flow is already OTP-based, so adding a
/// password here would mean two different credentials to remember and a
/// "forgot password" branch that earns nothing.
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _email = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;

  bool get _valid {
    final v = _email.text.trim();
    final at = v.indexOf('@');
    return at > 0 && v.indexOf('.', at) > at + 1 && !v.endsWith('.');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _email.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OtpScreen(phone: _email.text.trim(), isEmail: true),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const StatusBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackChevron(onTap: () => Navigator.of(context).maybePop()),
                    const SizedBox(height: 16),
                    const Text(
                      'Continue with email',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'We’ll send you a 4-digit code. No password needed.',
                      style: TextStyle(fontSize: 14, color: AppColors.subTextGrey),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Email address',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _email,
                      focusNode: _focus,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _valid ? _sendCode() : null,
                      style: const TextStyle(fontSize: 15, color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFB0B4C4)),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 51,
                      child: Material(
                        color: _valid && !_sending ? AppColors.primary : const Color(0xFFC7CBD9),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _valid && !_sending ? _sendCode : null,
                          child: Center(
                            child: Text(
                              _sending ? 'Sending…' : 'Send code',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.lock_outline, size: 13, color: AppColors.subTextGrey),
                          SizedBox(width: 6),
                          Text('We never post or share anything',
                              style: TextStyle(fontSize: 12, color: AppColors.subTextGrey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
