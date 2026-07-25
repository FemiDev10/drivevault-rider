import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // web-only prototype — used for "Save to phone" download
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/safety_repository.dart';
import '../account/account_widgets.dart';

const _ink = Color(0xFF0A0F2C);
const _sub = Color(0xFF808080);
const _line = Color(0xFFEDEDED);

/// Safety recorder — lets a rider record ride activity (audio voice-note style)
/// and save it to their phone. Prototype: audio capture is simulated, but
/// "Save to phone" performs a real browser download so the flow is genuine.
class RideRecorderScreen extends StatefulWidget {
  const RideRecorderScreen({super.key});

  @override
  State<RideRecorderScreen> createState() => _RideRecorderScreenState();
}

class _RideRecorderScreenState extends State<RideRecorderScreen>
    with SingleTickerProviderStateMixin {
  final _s = SafetyStore.instance;
  late final AnimationController _wave =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  bool _recording = false;
  int _seconds = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _s.addListener(_r);
  }

  void _r() => setState(() {});

  @override
  void dispose() {
    _ticker?.cancel();
    _wave.dispose();
    _s.removeListener(_r);
    super.dispose();
  }

  void _toggle() {
    if (_recording) {
      _stop();
    } else {
      setState(() {
        _recording = true;
        _seconds = 0;
      });
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    }
  }

  void _stop() {
    _ticker?.cancel();
    final secs = _seconds;
    setState(() {
      _recording = false;
      _seconds = 0;
    });
    if (secs >= 1) {
      _s.addRecording(RideRecording(label: 'Ride recording', seconds: secs));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording saved to your library')));
    }
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(children: [
          const StatusBar(),
          const AccountHeader(title: 'Record ride'),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Record audio of your ride for your own safety. Recordings stay private on '
              'your device and can be saved to your phone or shared with support.',
              style: TextStyle(fontSize: 13, color: _sub, height: 1.45),
            ),
          ),
          const SizedBox(height: 28),
          // recorder
          _recorderPanel(),
          const SizedBox(height: 24),
          const Divider(height: 1, color: _line),
          Expanded(child: _library()),
        ]),
      ),
    );
  }

  Widget _recorderPanel() {
    return Column(children: [
      // animated waveform
      SizedBox(
        height: 56,
        child: AnimatedBuilder(
          animation: _wave,
          builder: (_, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(21, (i) {
              final base = _recording ? 0.35 + 0.65 * ((math.sin((i * 0.9) + _wave.value * 6) + 1) / 2) : 0.18;
              return Container(
                width: 4,
                height: 8 + base * 40,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _recording ? AppColors.red : const Color(0xFFDDE1EC),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(_recording ? _timeLabel : 'Tap to start recording',
          style: TextStyle(
              fontSize: _recording ? 22 : 14,
              fontWeight: _recording ? FontWeight.w700 : FontWeight.w400,
              color: _recording ? _ink : _sub)),
      const SizedBox(height: 18),
      // record / stop button
      GestureDetector(
        onTap: _toggle,
        child: Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.red.withValues(alpha: 0.10),
            border: Border.all(color: AppColors.red, width: 2),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _recording ? 28 : 52,
              height: _recording ? 28 : 52,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(_recording ? 6 : 26),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(_recording ? 'Tap to stop' : 'Record',
          style: const TextStyle(fontSize: 12, color: _sub)),
    ]);
  }

  Widget _library() {
    if (_s.recordings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No recordings yet',
              style: TextStyle(fontSize: 14, color: _sub)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const Text('YOUR RECORDINGS',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: _sub)),
        const SizedBox(height: 8),
        for (final rec in _s.recordings) _recordingRow(rec),
      ],
    );
  }

  Widget _recordingRow(RideRecording rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: Color(0xFFE9ECF7), shape: BoxShape.circle),
          child: const Icon(Icons.multitrack_audio, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rec.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 2),
            Text(rec.durationLabel, style: const TextStyle(fontSize: 12, color: _sub)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, size: 22, color: AppColors.primary),
          tooltip: 'Save to phone',
          onPressed: () => _saveToPhone(rec),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 22, color: _sub),
          tooltip: 'Delete',
          onPressed: () => _s.removeRecording(rec),
        ),
      ]),
    );
  }

  /// Real browser download so the recording lands in the rider's device.
  void _saveToPhone(RideRecording rec) {
    final content =
        'DriveVault ride recording\n${rec.label}\nDuration: ${rec.durationLabel}\n'
        'Saved from the DriveVault safety recorder.';
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'DriveVault-ride-recording.txt')
      ..click();
    html.Url.revokeObjectUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your phone')));
  }
}
