import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Back chevron used on every auth/OTP screen (weui:back-filled, ~9.5x17).
class BackChevron extends StatelessWidget {
  const BackChevron({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.black),
          ),
        ),
      ),
    );
  }
}

/// Primary pill button — bg #1A2A80, height 50, radius 30, 14px Semibold white.
/// Dims to a muted blue when [enabled] is false.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: enabled ? AppColors.primary : const Color(0xFF8B93C0),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Field label — 12px Medium black.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.black,
      ),
    );
  }
}

/// Filled text field — bg #F7F7F7, height 48, radius 4, 14px placeholder #9D9EB1.
class DvTextField extends StatelessWidget {
  const DvTextField({
    super.key,
    required this.hint,
    this.controller,
    this.keyboardType,
    this.onChanged,
  });

  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        cursorColor: AppColors.primary,
        style: const TextStyle(fontSize: 14, color: AppColors.black),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9D9EB1)),
        ),
      ),
    );
  }
}

/// "or sign up with" / "or continue with" divider row.
class OrDivider extends StatelessWidget {
  const OrDivider(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.stroke, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6A7282)),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.stroke, height: 1)),
      ],
    );
  }
}

/// Outlined social button (Google / Apple) — border #E1E1E1, h50, radius 30.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Color(0xFFE1E1E1)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 16, height: 16, child: icon),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: AppColors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The white iOS home indicator bar at the very bottom.
class HomeIndicator extends StatelessWidget {
  const HomeIndicator({super.key, this.color = AppColors.black});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 129,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}
