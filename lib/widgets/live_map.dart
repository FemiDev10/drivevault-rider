import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A map with cars that drift along looping paths — a lightweight "live map".
/// Optionally draws a pickup→destination route with pins, or a single
/// glowing centre pin (for the confirm-pickup spot flow).
class LiveMap extends StatefulWidget {
  const LiveMap({
    super.key,
    this.showRoute = false,
    this.showCentrePin = false,
    this.centrePinLabel,
    this.filledLabel = false,
    this.tripProgress,
  });

  /// Draw the pickup→destination route line + pins.
  final bool showRoute;

  /// 0..1 progress of the ride along the route. When set, the travelled part
  /// fades, the remaining route stays bold, and the car moves toward drop-off.
  final double? tripProgress;

  /// Cubic-bezier route sampled at [t] (0..1); returns (position, heading).
  static (Offset, double) sampleRoute(Size size, double t) {
    final p0 = Offset(size.width * 0.30, size.height * 0.20);
    final p1 = Offset(size.width * 0.20, size.height * 0.42);
    final p2 = Offset(size.width * 0.50, size.height * 0.50);
    final p3 = Offset(size.width * 0.66, size.height * 0.74);
    Offset bez(double u) {
      final v = 1 - u;
      return p0 * (v * v * v) + p1 * (3 * v * v * u) + p2 * (3 * v * u * u) + p3 * (u * u * u);
    }
    final pos = bez(t.clamp(0.0, 1.0));
    final ahead = bez((t + 0.02).clamp(0.0, 1.0));
    final d = ahead - pos;
    return (pos, math.atan2(d.dy, d.dx) + math.pi / 2);
  }

  /// Draw a glowing pin fixed at the map centre (confirm pickup spot).
  final bool showCentrePin;

  /// Label shown above the centre pin, e.g. "Pick up on Shehu Billamou Street".
  final String? centrePinLabel;

  /// When true the label is a filled navy chip; otherwise light text on white.
  final bool filledLabel;

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // Car paths in fractional (0..1) map coordinates. Each car loops its path.
  static const _paths = <List<Offset>>[
    [Offset(0.15, 0.30), Offset(0.40, 0.34), Offset(0.62, 0.30), Offset(0.85, 0.36)],
    [Offset(0.80, 0.62), Offset(0.55, 0.55), Offset(0.30, 0.60), Offset(0.10, 0.54)],
    [Offset(0.50, 0.12), Offset(0.54, 0.32), Offset(0.48, 0.52), Offset(0.52, 0.72)],
  ];
  static const _phase = [0.0, 0.45, 0.78];
  static const _speed = [1.0, 0.7, 0.85];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/home_map.png', fit: BoxFit.cover, alignment: Alignment.topCenter),
              if (widget.showRoute)
                CustomPaint(size: size, painter: _RoutePainter(progress: widget.tripProgress)),
              // Ambient traffic (hidden during an active trip so the ride car stands out)
              if (widget.tripProgress == null)
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        for (int i = 0; i < _paths.length; i++)
                          _carAt(_paths[i], (_c.value * _speed[i] + _phase[i]) % 1.0, size),
                      ],
                    );
                  },
                ),
              // The ride car moving along the route toward drop-off
              if (widget.tripProgress != null) _rideCar(size, widget.tripProgress!),
              if (widget.showCentrePin) _centrePin(),
            ],
          ),
        );
      },
    );
  }

  Widget _carAt(List<Offset> path, double t, Size size) {
    final (pos, angle) = _samplePath(path, t);
    return Positioned(
      left: pos.dx * size.width - 13,
      top: pos.dy * size.height - 13,
      child: Transform.rotate(
        angle: angle,
        child: const _CarMarker(),
      ),
    );
  }

  Widget _rideCar(Size size, double progress) {
    final (pos, angle) = LiveMap.sampleRoute(size, progress);
    return Positioned(
      left: pos.dx - 13,
      top: pos.dy - 13,
      child: Transform.rotate(angle: angle, child: const _CarMarker()),
    );
  }

  /// Returns interpolated position and heading angle along [path] at progress [t].
  (Offset, double) _samplePath(List<Offset> path, double t) {
    // Build segment lengths.
    double total = 0;
    final lens = <double>[];
    for (int i = 0; i < path.length - 1; i++) {
      final l = (path[i + 1] - path[i]).distance;
      lens.add(l);
      total += l;
    }
    double target = t * total;
    for (int i = 0; i < lens.length; i++) {
      if (target <= lens[i] || i == lens.length - 1) {
        final f = lens[i] == 0 ? 0.0 : (target / lens[i]).clamp(0.0, 1.0);
        final p = Offset.lerp(path[i], path[i + 1], f)!;
        final d = path[i + 1] - path[i];
        return (p, math.atan2(d.dy, d.dx) + math.pi / 2);
      }
      target -= lens[i];
    }
    return (path.first, 0);
  }

  Widget _centrePin() {
    return Align(
      alignment: const Alignment(0, -0.12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.centrePinLabel != null) ...[
            _PinLabel(text: widget.centrePinLabel!, filled: widget.filledLabel),
            const SizedBox(height: 6),
          ],
          // glow + pin
          SizedBox(
            width: 120,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(Icons.location_on, size: 40, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinLabel extends StatelessWidget {
  const _PinLabel({required this.text, required this.filled});
  final String text;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: filled ? AppColors.white : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

/// Small top-down car marker.
class _CarMarker extends StatelessWidget {
  const _CarMarker();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 26, height: 26, child: CustomPaint(painter: _CarPainter()));
}

class _CarPainter extends CustomPainter {
  const _CarPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 22),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      body.shift(const Offset(0, 1)),
      Paint()..color = const Color(0x33000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawRRect(body, Paint()..color = AppColors.white);
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = AppColors.primary);
    // windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 4), width: 8, height: 5), const Radius.circular(1.5)),
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) => false;
}

/// Stylised pickup→destination route overlay.
class _RoutePainter extends CustomPainter {
  _RoutePainter({this.progress});
  final double? progress;

  Path _sub(Size size, double from, double to) {
    final path = Path();
    const steps = 40;
    for (int i = 0; i <= steps; i++) {
      final t = from + (to - from) * (i / steps);
      final (p, _) = LiveMap.sampleRoute(size, t);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (start, _) = LiveMap.sampleRoute(size, 0);
    final (end, _) = LiveMap.sampleRoute(size, 1);
    final p = progress;

    final bold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;

    if (p == null) {
      canvas.drawPath(_sub(size, 0, 1), bold);
    } else {
      // travelled part faint, remaining bold
      canvas.drawPath(_sub(size, 0, p.clamp(0.0, 1.0)),
          Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round..color = const Color(0x33A9B0C9));
      canvas.drawPath(_sub(size, p.clamp(0.0, 1.0), 1), bold);
    }

    // pickup dot
    canvas.drawCircle(start, 7, Paint()..color = AppColors.white);
    canvas.drawCircle(start, 7, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = AppColors.primary);
    // destination pin
    final pin = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(end.dx, end.dy - 6), 8, pin);
    final tri = Path()
      ..moveTo(end.dx - 5, end.dy - 3)
      ..lineTo(end.dx + 5, end.dy - 3)
      ..lineTo(end.dx, end.dy + 6)
      ..close();
    canvas.drawPath(tri, pin);
    canvas.drawCircle(Offset(end.dx, end.dy - 6), 3, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.progress != progress;
}
