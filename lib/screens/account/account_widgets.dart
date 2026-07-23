import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);
const _line = Color(0xFFEDEDED);

/// "ICON LEFT" header from the design system: back chevron + title.
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: SizedBox(
        height: 42,
        child: Row(children: [
          InkWell(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: _ink),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _ink)),
        ]),
      ),
    );
  }
}

/// Small caps-ish section label above a group of rows.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
      );
}

/// Status pill (Verified / Verify / Locked).
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.color, {super.key});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}

/// A tappable settings row: label, optional value, optional status chip, chevron.
class RowTile extends StatelessWidget {
  const RowTile({
    super.key,
    required this.label,
    this.value,
    this.valueMuted = false,
    this.trailingChip,
    this.onTap,
    this.last = false,
    this.danger = false,
  });

  final String label;
  final String? value;
  final bool valueMuted;
  final Widget? trailingChip;
  final VoidCallback? onTap;
  final bool last;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final labelColor = danger ? AppColors.red : _ink;
    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
                if (value != null) ...[
                  const SizedBox(height: 3),
                  Text(value!,
                      style: TextStyle(
                          fontSize: 12,
                          color: valueMuted ? _sub : _sub,
                          fontStyle: valueMuted ? FontStyle.italic : FontStyle.normal)),
                ],
              ]),
            ),
            if (trailingChip != null) ...[trailingChip!, const SizedBox(width: 8)],
            if (!danger) const Icon(Icons.chevron_right, size: 24, color: _sub),
          ]),
        ),
      ),
      if (!last) const Divider(height: 1, color: _line),
    ]);
  }
}

/// A settings row with a switch. Disabled rows explain themselves rather than
/// silently doing nothing.
class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
    this.enabled = true,
    this.last = false,
  });

  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(fontSize: 14, color: enabled ? _ink : _sub)),
              if (sub != null) ...[
                const SizedBox(height: 3),
                Text(sub!, style: const TextStyle(fontSize: 12, color: _sub)),
              ],
            ]),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.white,
            activeTrackColor: AppColors.primary,
          ),
        ]),
      ),
      if (!last) const Divider(height: 1, color: _line),
    ]);
  }
}

/// Full-width primary button used across the account flows.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onTap, this.enabled = true});
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        width: double.infinity,
        child: Material(
          color: enabled ? AppColors.primary : const Color(0xFFC7CBD9),
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: enabled ? onTap : null,
            child: Center(
              child: Text(label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white)),
            ),
          ),
        ),
      );
}

/// Labelled text field matching the auth screens.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        enabled: enabled,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, color: _ink),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFB0B4C4)),
          filled: true,
          fillColor: enabled ? const Color(0xFFF7F8FC) : const Color(0xFFF0F1F5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    ]);
  }
}
