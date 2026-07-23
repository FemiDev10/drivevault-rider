import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/driver.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);

class _Bubble {
  final bool mine;
  final String text, time;
  const _Bubble(this.mine, this.text, this.time);
}

/// Message the driver (chat).
class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  static const _msgs = [
    _Bubble(false, 'Hi! I’m at the main entrance', '10:30 AM'),
    _Bubble(true, 'Perfect! I’ll be there in 5 minutes', '10:31 AM'),
    _Bubble(true, 'Great, see you soon!', '10:31 AM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const StatusBar(),
            SizedBox(
              height: 42,
              child: Row(children: [
                const SizedBox(width: 24),
                InkWell(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.arrow_back_ios_new, size: 20, color: _ink)),
                const Expanded(child: Center(child: Text('Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)))),
                Container(width: 36, height: 36,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.call, size: 18, color: AppColors.white)),
                const SizedBox(width: 24),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFEDEDED)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                children: [
                  for (final m in _msgs) _bubble(m),
                ],
              ),
            ),
            // quick replies
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  for (final q in ['I’ve arrived', 'Ok, got it!', 'I’m on my way']) _chip(q),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: const [
                  Expanded(child: TextField(cursorColor: AppColors.primary,
                      decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Message…', hintStyle: TextStyle(color: _sub)))),
                  Icon(Icons.mic_none, size: 20, color: _sub),
                  SizedBox(width: 8),
                  CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(Icons.send, size: 16, color: AppColors.white)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_Bubble m) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: m.mine ? AppColors.primary : const Color(0xFFF0F2FA),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14), topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(m.mine ? 14 : 2), bottomRight: Radius.circular(m.mine ? 2 : 14),
              ),
            ),
            child: Text(m.text, style: TextStyle(fontSize: 14, color: m.mine ? AppColors.white : _ink)),
          ),
          const SizedBox(height: 4),
          Text(m.time, style: const TextStyle(fontSize: 11, color: _sub)),
        ]),
      );

  Widget _chip(String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFE6E8F0))),
          child: Text(label, style: const TextStyle(fontSize: 13, color: _ink)),
        ),
      );
}

/// "Call driver" — pick a method, then place the call.
///
/// Selecting a radio must not dial on its own: riders tap to compare options,
/// and an accidental call to a driver is expensive to undo. Choose, then Call.
void showCallDriverSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CallDriverSheet(parent: context),
  );
}

class _CallDriverSheet extends StatefulWidget {
  const _CallDriverSheet({required this.parent});
  final BuildContext parent;
  @override
  State<_CallDriverSheet> createState() => _CallDriverSheetState();
}

class _CallDriverSheetState extends State<_CallDriverSheet> {
  int _method = 0; // 0 = in-app, 1 = phone

  void _call() {
    Navigator.pop(context);
    if (_method == 0) {
      Navigator.of(widget.parent).push(
          MaterialPageRoute(builder: (_) => const CallDriverScreen()));
    } else {
      ScaffoldMessenger.of(widget.parent).showSnackBar(
          const SnackBar(content: Text('Dialling the driver on your phone…')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
              width: 68, height: 5,
              decoration: BoxDecoration(
                  color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18))),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Call driver',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
          const Spacer(),
          InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, size: 22, color: _ink)),
        ]),
        const SizedBox(height: 4),
        const Text('Choose how you\u2019d like to contact the driver',
            style: TextStyle(fontSize: 13, color: _sub)),
        const SizedBox(height: 8),
        _option(0, Icons.smartphone, 'In-app call', 'Free \u00b7 your number stays private'),
        const Divider(height: 1, color: Color(0xFFEDEDED)),
        _option(1, Icons.call, 'Phone call', 'Uses your airtime'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 51,
          child: Material(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: _call,
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.call, size: 18, color: AppColors.white),
                  const SizedBox(width: 8),
                  Text(_method == 0 ? 'Call in app' : 'Call on phone',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _option(int value, IconData icon, String label, String sub) {
    final selected = _method == value;
    return InkWell(
      onTap: () => setState(() => _method = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Icon(icon, size: 20, color: selected ? AppColors.primary : _ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: _ink)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 12, color: _sub)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18, height: 18,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? AppColors.primary : const Color(0xFFC7CBD9),
                    width: selected ? 5 : 1.5)),
          ),
        ]),
      ),
    );
  }
}

/// Active call screen.
class CallDriverScreen extends StatelessWidget {
  const CallDriverScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const StatusBar(),
            const Spacer(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(16)),
              child: Column(children: const [
                Text('Jerry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                SizedBox(height: 2),
                Text('Blue · Toyota Yaris', style: TextStyle(fontSize: 13, color: _sub)),
                SizedBox(height: 2),
                Text('EP2928404', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.verified, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Verified', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            CircleAvatar(radius: 44, backgroundImage: AssetImage(kDriver.avatar)),
            const SizedBox(height: 12),
            const Text('Calling…', style: TextStyle(fontSize: 15, color: _sub)),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _callBtn(Icons.volume_up_outlined, 'Speaker', const Color(0xFFF5F6FA), _ink, () {}),
              _callBtn(Icons.mic_off_outlined, 'Mute', const Color(0xFFF5F6FA), _ink, () {}),
              _callBtn(Icons.call_end, 'End call', AppColors.red, AppColors.white, () => Navigator.of(context).maybePop()),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _callBtn(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) => Column(children: [
        Material(color: bg, shape: const CircleBorder(),
            child: InkWell(onTap: onTap, customBorder: const CircleBorder(),
                child: SizedBox(width: 60, height: 60, child: Icon(icon, size: 24, color: fg)))),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: _sub)),
      ]);
}
