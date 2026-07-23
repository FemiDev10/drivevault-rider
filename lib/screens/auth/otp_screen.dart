import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/dv_widgets.dart';

/// OTP verification. The prototype always accepts 1234.
/// States: typing → verifying (spinner) → success (→ Home) / incorrect (red).
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.phone = '+234 816 687 9486'});
  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

enum _OtpState { typing, verifying, incorrect }

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  _OtpState _state = _OtpState.typing;
  bool _showResentToast = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_state == _OtpState.incorrect && value.length < 4) {
      setState(() => _state = _OtpState.typing);
    } else {
      setState(() {});
    }
    if (value.length == 4) _verify();
  }

  void _verify() {
    FocusScope.of(context).unfocus();
    setState(() => _state = _OtpState.verifying);
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_controller.text == '1234') {
        Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (_) => false);
      } else {
        setState(() {
          _state = _OtpState.incorrect;
          _startCountdown();
        });
        _controller.clear();
        _focus.requestFocus();
      }
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  void _resend() {
    _controller.clear();
    setState(() {
      _state = _OtpState.typing;
      _showResentToast = true;
    });
    _startCountdown();
    _focus.requestFocus();
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showResentToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Column(
            children: [
              const StatusBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackChevron(onTap: () => Navigator.of(context).maybePop()),
                    const SizedBox(height: 16),
                    const Text(
                      'Verify your Phone Number',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Enter the 4-digit code sent to '),
                          TextSpan(
                            text: widget.phone,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          const TextSpan(text: ' via SMS'),
                        ],
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.subTextGrey,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _CodeBoxes(
                      value: _controller.text,
                      error: _state == _OtpState.incorrect,
                      onTap: () => _focus.requestFocus(),
                    ),
                    const SizedBox(height: 24),
                    _statusArea(),
                  ],
                ),
              ),
            ],
          ),

          // Hidden input that actually captures the typed code.
          Positioned(
            left: -100,
            child: SizedBox(
              width: 10,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                maxLength: 4,
                autofocus: true,
                showCursor: false,
                enabled: _state != _OtpState.verifying,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _onChanged,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),

          // "Code resent successfully" green toast.
          if (_showResentToast)
            Positioned(
              top: 26,
              left: 23,
              right: 23,
              child: Container(
                height: 49,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Code resent successfully',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusArea() {
    switch (_state) {
      case _OtpState.verifying:
        return const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 24),
            child: Column(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Verifying...',
                  style: TextStyle(fontSize: 14, color: AppColors.subTextGrey),
                ),
              ],
            ),
          ),
        );
      case _OtpState.incorrect:
        return Column(
          children: [
            const Center(
              child: Text(
                'Incorrect code. Try again',
                style: TextStyle(fontSize: 14, color: AppColors.red),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _seconds > 0
                  ? Text(
                      "Didn't receive any code? ${_seconds}secs",
                      style: const TextStyle(fontSize: 14, color: AppColors.subTextGrey),
                    )
                  : _resendLink(),
            ),
          ],
        );
      case _OtpState.typing:
        return Column(
          children: [
            Center(child: _resendLink()),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Wrong number? '),
                      TextSpan(text: 'Change', style: TextStyle(color: AppColors.primary)),
                    ],
                    style: TextStyle(fontSize: 14, color: AppColors.subTextGrey),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _resendLink() {
    return GestureDetector(
      onTap: _resend,
      child: const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: "Didn't receive any code? "),
            TextSpan(text: 'Resend', style: TextStyle(color: AppColors.primary)),
          ],
          style: TextStyle(fontSize: 14, color: AppColors.subTextGrey),
        ),
      ),
    );
  }
}

class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.value, required this.error, required this.onTap});
  final String value;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final filled = i < value.length;
            return Container(
              width: 67,
              height: 60,
              margin: EdgeInsets.only(right: i < 3 ? 20 : 0),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: error
                      ? AppColors.red
                      : (filled ? AppColors.primary : Colors.transparent),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                filled ? value[i] : '',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
