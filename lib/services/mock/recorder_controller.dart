import 'dart:async';
import 'package:flutter/foundation.dart';
import 'safety_repository.dart';

/// App-wide recording state so a rider can record and keep using the app,
/// with guards against an accidentally-endless recording.
///
/// Guards:
/// 1. A persistent indicator (rendered app-wide) keeps it visible.
/// 2. [stopForTripEnd] ends it automatically when the ride finishes.
/// 3. [maxSeconds] is a hard backstop that auto-stops runaway recordings —
///    protecting device battery/storage and server (S3) cost.
class RecorderController extends ChangeNotifier {
  RecorderController._();
  static final RecorderController instance = RecorderController._();

  /// Hard ceiling. A safety clip should never run longer than a trip; this is
  /// the backstop for a session that is never ended manually.
  static const int maxSeconds = 2 * 60 * 60; // 2 hours

  /// Gentle heads-up before the hard cap.
  static const int warnAtSeconds = maxSeconds - 5 * 60; // 5 min before cap

  bool _recording = false;
  int _elapsed = 0;
  Timer? _timer;

  /// Set true for one read after an auto-stop, so UI can explain why it ended.
  String? autoStopReason;

  bool get isRecording => _recording;
  int get elapsed => _elapsed;
  bool get nearCap => _recording && _elapsed >= warnAtSeconds;

  String get elapsedLabel {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void start() {
    if (_recording) return;
    _recording = true;
    _elapsed = 0;
    autoStopReason = null;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      if (_elapsed >= maxSeconds) {
        _finish(save: true, reason: 'Recording reached the ${maxSeconds ~/ 3600}-hour limit and was saved automatically.');
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  /// Manual stop from the recorder or the indicator.
  void stop() => _finish(save: true, reason: null);

  /// Called when the ride ends — the recording's natural boundary.
  void stopForTripEnd() {
    if (_recording) {
      _finish(save: true, reason: 'Your trip ended, so recording stopped and was saved.');
    }
  }

  void _finish({required bool save, required String? reason}) {
    _timer?.cancel();
    final secs = _elapsed;
    _recording = false;
    _elapsed = 0;
    autoStopReason = reason;
    if (save && secs >= 1) {
      SafetyStore.instance.addRecording(RideRecording(label: 'Ride recording', seconds: secs));
    }
    notifyListeners();
  }

  String? consumeAutoStopReason() {
    final r = autoStopReason;
    autoStopReason = null;
    return r;
  }
}
